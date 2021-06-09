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
import { ThemeControler } from 'app/lib/controller/theme';
import { ZilliqaControl } from 'app/lib/controller/zilliqa';
import { AppsController } from 'app/lib/controller/apps';
import { MobileStorage } from 'app/lib/storage';
import { BlockControl } from './block';
import { blockStore } from './store';

export class WorkerController {
  public store = blockStore;
  public block: BlockControl;

  private _transactions: TransactionsQueue;
  private _account: AccountControler;
  private _theme: ThemeControler;
  private _apps: AppsController;

  constructor(
    transactions: TransactionsQueue,
    account: AccountControler,
    zilliqa: ZilliqaControl,
    storage: MobileStorage,
    apps: AppsController,
    theme: ThemeControler
  ) {
    this._account = account;
    this._apps = apps;
    this._transactions = transactions;
    this.block = new BlockControl(storage, zilliqa);
    this._theme  = theme;
  }

  public async step() {
    await this.block.sync();
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

    this._theme.updateColors();
  }

  public async start() {
    await this.block.sync();

    // const blocknumber = this.store.get();

    // await this._apps.getBanners(blocknumber);

    this.block.subscriber(async(block) => {
      await this.step();
      // await this._apps.getBanners(block);
    });
  }
}
