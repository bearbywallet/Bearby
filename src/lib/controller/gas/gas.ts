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
import { ZilliqaControl } from 'app/lib/controller/zilliqa';
import { STORAGE_FIELDS, DEFAULT_GAS } from 'app/config';
import { GasState } from 'types';

export class GasControler {
  public readonly store = gasStore;
  private _storage: MobileStorage;
  private _zilliqa: ZilliqaControl;

  constructor(storage: MobileStorage, zilliqa: ZilliqaControl) {
    this._storage = storage;
    this._zilliqa = zilliqa;
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

      if (Number(state.gasLimit) < Number(DEFAULT_GAS.gasLimit)) {
        state.gasLimit = DEFAULT_GAS.gasLimit;
      }

      if (Number(state.gasPrice) < Number(DEFAULT_GAS.gasPrice)) {
        state.gasLimit = DEFAULT_GAS.gasLimit;
      }

      gasStoreUpdate(state);
    } catch (err) {
      return null;
    }
  }

  public async reset() {
    gasStoreReset();

    const minGas = await this._zilliqa.getMinimumGasPrice();
    const state = this.store.get();

    state.gasPrice = String(Number(minGas) / 10 ** 6);

    return this._storage.set(
      buildObject(STORAGE_FIELDS.GAS, state)
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
