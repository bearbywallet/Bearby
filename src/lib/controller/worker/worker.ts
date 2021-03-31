/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { TransactionsQueue } from 'app/lib/controller/transaction';
import { AccountControler } from 'app/lib/controller/account';
import { ZilliqaControl } from 'app/lib/controller/zilliqa';
import { MobileStorage } from 'app/lib/storage';
import { BlockControl } from './block';
import { blockStore } from './store';

export class WorkerController {
  public store = blockStore;
  public block: BlockControl;

  private _transactions: TransactionsQueue;
  private _account: AccountControler;

  constructor(
    transactions: TransactionsQueue,
    account: AccountControler,
    zilliqa: ZilliqaControl,
    storage: MobileStorage
  ) {
    this._account = account;
    this._transactions = transactions;
    this.block = new BlockControl(storage, zilliqa);
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
    this.block.subscriber((block) => {
      this.step();
    });
  }
}
