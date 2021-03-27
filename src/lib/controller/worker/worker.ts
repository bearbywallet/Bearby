/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import BackgroundTimer from 'react-native-background-timer';
import { TransactionsQueue } from 'app/lib/controller/transaction';
import { AccountControler } from 'app/lib/controller/account';
import { BLOCK_INTERVAL } from 'app/config';

export class WorkerController {
  private _transactions: TransactionsQueue;
  private _account: AccountControler;

  constructor(
    transactions: TransactionsQueue,
    account: AccountControler
  ) {
    this._account = account;
    this._transactions = transactions;
  }

  public async step() {
    try {
      await this._transactions.checkProcessedTx();
    } catch {
      //
    }

    try {
      await this._account.balanceUpdate();
    } catch {
      //
    }
  }

  public async start() {
    await this.step();
    BackgroundTimer.runBackgroundTimer(() => {
      this.step();
    }, BLOCK_INTERVAL);
  }
}
