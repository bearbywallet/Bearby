/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { keystore } from 'app/keystore';
import numbro from 'numbro';


const options: numbro.Format = {
  thousandSeparated: true,
  mantissa: 5,
  average: true,
  trimMantissa: true
};


export function nFormatter(num: string | number, opt?: numbro.Format) {
  const { formated } = keystore.settings.store.get();

  if (!formated) {
    return num;
  }

  if (Number(num) === 0) {
    return '0';
  }

  return numbro(num).format({
    ...options,
    ...opt
  });
}
