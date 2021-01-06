/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import BackgroundTimer from 'react-native-background-timer';
import { TransactionsContoller, AccountControler } from 'app/lib/controller';
import { BLOCK_INTERVAL } from 'app/config';

export class WorkerController {
  private _transactions: TransactionsContoller;
  private _account: AccountControler;

  constructor(
    transactions: TransactionsContoller,
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
      const needUpdate = await this._account.zilBalaceUpdate();

      if (needUpdate) {
        this._transactions.updateTxns();
      }
    } catch {
      //
    }
  }

  public async start() {
    BackgroundTimer.runBackgroundTimer(() => {
      this.step();
    }, BLOCK_INTERVAL);
  }
}
