/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import {
  settingsStore,
  settingsStoreReset,
  settingsStoreSetAddressFormat,
  settingsStoreSetRate
} from './store';
import { MobileStorage, buildObject } from 'app/lib/storage';
import {
  STORAGE_FIELDS,
  ADDRESS_FORMATS,
  API_COINGECKO,
  DEFAULT_CURRENCIES
} from 'app/config';

export class SettingsControler {
  public readonly store = settingsStore;
  public readonly formats = ADDRESS_FORMATS;
  private _storage: MobileStorage;

  constructor(storage: MobileStorage) {
    this._storage = storage;
  }

  public async rateUpdate() {
    const currencies = DEFAULT_CURRENCIES.join();
    const url = `${API_COINGECKO}?ids=zilliqa&vs_currencies=${currencies}`;

    const response = await fetch(url);
    const data = await response.json();
    const rate = data.zilliqa;

    settingsStoreSetRate(rate);

    return this._storage.set(
      buildObject(STORAGE_FIELDS.RATE, String(rate))
    );
  }

  public setFormat(format: string) {
    settingsStoreSetAddressFormat(format);

    return this._storage.set(
      buildObject(STORAGE_FIELDS.ADDRESS_FORMAT, String(format))
    );
  }

  public reset() {
    settingsStoreReset();

    const { rate, addressFormat } = this.store.getState();

    return this._storage.set(
      buildObject(STORAGE_FIELDS.RATE, String(rate)),
      buildObject(STORAGE_FIELDS.ADDRESS_FORMAT, String(addressFormat))
    );
  }

  public async sync() {
    const data = await this._storage.multiGet<string>(
      STORAGE_FIELDS.RATE,
      STORAGE_FIELDS.ADDRESS_FORMAT
    );

    if (typeof data !== 'object') {
      return null;
    }

    try {
      if (data[STORAGE_FIELDS.RATE]) {
        const rate = JSON.parse(data[STORAGE_FIELDS.RATE]);

        settingsStoreSetRate(rate);
      }
    } catch {
      //
    }

    if (data[STORAGE_FIELDS.ADDRESS_FORMAT]) {
      const format = data[STORAGE_FIELDS.ADDRESS_FORMAT];

      settingsStoreSetAddressFormat(format);
    }
  }
}
