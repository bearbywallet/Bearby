/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */

/**
 * Split an array to some chunks.
 * @param arr Array of items.
 * @param chunk number of chunks in Array.
 * @example
 * import { splitByChunk } from 'app/utils';
 * const test = [1, 2, 3, 4, 5, 6, 7, 8]
 * splitByChunk<number>(test, 2) => [[1, 2], [3, 4], [5, 6], [7, 8]]
 */
export function splitByChunk<T>(arr: T[], chunk: number) {
  const splited = [];

  for (let i = 0; i < arr.length; i += chunk) {
      splited.push(arr.slice(i, i + chunk));
  }

  return splited;
}
