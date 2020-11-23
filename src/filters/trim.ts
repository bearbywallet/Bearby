/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */

export function trim(addr: string, length = 6) {
  if (!addr) {
    return null;
  }

  const part0 = addr.substr(0, length);
  const part1 = addr.substr(length * -1);

  return `${part0}...${part1}`;
}