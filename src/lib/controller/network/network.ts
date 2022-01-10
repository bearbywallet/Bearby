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
import WebView from 'react-native-webview';
import { MobileStorage, buildObject } from 'app/lib/storage';
import { ZILLIQA, STORAGE_FIELDS, Messages } from 'app/config';
import { ZilliqaNetwork } from 'types';
import { connectStore } from 'app/lib/controller/connect';
import { accountStore } from 'app/lib/controller/account/sate';
import { Message } from 'app/lib/controller/inject/message';

const defualtNetwroks = Object.keys(ZILLIQA);
const [mainnet, testnet, privateNet] = defualtNetwroks;

export class NetworkControll {
  public static defualtNetwroks = defualtNetwroks;
  public static isValidSelected(selected: string) {
    if (!defualtNetwroks.includes(selected)) {
      throw new Error('unavailable network');
    }
  }

  public readonly store = networkStore;
  private _storage: MobileStorage;
  private _onlyMainnet: boolean;
  private _webView: WebView | undefined;
  private _origin: string | undefined;

  constructor(storage: MobileStorage, onlyMainnet = false) {
    this._storage = storage;
    this._onlyMainnet = onlyMainnet;
  }

  public get selected() {
    if (this._onlyMainnet) {
      return mainnet;
    }

    return this.store.get().selected;
  }

  public get config(): typeof ZILLIQA {
    return this.store.get().config;
  }

  public get http() {
    return this._getHTTP(this.selected);
  }

  public get nativeHttp() {
    return ZILLIQA[this.selected].PROVIDER;
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

  public updateWebView(webView: WebView | undefined, origin = '') {
    this._webView = webView;
    this._origin = origin;
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

    this._updateWebView();

    return this.self;
  }

  public async changeConfig(config: ZilliqaNetwork) {
    const { WS, PROVIDER, MSG_VERSION } = config[privateNet];

    if (!WS || !PROVIDER || !MSG_VERSION) {
      throw new Error('missed properties');
    }

    setConfigNetworkStore(config);

    await this._storage.set(
      buildObject(STORAGE_FIELDS.CONFIG, config)
    );

    this._updateWebView();

    return config;
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

      this._updateWebView();
    } catch (err) {
      return null;
    }
  }

  public async reset() {
    networkStoreReset();

    const { selected, config } = this.store.get();

    await this._storage.set(
      buildObject(STORAGE_FIELDS.CONFIG, config),
      buildObject(STORAGE_FIELDS.SELECTED_NET, selected)
    );

    this._updateWebView();
  }

  private _updateWebView() {
    if (this._webView && this._origin) {
      const connections = connectStore.get();
      const accounts = accountStore.get();
      const isConnect = connections.some(
        (c) => c.domain.toLowerCase() === String(this._origin).toLowerCase()
      );
      const { base16, bech32 } = accounts.identities[accounts.selectedAddress];
      this._webView.postMessage(new Message(Messages.init).serialize({
        isConnect,
        account: isConnect ? {
          base16,
          bech32
        } : null,
        isEnable: true,
        netwrok: this.selected,
        http: this.http
      }));
    }
  }

  private _getHTTP(selected: string) {
    return this.config[selected].PROVIDER;
  }

  private _getWS(selected: string) {
    return this.config[selected].WS;
  }
}
