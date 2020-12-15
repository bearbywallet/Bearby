/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { MobileStorage, buildObject } from 'app/lib/storage';
import { ZilliqaControl } from 'app/lib/controller/zilliqa';
import { NetworkControll } from 'app/lib/controller/network';

import { STORAGE_FIELDS, TokenTypes } from 'app/config';
import { Token, Account } from 'types';
import { tokensStore } from './state';
import { toZRC1 } from 'app/utils';

export class TokenControll {

  public static isUnique(token: Token, list: Token[]) {
    const isAddress = list.some((t) => {
      const { mainnet, testnet } = t.address;
      const checkMainnet = mainnet && mainnet === token.address.mainnet;
      const checkTestnet = testnet && testnet === token.address.testnet;
      const checkPrivate = t.address.private &&
        t.address.private === token.address.private;

      return checkMainnet || checkTestnet || checkPrivate;
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

  public async getTokensList(): Promise<Token[]> {
    const tokens = await this._storage.get(
      STORAGE_FIELDS.TOKENS
    );

    if (Array.isArray(tokens)) {
      return tokens;
    }

    return [];
  }

  public async getToken(address: string, acc: Account): Promise<Token> {
    const type = TokenTypes.ZRC2;
    const init = await this._zilliqa.getSmartContractInit(address);
    const zrc = toZRC1(init);
    const userAddress = acc.base16.toLowerCase();
    const field = 'balances';
    const totalSupplyField = 'total_supply';
    let totalSupply = await this._zilliqa.getSmartContractSubState(
      address,
      totalSupplyField
    );
    let balance = await this._zilliqa.getSmartContractSubState(
      address,
      field,
      [userAddress]
    );

    try {
      balance = balance[field][userAddress];
      totalSupply = totalSupply[totalSupplyField];
    } catch {
      balance = '0';
    }

    return {
      type,
      totalSupply,
      balance,
      name: zrc.name,
      symbol: zrc.symbol,
      decimals: zrc.decimals,
      address: {
        [this._network.selected]: zrc.address
      }
    };
  }

  public async addToken(token: Token) {
    const tokens = await this.getTokensList();

    TokenControll.isUnique(token, tokens);

    tokens.push(token);

    await this._update(tokens);

    return tokens;
  }

  private async _update(tokens: Token[]) {
    await this._storage.set(
      buildObject(STORAGE_FIELDS.TOKENS, tokens)
    );
  }
}
