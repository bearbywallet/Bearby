/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
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
      const needUpdate = await this._account.zilBalaceUpdate();

      if (needUpdate) {
        await this._transactions.checkProcessedTx();
      }
    } catch {
      //
    }

    try {
      await this._transactions.checkProcessedTx();
    } catch {
      //
    }
  }

  public async start() {
    setInterval(() => this.step(), BLOCK_INTERVAL);
  }
}
