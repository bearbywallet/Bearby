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
  CurrenciesStoreReset
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

  public setCurrency(currency: string) {
    currenciesStoreUpdate(currency);

    return this._storage.set(
      buildObject(STORAGE_FIELDS.CURRENCY, currency)
    );
  }

  public reset() {
    CurrenciesStoreReset();

    return this._storage.set(
      buildObject(STORAGE_FIELDS.CURRENCY, this.store.getState())
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
