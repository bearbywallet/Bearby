/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { changeBarColors } from 'react-native-immersive-bars';
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
import { theme } from 'app/styles';
import { Device } from 'app/utils';

export class ThemeControler {
  public readonly store = themesStore;
  public readonly themes = DEFAULT_THEMES;
  private _storage: MobileStorage;

  constructor(storage: MobileStorage) {
    this._storage = storage;
  }

  public set(type: string) {
    themesStoreUpdate(type);
    this._updateColors();

    return this._storage.set(
      buildObject(STORAGE_FIELDS.THEME, type)
    );
  }

  public reset() {
    themesStoreReset();
    this._updateColors();

    return this._storage.set(
      buildObject(STORAGE_FIELDS.THEME, this.store.get())
    );
  }

  public async sync() {
    const type = await this._storage.get<string>(
      STORAGE_FIELDS.THEME
    );

    if (typeof type === 'string') {
      themesStoreUpdate(type);
    }

    this._updateColors();
  }

  private _updateColors() {
    if (Device.isAndroid()) {
      const type = this.store.get();
      const { dark, colors } = theme[type];

      changeBarColors(dark, colors.background, colors.background);
    }
  }
}
