/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { MobileStorage, buildObject } from 'app/lib/storage';
import { STORAGE_FIELDS, AccountTypes, ZILLIQA_KEYS } from 'app/config';
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
import { TokenControll } from 'app/lib/controller/tokens';
import { ZilliqaControl } from 'app/lib/controller/zilliqa';

export class AccountControler {
  public store = accountStore;
  private _storage: MobileStorage;
  private _token: TokenControll;
  private _zilliqa: ZilliqaControl;

  constructor(
    storage: MobileStorage,
    token: TokenControll,
    zilliqa: ZilliqaControl
  ) {
    this._storage = storage;
    this._token = token;
    this._zilliqa = zilliqa;
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

    return this.store.get();
  }



  public async fromKeyPairs(acc: KeyPair, type: AccountTypes, name = ''): Promise<Account> {
    const base16 = getAddressFromPublicKey(acc.publicKey);
    const bech32 = toBech32Address(base16);
    const balance = await this._tokenBalance(base16);

    return {
      base16,
      bech32,
      name,
      type,
      balance,
      index: Number(acc.index),
      nonce: 0 // TODO: check and update nonce.
    };
  }

  public getCurrentAccount() {
    const { identities, selectedAddress } = this.store.get();

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
    const { identities } = this.store.get();

    if (identities.length < index) {
      return null;
    }

    accountStoreSelect(index);

    await this.update(this.store.get());
  }

  public async balanceUpdate() {
    const accounts = this.store.get();
    const account = accounts.identities[accounts.selectedAddress];

    account.balance = await this._tokenBalance(account.base16);

    await this.update(accounts);
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

  private async _tokenBalance(base16: string) {
    const promiseTokens = this._token.store.get().identities.map(async(t) => {
      try {
        const bl = await this._zilliqa.handleBalance(base16, t);

        return [t.symbol, bl];
      } catch (err) {
        return [t.symbol, '0'];
      }
    });
    const tokens = await Promise.all(promiseTokens);
    const entries = ZILLIQA_KEYS.map((net) => [net, Object.fromEntries(tokens)]);

    return Object.fromEntries(entries);
  }
}
