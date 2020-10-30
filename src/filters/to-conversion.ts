/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { fromZil } from './from-zil';

export function toConversion(value: string, rate: number, decimals: number) {
  if (isNaN(rate) || Number(value) <= 0) {
    return '0';
  }

  const inFloat = Number(fromZil(value, decimals));
  const converted = inFloat * rate;

  return (converted).toFixed(3);
}
