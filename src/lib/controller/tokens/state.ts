/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { newRidgeState } from 'react-ridge-state';

import { Token } from 'types';
import { ZILLIQA_KEYS, NIL_ADDRESS, TokenTypes } from 'app/config';

const [mainnet, testnet, privatenet] = ZILLIQA_KEYS;
const identities: Token[] = [
  {
    type: TokenTypes.ZRC2,
    address: {
      [mainnet]: NIL_ADDRESS,
      [testnet]: NIL_ADDRESS,
      [privatenet]: NIL_ADDRESS
    },
    decimals: 12,
    default: true,
    name: 'Zilliqa',
    symbol: 'ZIL',
    rate: 1,
    pool: ['0', '0']
  },
  {
    type: TokenTypes.ZRC2,
    address: {
      [mainnet]: '0xfbd07e692543d3064b9cf570b27faabfd7948da4',
      [testnet]: '0x6f0b1fbda199dc4abfda28fa2eaa299599b3e8f2'
    },
    decimals: 18,
    default: true,
    name: 'ZilPay wallet',
    symbol: 'ZLP',
    rate: 0
  }
];

export const tokensStore = newRidgeState(identities);

export function tokensStoreUpdate(payload: typeof identities) {
  tokensStore.set(() => payload);
}
export function tokensStoreReset() {
  tokensStore.reset();
}
