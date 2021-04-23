/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { newRidgeState } from 'react-ridge-state';

const initalState = {
  selected: 0,
  list: [
    {
      name: 'General',
      url: 'https://ipfs.io/ipfs',
      value: '0'
    },
    {
      name: 'Pinata',
      url: 'https://gateway.pinata.cloud/ipfs',
      value: '0'
    },
    {
      name: 'Gateway',
      url: 'https://gateway.ipfs.io/ipfs',
      value: '0'
    },
    {
      name: 'Infura',
      url: 'https://ipfs.infura.io/ipfs',
      value: '0'
    },
    {
      name: 'Cloudflare',
      url: 'https://cloudflare-ipfs.com/ipfs',
      value: '0'
    }
  ]
};
export const ipfsStore = newRidgeState(initalState);

export function ipfsStoreUpdate(payload: typeof initalState) {
  ipfsStore.set(() => payload);
}
export function ipfsSelect(selected: number) {
  ipfsStore.set((state) => ({
    ...state,
    selected
  }));
}
export function ipfsStoreReset() {
  ipfsStore.reset();
}
