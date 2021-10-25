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
  settingsStoreSetAddressFormat,
  settingsStoreUpdate,
  settingsStoreReset
} from './store';
import { MobileStorage, buildObject } from 'app/lib/storage';
import {
  STORAGE_FIELDS,
  ADDRESS_FORMATS,
  API_COINGECKO,
  DEFAULT_CURRENCIES,
  ZIL_SWAP_CONTRACTS
} from 'app/config';
import { ZilliqaControl, TokenControll, NetworkControll } from 'app/lib/controller';
import { currenciesStore } from 'app/lib/controller/currency/store';
import { Methods } from '../zilliqa/methods';
import { tohexString } from 'app/utils';
import { RPCResponse } from 'types';

export class SettingsControler {
  public readonly store = settingsStore;
  public readonly formats = ADDRESS_FORMATS;
  private _storage: MobileStorage;
  private _zilliqa: ZilliqaControl;
  private _tokens: TokenControll;
  private _netwrok: NetworkControll;

  constructor(
    storage: MobileStorage,
    zilliqa: ZilliqaControl,
    tokens: TokenControll,
    netwrok: NetworkControll
  ) {
    this._storage = storage;
    this._zilliqa = zilliqa;
    this._tokens = tokens;
    this._netwrok = netwrok;
  }

  public get rate() {
    const state = this.store.get();
    const [zil] = this._tokens.store.get();

    return state.rate[zil.symbol];
  }

  public getRate(symbol: string) {
    const rate = this.store.get().rate[symbol];

    if (!rate) {
      return 0;
    }

    return rate;
  }

  public async rateUpdate() {
    const currencies = DEFAULT_CURRENCIES.join();
    const url = `${API_COINGECKO}?ids=zilliqa&vs_currencies=${currencies}`;

    const response = await fetch(url);
    const data = await response.json();
    const rate = data.zilliqa;
    const currency = currenciesStore.get();
    const state = this.store.get();
    const [zil] = this._tokens.store.get();

    state.rate[zil.symbol] = rate[currency];

    settingsStoreUpdate(state);

    return this._storage.set(
      buildObject(STORAGE_FIELDS.SETTINGS, state)
    );
  }

  public async getDexRate() {
    const fieldname = 'pools';
    const net = this._netwrok.selected;
    const contract = tohexString(ZIL_SWAP_CONTRACTS[net]);
    const state = this.store.get();
    const tokens = this._tokens.store.get();
    const [zil] = tokens;
    const identities = tokens.filter((t) => t.symbol !== zil.symbol).map((t) => {
      const tokenAddress = t.address[net].toLowerCase();

      return this._zilliqa.provider.buildBody(
        Methods.GetSmartContractSubState,
        [contract, fieldname, [tokenAddress]]
      );
    });
    const replies = await this._zilliqa.sendJson(...identities);
    const entries = Array.from(replies as RPCResponse[]).map((res, index: number) => {
      const token = tokens[index + 1];
      const tokenAddress = token.address[net].toLowerCase();
      const [zilReserve, tokenReserve] = res.result[fieldname][tokenAddress].arguments;
      const _zilReserve = zilReserve * Math.pow(10, -1 * zil.decimals);
      const _tokenReserve = tokenReserve * Math.pow(10, -1 * token.decimals);
      const exchangeRate = (_zilReserve / _tokenReserve).toFixed(10);
      const rate = this.rate * Number(exchangeRate);

      return [token.symbol, Math.fround(rate)];
    });
    const rates = Object.fromEntries(entries);

    state.rate = {
      ...state.rate,
      ...rates
    };

    settingsStoreUpdate(state);
    return this._storage.set(
      buildObject(STORAGE_FIELDS.SETTINGS, state)
    );
  }

  public setFormat(format: string) {
    settingsStoreSetAddressFormat(format);

    return this._storage.set(
      buildObject(STORAGE_FIELDS.SETTINGS, this.store.get())
    );
  }

  public reset() {
    settingsStoreReset();

    return this._storage.set(
      buildObject(STORAGE_FIELDS.SETTINGS, this.store.get())
    );
  }

  public async sync() {
    const settings = await this._storage.get(STORAGE_FIELDS.SETTINGS);

    try {
      if (!settings || typeof settings !== 'string') {
        throw new Error('bad response');
      }

      const parsed = JSON.parse(settings);

      settingsStoreUpdate(parsed);
    } catch {
      await this.reset();
    }
  }
}
