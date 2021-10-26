/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { MobileStorage, buildObject, NetworkControll, AccountControler } from 'app/lib';
import { ZilliqaControl } from 'app/lib/controller/zilliqa';
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
import { Methods } from '../zilliqa/methods';

export class TransactionsQueue {
  public store = transactionStore;

  private _zilliqa: ZilliqaControl;
  private _storage: MobileStorage;
  private _notification: NotificationManager;
  private _netwrok: NetworkControll;
  private _accounts: AccountControler;

  constructor(
    zilliqa: ZilliqaControl,
    storage: MobileStorage,
    notification: NotificationManager,
    netwrok: NetworkControll,
    accounts: AccountControler
  ) {
    this._zilliqa = zilliqa;
    this._storage = storage;
    this._notification = notification;
    this._accounts = accounts;
    this._netwrok = netwrok;
  }

  private get _field() {
    const field = STORAGE_FIELDS.TRANSACTIONS;
    const bech32 = this._accounts.getCurrentAccount().base16;
    const net = this._netwrok.selected;
    return `${field}/${bech32}/${net}`;
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
      } else {
        transactionStoreReset();
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
    const now = new Date().getTime();
    const dilaySeconds = 15000;
    const title = i18n.t('transaction');
    const identities = list.filter((t) => {
      return !t.confirmed && (now - t.timestamp) > dilaySeconds;
    });
    if (identities.length === 0) {
      return null;
    }
    const requests = identities.map(({ hash }) => {
      return this._zilliqa.provider.buildBody(Methods.GetTransactionStatus, [hash]);
    });
    let replies = await this._zilliqa.sendJson(...requests);
    if (!Array.isArray(replies)) {
      replies = [replies];
    }

    for (let index = 0; index < replies.length; index++) {
      const res = replies[index];
      const indicator = identities[index];
      const listIndex = list.findIndex((t) => t.hash === indicator.hash);
      const element = list[listIndex];

      if (res.error) {
        element.status = 0;
        element.confirmed = true;
        element.success = false;
        element.nonce = 0;
        element.info = String(res.error.message);
        this._makeNotify(title, element.hash, element.info);
        continue;
      }

      switch (res.result.status) {
        case StatusCodes.Confirmed:
          element.confirmed = true;
          element.success = res.result.success;
          element.nonce = res.result.nonce;
          element.status = res.result.status;
          element.info = `node_status_${res.result.status}`;
          this._makeNotify(title, element.hash, i18n.t(element.info));
          continue;
        case StatusCodes.Pending:
          continue;
        case StatusCodes.PendingAwait:
          element.confirmed = true;
          element.success = res.result.success;
          element.nonce = res.result.nonce;
          element.status = res.result.status;
          element.info = `node_status_${res.result.status}`;
          this._makeNotify(title, element.hash, i18n.t(element.info));
          continue;
        default:
          element.confirmed = true;
          element.success = res.result.success;
          element.status = res.result.status;
          element.nonce = 0;
          element.info = `node_status_${res.result.status}`;
          this._makeNotify(title, element.hash, i18n.t(element.info));
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
    const state = this.store.get();

    await this._storage.set(
      buildObject(this._field, state)
    );
  }
}
