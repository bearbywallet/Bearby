/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import {
  networkStore,
  setNetworkStore,
  setConfigNetworkStore,
  networkStoreReset
} from './state';
import { MobileStorage, buildObject } from 'app/lib/storage';
import { ZILLIQA, STORAGE_FIELDS } from 'app/config';
import { ZilliqaNetwork } from 'types';

const defualtNetwroks = Object.keys(ZILLIQA);
const [mainnet, testnet, privateNet] = defualtNetwroks;

export class NetworkControll {
  public static isValidSelected(selected: string) {
    if (!defualtNetwroks.includes(selected)) {
      throw new Error('unavailable network');
    }
  }

  public readonly store = networkStore;
  private _storage: MobileStorage;

  constructor(storage: MobileStorage) {
    this._storage = storage;
  }

  public get selected() {
    return this.store.getState().selected;
  }

  public get config(): typeof ZILLIQA {
    return this.store.getState().config;
  }

  public get http() {
    return this._getHTTP(this.selected);
  }

  public get ws() {
    return this._getWS(this.selected);
  }

  public get version() {
    return this.config[this.selected].MSG_VERSION;
  }

  public get self() {
    return {
      selected: this.selected,
      http: this.http,
      ws: this.ws
    };
  }

  public async changeNetwork(selected: string) {
    NetworkControll.isValidSelected(selected);

    if (selected === this.selected) {
      return this.self;
    }

    setNetworkStore(selected);

    await this._storage.set(
      buildObject(STORAGE_FIELDS.SELECTED_NET, selected)
    );

    return this.self;
  }

  public async changeConfig(config: ZilliqaNetwork) {
    const { WS, PROVIDER, MSG_VERSION } = config[privateNet];

    if (!WS || !PROVIDER || !MSG_VERSION) {
      throw new Error('missed properties');
    }

    const newConfig = {
      ...ZILLIQA,
      [privateNet]: config[privateNet]
    };

    setConfigNetworkStore(newConfig);

    await this._storage.set(
      buildObject(STORAGE_FIELDS.CONFIG, newConfig)
    );

    return newConfig;
  }

  public async sync() {
    const data = await this._storage.multiGet<string>(
      STORAGE_FIELDS.CONFIG,
      STORAGE_FIELDS.SELECTED_NET
    );

    try {
      if (data && data[STORAGE_FIELDS.SELECTED_NET]) {
        const selected = String(data[STORAGE_FIELDS.SELECTED_NET]);

        setNetworkStore(selected);
      }

      if (data && data[STORAGE_FIELDS.CONFIG]) {
        const config = JSON.parse(data[STORAGE_FIELDS.CONFIG]);

        setConfigNetworkStore(config);
      }
    } catch (err) {
      return null;
    }
  }

  public async reset() {
    networkStoreReset();

    const { selected, config } = this.store.getState();

    await this._storage.set(
      buildObject(STORAGE_FIELDS.CONFIG, config),
      buildObject(STORAGE_FIELDS.SELECTED_NET, selected)
    );
  }

  private _getHTTP(selected: string) {
    return this.config[selected].PROVIDER;
  }

  private _getWS(selected: string) {
    return this.config[selected].WS;
  }
}
