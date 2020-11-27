/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { MobileStorage } from 'app/lib';
import { ViewBlockControler } from 'app/lib/controller/viewblock';
import { ZilliqaControl } from 'app/lib/controller/zilliqa';

export class TransactionsContoller {
  private _viewblock: ViewBlockControler;
  private _zilliqa: ZilliqaControl;
  private _storage: MobileStorage

  constructor(
    viewblock: ViewBlockControler,
    zilliqa: ZilliqaControl,
    storage: MobileStorage
  ) {
    this._viewblock = viewblock;
    this._zilliqa = zilliqa;
    this._storage = storage;
  }

  public sync() {}

  public reset() {}
}
