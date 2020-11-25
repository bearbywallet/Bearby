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

export function amountFromPercent(value: string, percent: number): string {
  if (isNaN(Number(value)) || isNaN(percent)) {
    return '0';
  }

  const _100 = Big(100);
  const _percent = Big(percent);
  const _amount = Big(value);
  const result = _amount.div(_100).mul(_percent).round();

  return result.toString();
}
