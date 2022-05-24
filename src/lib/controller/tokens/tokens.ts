/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import type { Token, Account, ServerResponse } from 'types';

import { MobileStorage, buildObject } from 'app/lib/storage';
import { ZilliqaControl } from 'app/lib/controller/zilliqa';
import { NetworkControll } from 'app/lib/controller/network';

import { API_RATE, STORAGE_FIELDS, TokenTypes, ZRC2Fields } from 'app/config';
import { tokensStore, tokensStoreUpdate, tokensStoreReset } from './state';
import { deppUnlink } from 'app/utils/deep-unlink';
import { toZRC1 } from 'app/utils/token';
import { tohexString } from 'app/utils/address';
import { Methods } from 'app/lib/controller/zilliqa/methods';
import { dexStore } from 'app/lib/controller/dex';


export class TokenControll {

  public static isUnique(token: Token, list: Token[]) {
    const isAddress = list.some((t) => {
      const { mainnet, testnet } = t.address;
      const checkMainnet = mainnet && mainnet === token.address.mainnet;
      const checkTestnet = testnet && testnet === token.address.testnet;
      const checkPrivate = t.address.private &&
        t.address.private === token.address.private;
      const samename = token.symbol === t.symbol;
      return checkMainnet || checkTestnet || checkPrivate || samename;
    });

    if (isAddress) {
      throw new Error('Token address must be unique');
    }
  }

  public store = tokensStore;

  private _network: NetworkControll;
  private _zilliqa: ZilliqaControl;
  private _storage: MobileStorage;

  constructor(zilliqa: ZilliqaControl, storage: MobileStorage, network: NetworkControll) {
    this._storage = storage;
    this._network = network;
    this._zilliqa = zilliqa;
  }

  public get deContract() {
    const state = dexStore.get();
    return state.contract[this._network.selected];
  }

  public async sync() {
    const tokens = await this._storage.get<string>(STORAGE_FIELDS.TOKENS);

    if (typeof tokens !== 'string') {
      return this._update(this.store.get());
    }

    try {
      tokensStoreUpdate(JSON.parse(tokens));
    } catch {
      await this._update(this.store.get());
    }
  }

  public async reset() {
    tokensStoreReset();
    await this._update(this.store.get());
  }

  public async getToken(address: string, acc: Account): Promise<Token> {
    let balance = '0';
    let totalSupply = '0';
    let rate = 0;
    let pool = ['0', '0'];
    const type = TokenTypes.ZRC2;
    const addr = tohexString(address);
    const net = this._network.selected;
    const userAddress = acc.base16.toLowerCase();
    const tokenAddressBase16 = address.toLowerCase();
    const identities = [
      this._zilliqa.provider.buildBody(Methods.GetSmartContractInit, [addr]),
      this._zilliqa.provider.buildBody(
        Methods.GetSmartContractSubState,
        [addr, ZRC2Fields.Balances, [userAddress]]
      ),
      this._zilliqa.provider.buildBody(
        Methods.GetSmartContractSubState,
        [addr, ZRC2Fields.TotalSupply, []]
      ),
      this._zilliqa.provider.buildBody(
        Methods.GetSmartContractSubState,
        [
          tohexString(this.deContract),
          ZRC2Fields.Pools,
          [tokenAddressBase16]
        ]
      )
    ];
    const replies = await this._zilliqa.sendJson(...identities);
    const zrc = toZRC1(replies[0].result);

    if (replies[1].result) {
      balance = replies[1].result[ZRC2Fields.Balances][userAddress];
    }
    if (replies[2].result) {
      totalSupply = replies[2].result[ZRC2Fields.TotalSupply];
    }
    if (replies[3].result) {
      const pair = replies[3].result[ZRC2Fields.Pools];
      pool = pair[tokenAddressBase16].arguments;
      const [zilReserve, tokenReserve] = pool;
      rate = this._calcRate(
        zilReserve,
        tokenReserve,
        zrc.decimals
      );
    }

    return {
      pool,
      type,
      totalSupply,
      balance,
      rate,
      name: zrc.name,
      symbol: zrc.symbol,
      decimals: zrc.decimals,
      address: {
        [this._network.selected]: zrc.address
      },
    };
  }

  public async addToken(token: Token) {
    const tokens = this.store.get();

    TokenControll.isUnique(token, tokens);

    tokens.push(token);

    await this._update(tokens);
  }

  public async loadingFromServer(limit = 30, offset = 0): Promise<ServerResponse> {
    const url = `${API_RATE}/tokens?limit=${limit}&${offset}=0&type=1`;
    const res = await fetch(url);
    const data = await res.json();

    return data;
  }

  public removeToken(token: Token) {
    if (token.default) {
      throw new Error('cannot remove default token.');
    }

    const tokens = this
      .store
      .get()
      .filter((t) => t.symbol !== token.symbol);

    return this._update(tokens);
  }

  public async updateRate(pools: object[]) {
    const tokens = this.store.get();
    const net = this._network.selected;

    tokens[0].pool = ['0', '0'];

    for (const res of pools) {
      try {
        const pool = res['result'][ZRC2Fields.Pools];
        const [base16] = Object.keys(pool);
        const foundIndex = tokens.findIndex(
          (t) => t.address[net].toLowerCase() === base16
        );
        const foundToken = tokens[foundIndex];
        const [zilReserve, tokenReserve] = pool[base16].arguments;

        tokens[foundIndex].pool = pool[base16].arguments;
        tokens[foundIndex].rate = this._calcRate(
          zilReserve,
          tokenReserve,
          foundToken.decimals
        );
      } catch (err) {
        continue;
      }
    }

    await this._update(tokens);
  }

  private async _update(tokens: Token[]) {
    tokensStoreUpdate(deppUnlink(tokens));

    await this._storage.set(
      buildObject(STORAGE_FIELDS.TOKENS, tokens)
    );
  }

  private _calcRate(zilReserve: string, tokenReserve: string, decimals: number) {
    const [ZIL] = this.store.get();
    const _zilReserve = Number(zilReserve) * Math.pow(10, -1 * ZIL.decimals);
    const _tokenReserve = Number(tokenReserve) * Math.pow(10, -1 * decimals);
    const exchangeRate = (_zilReserve / _tokenReserve).toFixed(6);

    return Number(exchangeRate);
  }
}
