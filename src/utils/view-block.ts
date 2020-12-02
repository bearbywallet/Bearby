/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import {
  VIEW_BLOCK_METHODS,
  VIEW_BLOCK_URL
} from 'app/config';

export function viewAddress(address: string, netwrok: string) {
  const url = VIEW_BLOCK_URL;
  const type = VIEW_BLOCK_METHODS.address;

  return `${url}/${type}/${address}?network=${netwrok}`;
}

export function viewTransaction(hash: string, netwrok: string) {
  const url = VIEW_BLOCK_URL;
  const type = VIEW_BLOCK_METHODS.tx;

  return `${url}/${type}/${hash}?network=${netwrok}`;
}

export function viewBlockNumber(blockNumber: string | number, netwrok: string) {
  const url = VIEW_BLOCK_URL;
  const type = VIEW_BLOCK_METHODS.block;

  return `${url}/${type}/${blockNumber}?network=${netwrok}`;
}
