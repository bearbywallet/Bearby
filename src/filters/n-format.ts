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

const si = [
  { value: Big(1), symbol: '' },
  { value: Big(1), symbol: '' },
  { value: Big(1E6), symbol: 'M' },
  { value: Big(1E9), symbol: 'G' },
  { value: Big(1E12), symbol: 'T' },
  { value: Big(1E15), symbol: 'P' },
  { value: Big(1E18), symbol: 'E' }
];
export function nFormatter(num: string, digits = 3) {
  if (Number(num) === 0) {
    return '0';
  }

  const _num = Big(num);
  const rx = /\.0+$|(\.[0-9]*[1-9])0+$/;
  let i;

  for (i = si.length - 1; i > 0; i--) {
    if (_num.gte(Big(si[i].value))) {
      break;
    }
  }

  return _num
    .div(si[i].value)
    .toFixed(digits)
    .toLocaleString()
    .replace(rx, "$1") + si[i].symbol;
}
