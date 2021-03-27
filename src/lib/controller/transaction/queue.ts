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
import { Token, Account } from 'types';
import { StatusCodes } from './tx-statuses';
import { tokensStore } from 'app/lib/controller/tokens';
import { NONCE_DIFFICULTY, STORAGE_FIELDS } from 'app/config';

export class TransactionsQueue {
  public store = transactionStore;

  private _zilliqa: ZilliqaControl;
  private _storage: MobileStorage;
  private _netwrok: NetworkControll;
  private _account: AccountControler;
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

  private get _field() {
    return STORAGE_FIELDS.TRANSACTIONS;
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
      from: tx.from,
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
    const data = await this._storage.get(this._field);

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
    await this._storage.rm(this._field);

    this._notification.setBadgeNumber(0);

    transactionStoreReset();
  }

  public async resetNonce(account: Account) {
    await this.sync();

    const list = this.store.get();
    const result = await this._zilliqa.getBalance(account.base16);

    if (list.length !== 0) {
      list[0].nonce = result.nonce;
    }

    return result.nonce;
  }

  public async calcNextNonce(account: Account) {
    await this.sync();

    const list = this.store.get().filter((t) => !t.confirmed);
    let { nonce } = await this._zilliqa.getBalance(account.base16);

    if (list.length > NONCE_DIFFICULTY) {
      throw new Error('nonce too hight');
    }

    if (list && list[0]) {
      const [tx] = list;

      nonce = Number(nonce) < Number(tx.nonce) ? Number(tx.nonce) : Number(nonce);
    }

    return nonce + 1;
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
        element.nonce = 0;

        continue;
      }

      if (element.confirmed) {
        continue;
      }

      const title = i18n.t('transaction');
      const result = await this._zilliqa.getTransactionStatus(element.hash);

      switch (result.status) {
        case StatusCodes.Confirmed:
          element.status = result.status;
          element.confirmed = true;
          element.nonce = result.nonce;
          element.info = `node_status_${result.status}`;
          this._makeNotify(title, element.hash, element.info);
          continue;
        case StatusCodes.Pending:
          element.status = result.status;
          element.confirmed = result.success;
          element.info = `node_status_${result.status}`;
          continue;
        case StatusCodes.PendingAwait:
          element.status = result.status;
          element.confirmed = true;
          element.info = `node_status_${result.status}`;
          this._makeNotify(title, element.hash, element.info);
          continue;
        default:
          element.status = result.status;
          element.confirmed = true;
          element.nonce = 0;
          element.info = `node_status_${result.status}`;
          rejectAll = {
            info: element.info,
            status: result.status
          };
          this._makeNotify(title, element.hash, element.info);
          continue;
      }
    }

    transactionStoreUpdate(list);

    await this._update();
  }

  private _makeNotify(title: string, hash: string, message: string) {
    this._notification.localNotification({
      title,
      message: i18n.t(message),
      userInfo: {
        hash
      }
    });
  }

  private async _update() {
    const state = this.store.get();

    await this._storage.set(
      buildObject(this._field, state)
    );
  }
}
