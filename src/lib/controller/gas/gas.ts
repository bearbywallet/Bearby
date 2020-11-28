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
  gasStoreReset
} from './state';
import { STORAGE_FIELDS, DEFAULT_GAS } from 'app/config';
import { GasState } from 'types';

export class GasControler {
  public readonly store = gasStore;
  private _storage: MobileStorage;

  constructor(storage: MobileStorage) {
    this._storage = storage;
  }

  public async sync() {
    const gasConfig = await this._storage.get(
      STORAGE_FIELDS.GAS
    );

    if (!gasConfig) {
      return null;
    }

    try {
      const state = JSON.parse(String(gasConfig));

      gasStoreUpdate(state);
    } catch (err) {
      return null;
    }
  }

  public reset() {
    gasStoreReset();

    return this._storage.set(
      buildObject(STORAGE_FIELDS.GAS, this.store.get())
    );
  }

  public async changeGas(gas: GasState) {
    if (isNaN(Number(gas.gasLimit))) {
      return null;
    } else if (isNaN(Number(gas.gasPrice))) {
      return null;
    } else if (Number(gas.gasPrice) < Number(DEFAULT_GAS.gasPrice)) {
      return null;
    } else if (Number(gas.gasLimit) < Number(DEFAULT_GAS.gasLimit)) {
      return null;
    }

    gasStoreUpdate(gas);

    await this._storage.set(
      buildObject(STORAGE_FIELDS.GAS, this.store.get())
    );
  }
}
