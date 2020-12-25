/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import {
  connectStore,
  connectStoreAdd,
  connectStoreReset,
  connectStoreUpdate,
  connectStoreRm
} from './store';
import { MobileStorage, buildObject } from "app/lib/storage";
import { Connect } from 'types';
import { STORAGE_FIELDS } from 'app/config';

export class ConnectController {

  public static uniqueCheck(connect: Connect) {
    const connections = connectStore.get();

    for (const iterator of connections) {
      if (iterator.domain.toLowerCase() === connect.domain.toLowerCase()) {
        throw new Error('Must be unique');
      }
    }
  }

  public store = connectStore;
  private _storage: MobileStorage;

  constructor(storage: MobileStorage) {
    this._storage = storage;
  }

  public async add(connect: Connect) {
    try {
      ConnectController.uniqueCheck(connect);
      connectStoreAdd(connect);
      await this._storage.set(
        buildObject(STORAGE_FIELDS.CONNECTIONS, this.store.get())
      );
    } catch {
      //
    }
  }

  public async rm(connect: Connect) {
    connectStoreRm(connect);

    await this._storage.set(
      buildObject(STORAGE_FIELDS.CONNECTIONS, this.store.get())
    );
  }

  public async reset() {
    connectStoreReset();

    await this._storage.set(
      buildObject(STORAGE_FIELDS.CONNECTIONS, this.store.get())
    );
  }

  public async sync() {
    const data = await this._storage.get(STORAGE_FIELDS.CONNECTIONS);

    if (typeof data !== 'string') {
      await this.reset();
      return null;
    }

    try {
      connectStoreUpdate(JSON.parse(data));
    } catch (err) {
      console.error('lib/connect/sync', err);
      await this.reset();
    }
  }
}
