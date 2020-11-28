/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import {
  themesStore,
  themesStoreReset,
  themesStoreUpdate
} from './store';
import { MobileStorage, buildObject } from 'app/lib/storage';
import {
  DEFAULT_THEMES,
  STORAGE_FIELDS
} from 'app/config';

export class ThemeControler {
  public readonly store = themesStore;
  public readonly themes = DEFAULT_THEMES;
  private _storage: MobileStorage;

  constructor(storage: MobileStorage) {
    this._storage = storage;
  }

  public set(currency: string) {
    themesStoreUpdate(currency);

    return this._storage.set(
      buildObject(STORAGE_FIELDS.THEME, currency)
    );
  }

  public reset() {
    themesStoreReset();

    return this._storage.set(
      buildObject(STORAGE_FIELDS.THEME, this.store.get())
    );
  }

  public async sync() {
    const currency = await this._storage.get<string>(
      STORAGE_FIELDS.THEME
    );

    if (typeof currency === 'string') {
      themesStoreUpdate(currency);
    }
  }
}
