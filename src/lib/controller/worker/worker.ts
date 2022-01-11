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
import { Device } from 'app/utils/device';

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
    try {
      await this.block.sync();
    } catch (err) {
      console.error('block.sync', err);
      //
    }

    try {
      await this._transactions.checkProcessedTx();
    } catch (err) {
      console.error('checkProcessedTx', err);
    }

    try {
      await this._account.balanceUpdate();
    } catch (err) {
      console.error('balanceUpdate', err);
    }

    this._theme.updateColors();
  }

  public async start() {
    let k = 0;
    try {
      await this.block.sync();
    } catch {
      //
    }

    const blocknumber = this.store.get();

    if (Device.isAndroid()) {
      await this._apps.getBanners(blocknumber);
    }

    this.block.subscriber(async(block) => {
      await this.step();

      if (Device.isAndroid()) {
        k++;

        if (k > 10) {
          await this._apps.getBanners(block);
          k = 0;
        }
      }
    });
  }
}
