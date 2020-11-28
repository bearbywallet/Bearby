/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import {
  currenciesStore,
  currenciesStoreUpdate,
  currenciesStoreReset
} from './store';
import { MobileStorage, buildObject } from 'app/lib/storage';
import {
  DEFAULT_CURRENCIES,
  STORAGE_FIELDS
} from 'app/config';

export class CurrencyControler {
  public readonly store = currenciesStore;
  public readonly currencies = DEFAULT_CURRENCIES;
  private _storage: MobileStorage;

  constructor(storage: MobileStorage) {
    this._storage = storage;
  }

  public set(currency: string) {
    currency = currency.toLowerCase();

    currenciesStoreUpdate(currency);

    return this._storage.set(
      buildObject(STORAGE_FIELDS.CURRENCY, currency)
    );
  }

  public reset() {
    currenciesStoreReset();

    return this._storage.set(
      buildObject(STORAGE_FIELDS.CURRENCY, this.store.get())
    );
  }

  public async sync() {
    const currency = await this._storage.get<string>(
      STORAGE_FIELDS.CURRENCY
    );

    if (typeof currency === 'string') {
      currenciesStoreUpdate(currency);
    }
  }
}
