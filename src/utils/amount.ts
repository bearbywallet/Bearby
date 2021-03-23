/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import Big from 'big.js';
import { GasState, Token } from 'types';
import { keystore } from 'app/keystore';
import { gasToFee } from 'app/filters';

Big.PE = 99;

export class Amount {
  public readonly _li = Big(10 ** 6);
  public readonly _100 = Big(100);
  public _balance: Big;
  public _fee: Big;
  public _gasPrice: Big;
  public _gasLimit: Big;

  constructor(gas: GasState, balance: string) {
    this._balance = Big(balance);

    this._gasPrice = Big(gas.gasPrice).round();
    this._gasLimit = Big(gas.gasLimit).round();
    this._fee = gasToFee(gas.gasLimit, gas.gasPrice)._fee;
  }

  public get fee() {
    return this._fee.div(this._li).toString();
  }

  public get max(): Big {
    return this._balance.sub(this.fee);
  }

  public insufficientFunds(amount: string, token: Token) {
    const [zilliqa] = keystore.token.store.get();

    const _amount = token.symbol === zilliqa.symbol ?
      Big(amount).add(this._fee) : Big(amount);

    return _amount.gt(this._balance);
  }

  public fromPercent(percent: number, token: Token): Big {
    const [zilliqa] = keystore.token.store.get();
    const _amount = token.symbol === zilliqa.symbol ?
      Big(this._balance).sub(this._fee) : Big(this._balance);

    const _percent = Big(percent);
    const result = _amount.div(this._100).mul(_percent).round();

    return result;
  }
}
