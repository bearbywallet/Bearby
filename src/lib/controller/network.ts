/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { MobileStorage, buildObject } from '../storage';
import { ZILLIQA, STORAGE_FIELDS } from '../../config';
import { ZilliqaNetwork } from 'types';

const defualtNetwroks = Object.keys(ZILLIQA);
const [mainnet, testnet, privateNet] = defualtNetwroks;

let _selected = mainnet;
let _config = JSON.stringify(ZILLIQA);

export class NetworkControll {

  public static isValidSelected(selected: string) {
    if (!defualtNetwroks.includes(selected)) {
      throw new Error('unavailable network');
    }
  }

  private _storage: MobileStorage;

  constructor(storage: MobileStorage, config = ZILLIQA, selected = mainnet) {
    NetworkControll.isValidSelected(selected);

    _config = JSON.stringify(config);
    _selected = selected;

    this._storage = storage;
  }

  public get selected() {
    return _selected;
  }

  public get config(): ZilliqaNetwork {
    return JSON.parse(_config);
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
      selected: _selected,
      http: this.http,
      ws: this.ws
    };
  }

  public async changeNetwork(selected: string) {
    NetworkControll.isValidSelected(selected);

    if (selected === this.selected) {
      return this.self;
    }

    await this._storage.set(
      buildObject(STORAGE_FIELDS.SELECTED_NET, selected)
    );

    _selected = selected;

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

    await this._storage.set(
      buildObject(STORAGE_FIELDS.CONFIG, newConfig)
    );

    _config = JSON.stringify(newConfig);

    return newConfig;
  }

  public async sync() {
    const data = await this._getStore();

    if (data && data[STORAGE_FIELDS.SELECTED_NET]) {
      await this.changeNetwork(_selected);
    }

    if (data && data[STORAGE_FIELDS.CONFIG]) {
      await this.changeConfig(this.config);
    }

    await this._update();

    return self;
  }

  private _getHTTP(selected: string) {
    return this.config[selected].PROVIDER;
  }

  private _getWS(selected: string) {
    return this.config[selected].WS;
  }

  private _getStore() {
    return this._storage.multiGet<ZilliqaNetwork | string>(
      STORAGE_FIELDS.CONFIG,
      STORAGE_FIELDS.SELECTED_NET
    );
  }

  private async _update() {
    const data = await this._getStore();
    const selected = data[STORAGE_FIELDS.SELECTED_NET];
    const config = data[STORAGE_FIELDS.CONFIG];

    if (typeof selected === 'string') {
      _selected = selected;
    }

    if (typeof config === 'object') {
      _config = JSON.stringify(config);
    }
  }
}
