/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { MobileStorage, buildObject } from 'app/lib';
import { ZilliqaControl } from 'app/lib/controller/zilliqa';
import { AccountControler } from 'app/lib/controller/account';
import { NetworkControll } from 'app/lib/controller/network';
import { NotificationManager } from 'app/lib/controller/notification';
import {
  transactionStore,
  transactionStoreReset,
  transactionStoreUpdate,
  transactionStoreAdd
} from './store';
import { Transaction } from './builder';
import i18n from 'app/lib/i18n';
import { Token } from 'types';
import { StatusCodes } from './tx-statuses';
import { tokensStore } from 'app/lib/controller/tokens';

export class TransactionsQueue {
  public store = transactionStore;

  private _zilliqa: ZilliqaControl;
  private _storage: MobileStorage;
  private _account: AccountControler;
  private _netwrok: NetworkControll;
  private _notification: NotificationManager;

  constructor(
    zilliqa: ZilliqaControl,
    storage: MobileStorage,
    account: AccountControler,
    netwrok: NetworkControll,
    notification: NotificationManager
  ) {
    this._zilliqa = zilliqa;
    this._storage = storage;
    this._account = account;
    this._netwrok = netwrok;
    this._notification = notification;
  }

  /**
   * Create a key for storage, via `account` and `netwrok`.
   */
  private get _field() {
    const account = this._account.getCurrentAccount();
    const netwrok = this._netwrok.selected;

    return {
      account,
      field: `${account.base16}/${netwrok}`
    };
  }

  public async add(tx: Transaction, token?: Token) {
    if (!tx.hash) {
      throw new Error('Tx without hash');
    }

    if (!token) {
      const [zilliqa] = tokensStore.get();

      token = zilliqa;
    }

    transactionStoreAdd({
      teg: tx.tag,
      token: {
        decimals: token.decimals,
        symbol: token.symbol
      },
      status: StatusCodes.Pending,
      amount: tx.tokenAmount,
      type: tx.transactionType,
      fee: tx.feeValue,
      nonce: tx.nonce,
      toAddr: tx.toAddr,
      hash: tx.hash,
      timestamp: new Date().getTime()
    });

    await this._update();
  }

  public async sync() {
    const { field } = this._field;
    const data = await this._storage.get(field);

    try {
      if (Boolean(data) && typeof data === 'string') {
        const list = JSON.parse(data);

        if (Array.isArray(list)) {
          transactionStoreUpdate(list);
        } else {
          transactionStoreReset();
        }
      }
    } catch {
      await this.reset();
    }
  }

  public async reset() {
    const { field } = this._field;

    await this._storage.rm(field);

    this._notification.setBadgeNumber(0);

    transactionStoreReset();
  }

  public async checkProcessedTx() {
    const list = this.store.get();
    let rejectAll = null;

    for (let index = list.length - 1; index >= 0; index--) {
      const element = list[index];

      if (rejectAll) {
        element.info = rejectAll.info;
        element.status = rejectAll.status;
        element.confirmed = true;

        continue;
      }

      if (element.confirmed) {
        continue;
      }

      try {
        const title = i18n.t('transaction');
        const result = await this._zilliqa.getTransactionStatus(element.hash);

        switch (result.status) {
          case StatusCodes.Confirmed:
            element.status = result.status;
            element.confirmed = result.success;
            element.nonce = result.nonce;
            element.info = i18n.t(`node_status_${result.status}`);
            this._makeNotify(title, element.hash, element.info);
            break;
          case StatusCodes.Pending:
            element.status = result.status;
            element.confirmed = result.success;
            element.nonce = result.nonce;
            element.info = i18n.t(`node_status_${result.status}`);
            break;
          case StatusCodes.PendingAwait:
            element.status = result.status;
            element.confirmed = result.success;
            element.nonce = result.nonce;
            element.info = i18n.t(`node_status_${result.status}`);
            break;
          default:
            element.status = result.status;
            element.confirmed = true;
            element.nonce = result.nonce;
            element.info = i18n.t(`node_status_${result.status}`);
            rejectAll = {
              info: element.info,
              status: result.status
            };
            this._makeNotify(title, element.hash, element.info);
            break;
        }
      } catch (err) {
        continue;
      }
    }

    transactionStoreUpdate(list);

    await this._update();
  }

  private _makeNotify(title: string, hash: string, message: string) {
    this._notification.localNotification({
      title,
      message,
      userInfo: {
        hash
      }
    });
  }

  private async _update() {
    const { field } = this._field;
    const state = this.store.get();

    await this._storage.set(
      buildObject(field, state)
    );
  }
}
