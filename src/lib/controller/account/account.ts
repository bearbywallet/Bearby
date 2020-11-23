/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { MobileStorage, buildObject } from 'app/lib/storage';
import { STORAGE_FIELDS, AccountTypes } from 'app/config';
import {
  getAddressFromPublicKey,
  toBech32Address
} from 'app/utils';
import {
  accountStore,
  accountStoreReset,
  accountStoreUpdate,
  accountStoreSelect
} from './sate';
import { AccountState, Account, KeyPair } from 'types';

export class AccountControler {
  public store = accountStore;
  private _storage: MobileStorage;

  constructor(storage: MobileStorage) {
    this._storage = storage;
  }

  public async sync(): Promise<AccountState> {
    try {
      const accounts = await this._storage.get<string>(
        STORAGE_FIELDS.ACCOUNTS
      );

      if (typeof accounts === 'string') {
        const parsed = JSON.parse(accounts);

        accountStoreUpdate(parsed);
      }
    } catch (err) {
      //
    }

    return this.store.getState();
  }

  public fromKeyPairs(acc: KeyPair, type: AccountTypes, name = ''): Account {
    const base16 = getAddressFromPublicKey(acc.publicKey);
    const bech32 = toBech32Address(base16);

    return {
      base16,
      bech32,
      name,
      type,
      index: Number(acc.index),
      nonce: 0 // TODO: check and update nonce.
    };
  }

  public getCurrentAccount() {
    const { identities, selectedAddress } = this.store.getState();

    return identities[selectedAddress];
  }

  public reset() {
    const accountsState = {
      identities: [],
      selectedAddress: -1
    };

    accountStoreReset();

    return this.update(accountsState);
  }

  public update(accountState: AccountState): Promise<void> {
    accountStoreUpdate(accountState);

    return this._storage.set(
      buildObject(STORAGE_FIELDS.ACCOUNTS, accountState)
    );
  }

  public async add(account: Account) {
    const accounts = await this._checkAccount(account);

    accounts
      .identities
      .push(account);
    accounts
      .selectedAddress = accounts.identities.length - 1;

    await this.update(accounts);

    return accounts;
  }

  public async selectAccount(index: number) {
    const { identities } = this.store.getState();

    if (identities.length < index) {
      return null;
    }

    accountStoreSelect(index);

    await this.update(this.store.getState());
  }

  private async _checkAccount(account: Account) {
    const accounts = await this.sync();
    const isUnique = accounts.identities.some(
      (acc) => (acc.base16 === account.base16)
    );
    const isIndex = accounts.identities.some(
      (acc) => (acc.index === account.index) && (acc.type === account.type)
    );

    if (isUnique) {
      throw new Error('Account must be unique');
    } else if (isIndex) {
      throw new Error('Incorect index and account type');
    }

    return accounts;
  }
}
