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

export function fromZil(value: string, decimals: number, isRound = true): string {
  if (isNaN(Number(value)) || isNaN(decimals)) {
    return '0';
  }

  const _decimals = Big(10).pow(Number(decimals));
  const _amount = Big(value);
  const result = _amount.div(_decimals).toString();

  if (isRound) {
    return Number(Big(result).toFixed(3)).toString();
  }

  return result;
}
