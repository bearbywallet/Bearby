/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { MobileStorage, buildObject } from '../storage';
import { ZilliqaControl } from './zilliqa';

import { STORAGE_FIELDS } from '../../config';
import { Token } from 'types';

export class TokenControll {

  public static isUnique(token: Token, list: Token[]) {
    const isAddress = list.some((t) => t.address === token.address);
    const isSymbol = list.some((t) => t.symbol === token.symbol);

    if (isAddress) {
      throw new Error('Token address must be unique');
    } else if (isSymbol) {
      throw new Error('Token symbol must be unique');
    }
  }

  private _network: ZilliqaControl;
  private _storage: MobileStorage;

  constructor(network: ZilliqaControl, storage: MobileStorage) {
    this._storage = storage;
    this._network = network;
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
    const tokens = await this.getTokensList();

    TokenControll.isUnique(token, tokens);

    tokens.push(token);

    return tokens;
  }

  private async _update(tokens: Token[]) {
    await this._storage.set(
      buildObject(STORAGE_FIELDS.TOKENS, tokens)
    );
  }
}
