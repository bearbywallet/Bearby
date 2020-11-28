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

import { STORAGE_FIELDS } from 'app/config';
import { Token } from 'types';
import { tokensStore } from './state';

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

  public async addToken(token: Token) {
    let tokens = await this.getTokensList();

    TokenControll.isUnique(token, tokens);
    const hasSymbol = tokens.some(
      (t) => t.symbol === token.symbol
    );

    if (hasSymbol) {
      tokens = tokens.map((t) => {
        const { selected } = this._network;

        t.address[selected] = token.address[selected];
        t.balance[selected] = token.balance[selected];

        return t;
      });
    } else {
      tokens.push(token);
    }

    await this._update(tokens);

    return tokens;
  }

  private async _update(tokens: Token[]) {
    await this._storage.set(
      buildObject(STORAGE_FIELDS.TOKENS, tokens)
    );
  }
}
