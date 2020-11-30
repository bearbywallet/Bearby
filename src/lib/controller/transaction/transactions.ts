/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { MobileStorage, buildObject } from 'app/lib';
import { ViewBlockControler } from 'app/lib/controller/viewblock';
import { ZilliqaControl } from 'app/lib/controller/zilliqa';
import { AccountControler } from 'app/lib/controller/account';
import { NetworkControll } from 'app/lib/controller/network';
import { Transaction } from 'types';
import {
  transactionStore,
  transactionStoreReset,
  transactionStoreUpdate
} from './store';
import { ZILLIQA_KEYS } from 'app/config';

export class TransactionsContoller {
  public store = transactionStore;

  private _viewblock: ViewBlockControler;
  private _zilliqa: ZilliqaControl;
  private _storage: MobileStorage;
  private _account: AccountControler;
  private _netwrok: NetworkControll;

  constructor(
    viewblock: ViewBlockControler,
    zilliqa: ZilliqaControl,
    storage: MobileStorage,
    account: AccountControler,
    netwrok: NetworkControll
  ) {
    this._viewblock = viewblock;
    this._zilliqa = zilliqa;
    this._storage = storage;
    this._account = account;
    this._netwrok = netwrok;
  }

  private get _field() {
    const account = this._account.getCurrentAccount();
    const netwrok = this._netwrok.selected;

    return {
      account,
      field: `${account.base16}/${netwrok}`
    };
  }

  public async sync() {
    if (this._netwrok.selected === ZILLIQA_KEYS[2]) {
      return null;
    }

    const { field } = this._field;
    const txns = await this._storage.get<Transaction[]>(field);

    if (!txns || typeof txns !== 'string') {
      return this._update();
    }

    const parsed = JSON.parse(txns);

    if (Array.isArray(parsed) && parsed.length === 0) {
      return this._update();
    }

    transactionStoreUpdate(parsed);
  }

  public async reset() {
    const { field } = this._field;

    await this._storage.rm(field);

    transactionStoreReset();
  }

  private async _update() {
    const { account, field } = this._field;
    const gotTxns = await this
      ._viewblock
      .getTransactions(account.bech32);

    transactionStoreUpdate(gotTxns);

    await this._storage.set(
      buildObject(field, gotTxns)
    );
  }
}
