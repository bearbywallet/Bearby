/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { MobileStorage, buildObject } from 'app/lib';
import { ViewBlockControler } from 'app/lib/controller/viewblock';
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
import { TX_DIRECTION, ZILLIQA_KEYS } from 'app/config';
import { Transaction } from './builder';
import { toBech32Address, tohexString, deppUnlink } from 'app/utils';
import { trim } from 'app/filters';
import i18n from 'app/lib/i18n';
import { TransactionType } from 'types';

export class TransactionsContoller {
  public store = transactionStore;

  private _viewblock: ViewBlockControler;
  private _zilliqa: ZilliqaControl;
  private _storage: MobileStorage;
  private _account: AccountControler;
  private _netwrok: NetworkControll;
  private _notification: NotificationManager;

  constructor(
    viewblock: ViewBlockControler,
    zilliqa: ZilliqaControl,
    storage: MobileStorage,
    account: AccountControler,
    netwrok: NetworkControll,
    notification: NotificationManager
  ) {
    this._viewblock = viewblock;
    this._zilliqa = zilliqa;
    this._storage = storage;
    this._account = account;
    this._netwrok = netwrok;
    this._notification = notification;
  }

  private get _field() {
    const account = this._account.getCurrentAccount();
    const netwrok = this._netwrok.selected;

    return {
      account,
      field: `${account.base16}/${netwrok}`
    };
  }

  public async sync() {
    if (this._netwrok.selected === ZILLIQA_KEYS[2]) {
      return null;
    }

    const { field } = this._field;
    const txns = await this._storage.get(field);

    if (!txns || typeof txns !== 'string') {
      return this._update();
    }

    try {
      const parsed = JSON.parse(txns);

      if (Array.isArray(parsed) && parsed.length === 0) {
        return this._update();
      }

      transactionStoreUpdate(parsed);
    } catch {
      return this._update();
    }
  }

  public async updateTxns() {
    if (this._netwrok.selected === ZILLIQA_KEYS[2]) {
      return null;
    }

    await this._update();
  }

  public async reset() {
    const { field } = this._field;

    await this._storage.rm(field);

    this._notification.setBadgeNumber(0);

    transactionStoreReset();
  }

  public async checkProcessedTx() {
    const panding = this.store.get().filter(
      (t) => Number(t.blockHeight) === 0
    );
    const state = deppUnlink(this.store.get()) as TransactionType[];
    const { field } = this._field;
    const countBadge = await this._notification.getBadgeNumber();

    for (const iterator of panding) {
      try {
        const data = await this._zilliqa.getTransaction(iterator.hash);
        const foundIndex = state.findIndex((tx) => tx.hash === data.ID);
        const title = data.receipt.errors ? i18n.t('tx_fail') : i18n.t('sent');

        this._notification.localNotification({
          title,
          message: i18n.t('transaction', {
            hash: `0x${trim(data.ID)}`
          }),
          userInfo: {
            hash: data.ID
          }
        });

        state[foundIndex] = {
          ...state[foundIndex],
          blockHeight: Number(data.receipt.epoch_num),
          receiptSuccess: data.receipt.success,
          events: data.receipt.event_logs
        };
        this._notification.setBadgeNumber(countBadge - 1);
      } catch {
        continue;
      }
    }

    transactionStoreUpdate(state);

    await this._storage.set(
      buildObject(field, state)
    );
  }

  public async add(tx: Transaction) {
    if (!tx.hash) {
      throw new Error('incorect transaction hash.');
    }
    const { field } = this._field;
    const to = toBech32Address(tx.toAddr);

    tx.direction = to === tx.from ? TX_DIRECTION.self : TX_DIRECTION.out;
    tx.timestamp = new Date().getTime();

    transactionStoreAdd({
      to,
      hash: tx.hash,
      blockHeight: 0,
      from: tx.from,
      value: tx.amount,
      fee: tx.feeValue,
      receiptSuccess: undefined,
      timestamp: tx.timestamp,
      direction: tx.direction,
      nonce: tx.nonce,
      data: tx.data,
      code: tx.code
    });

    await this._storage.set(
      buildObject(field, this.store.get())
    );
    const countBadge = await this._notification.getBadgeNumber();

    this._notification.setBadgeNumber(countBadge + 1);
  }

  private async _update() {
    const { account, field } = this._field;
    const countBadge = await this._notification.getBadgeNumber();
    const gotTxns = await this
      ._viewblock
      .getTransactions(account.bech32);
    const panding = this
      .store
      .get()
      .filter((t) => t.blockHeight === 0)
      .filter((t) => {
        const test = gotTxns.some((tx) => tohexString(tx.hash) === tohexString(t.hash));

        if (test) {
          this._notification.setBadgeNumber(countBadge - 1);
        }

        return !test;
      });
    transactionStoreUpdate([...panding, ...gotTxns]);

    await this._storage.set(
      buildObject(field, gotTxns)
    );
  }
}
