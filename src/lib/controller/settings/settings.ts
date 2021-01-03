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
  ZIL_SWAP_CONTRACTS,
  ZILLIQA_KEYS
} from 'app/config';
import { ZilliqaControl, TokenControll, NetworkControll } from 'app/lib/controller';
import { currenciesStore } from 'app/lib/controller/currency/store';

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

    return this._storage.set(
      buildObject(STORAGE_FIELDS.SETTINGS, state)
    );
  }

  public async getDexRate() {
    const fieldname = 'pools';
    const contract = ZIL_SWAP_CONTRACTS[this._netwrok.selected];
    const state = this.store.get();
    const tokens = this._tokens.store.get();
    const [zil] = tokens;

    for (const token of tokens) {
      if (token.symbol === zil.symbol) {
        continue;
      }

      const tokenAddress = token.address[this._netwrok.selected];
      const pool = await this._zilliqa.getSmartContractSubState(
        contract,
        fieldname,
        [tokenAddress]
      );

      if (!pool || !pool[fieldname] || !pool[fieldname][tokenAddress]) {
        return {
          symbol: token.symbol,
          zilReserve: '0',
          tokenReserve: '0',
          exchangeRate: '0',
          rate: '0'
        };
      }

      const [zilReserve, tokenReserve] = pool[fieldname][tokenAddress].arguments;
      const _zilReserve = zilReserve * Math.pow(10, -1 * zil.decimals);
      const _tokenReserve = tokenReserve * Math.pow(10, -1 * token.decimals);
      const exchangeRate = (_zilReserve / _tokenReserve).toFixed(10);

      state.rate[token.symbol] = this.rate * Number(exchangeRate);

      if (!state.rate[token.symbol] || isNaN(state.rate[token.symbol])) {
        state.rate[token.symbol] = 0;
      }
    }

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
