/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
export function millisToMinutesAndSeconds(millis: number) {
  const minutes = (millis / 60000);

  return minutes.toFixed(5);
}
