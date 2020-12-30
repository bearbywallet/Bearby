/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { TransactionsContoller, ZilliqaControl } from 'app/lib/controller';
import { BLOCK_INTERVAL } from 'app/config';

export class WorkerController {
  private _transactions: TransactionsContoller;
  private _zilliqa: ZilliqaControl;

  constructor(
    transactions: TransactionsContoller,
    zilliqa: ZilliqaControl
  ) {
    this._zilliqa = zilliqa;
    this._transactions = transactions;
  }

  public async step() {
    await this._transactions.checkProcessedTx();
  }

  public async start() {
    setInterval(() => this.step(), BLOCK_INTERVAL);
  }
}
