/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { MobileStorage, buildObject } from 'app/lib';
import {
  gasStore,
  gasStoreUpdate,
  GasStoreReset
} from './state';
import { STORAGE_FIELDS } from 'app/config';
import { GasState } from 'types';

export class GasControler {
  public readonly store = gasStore;
  private _storage: MobileStorage;

  constructor(storage: MobileStorage) {
    this._storage = storage;
  }

  public async sync() {
    const gasConfig = await this._storage.get<GasState>(
      STORAGE_FIELDS.GAS
    );

    if (gasConfig || typeof gasConfig !== 'object') {
      return null;
    } else if (Object.keys(gasConfig || {}).length !== 3) {
      return null;
    }

    gasStoreUpdate(gasConfig as GasState);
  }

  public reset() {
    GasStoreReset();

    return this._storage.set(
      buildObject(STORAGE_FIELDS.GAS, this.store.getState())
    );
  }
}
