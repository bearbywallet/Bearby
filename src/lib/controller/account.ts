/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { MobileStorage, buildObject } from '../storage';
import { STORAGE_FIELDS } from '../../config';
import { AccountState, Account } from 'types';

export class AccountControler {
  private _storage = new MobileStorage();

  public async get(): Promise<AccountState> {
    const accounts = await this._storage.get<AccountState>(
      STORAGE_FIELDS.ACCOUNTS
    );

    if (typeof accounts === 'object') {
      return accounts as AccountState;
    }

    return {
      identities: [],
      selectedAddress: -1
    };
  }

  public update(accountState: AccountState): Promise<void> {
    return this._storage.set(
      buildObject(STORAGE_FIELDS.ACCOUNTS, accountState)
    );
  }

  public async add(account: Account) {
    const accounts = await this._checkAccount(account);

    accounts
      .identities
      .push(account);
    accounts.selectedAddress = accounts.identities.length - 1;

    await this.update(accounts);

    return accounts;
  }

  private async _checkAccount(account: Account) {
    const accounts = await this.get();
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
