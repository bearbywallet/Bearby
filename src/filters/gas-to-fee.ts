/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import Big from 'big.js';

Big.PE = 99;

const _li = Big(10 ** 6);

export function toLi(value: string | number) {
  const _value = Big(value);
  return _value.div(_li).toString();
}

export function fromLI(value: string | number) {
  const _value = Big(value);
  return _value.mul(_li).toString();
}

export function gasToFee(gasLimit: string, gasPrice: string) {
  if (isNaN(Number(gasLimit)) || isNaN(Number(gasPrice))) {
    return {
      _fee: Big(0),
      fee: '0'
    };
  }

  const _gasPrice = Big(gasPrice).round();
  const _gasLimit = Big(gasLimit).round();
  const _fee = _gasLimit.mul(_gasPrice);
  const fee = _fee.div(_li);

  return {
    _fee: _fee.mul(_li),
    fee
  };
}
