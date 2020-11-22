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

export function gasToFee(gasLimit: string, gasPrice: string): string {
  if (isNaN(Number(gasLimit)) || isNaN(Number(gasPrice))) {
    return '0';
  }

  const _ten = Big(10);
  const _decimals = _ten.pow(12);
  const _gasLimit = Big(gasLimit);
  const _gasPrice = Big(gasPrice);
  const _fee = _gasLimit.mul(_gasPrice);

  return _fee.mul(_decimals).toString();
}
