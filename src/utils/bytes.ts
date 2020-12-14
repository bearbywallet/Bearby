/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */

/**
 * pack
 *
 * Takes two 16-bit integers and combines them. Used to compute version.
 *
 * @param {number} a
 * @param {number} b
 *
 * @returns {number} - a 32-bit number
 */
export const pack = (a: number, b: number): number => {
  if (a >> 16 > 0 || b >> 16 > 0) {
    throw new Error('Both a and b must be 16 bits or less');
  }

  return (a << 16) + b;
};
