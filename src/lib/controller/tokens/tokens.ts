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

import { STORAGE_FIELDS, TokenTypes, ZRC2Fields } from 'app/config';
import { Token, Account } from 'types';
import { tokensStore, tokensStoreUpdate } from './state';
import { toZRC1, deppUnlink, tohexString } from 'app/utils';
import { Methods } from '../zilliqa/methods';

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

  public async getToken(address: string, acc: Account): Promise<Token> {
    let balance = '0';
    let totalSupply = '0';
    const type = TokenTypes.ZRC2;
    const totalSupplyField = 'total_supply';
    const addr = tohexString(address);
    const userAddress = acc.base16.toLowerCase();
    const identities = [
      this._zilliqa.provider.buildBody(Methods.GetSmartContractInit, [addr]),
      this._zilliqa.provider.buildBody(
        Methods.GetSmartContractSubState,
        [addr, ZRC2Fields.Balances, [userAddress]]
      ),
      this._zilliqa.provider.buildBody(
        Methods.GetSmartContractSubState,
        [addr, totalSupplyField, []]
      )
    ];
    const replies = await this._zilliqa.sendJson(...identities);
    const zrc = toZRC1(replies[0].result);

    if (replies[1].result) {
      balance = replies[1].result[ZRC2Fields.Balances][userAddress];
    }
    if (replies[2].result) {
      totalSupply = replies[2].result[totalSupplyField];
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
    const tokens = this.store.get();

    TokenControll.isUnique(token, tokens);

    tokens.push(token);

    await this._update(tokens);
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

  private async _update(tokens: Token[]) {
    tokensStoreUpdate(deppUnlink(tokens));

    await this._storage.set(
      buildObject(STORAGE_FIELDS.TOKENS, tokens)
    );
  }
}
