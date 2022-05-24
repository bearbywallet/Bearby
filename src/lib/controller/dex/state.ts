/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2022 ZilPay
 */
import type { DexState } from 'types/store';

import { newRidgeState } from 'react-ridge-state';
import { SLIPPAGE, BLOCKS } from 'app/config/dex';
import { ZILLIQA_KEYS } from 'app/config/app-constants';


const [mainnet, testnet, custom] = ZILLIQA_KEYS;
const initalState: DexState = {
  liquidityFee: 9950,
  protocolFee: 500,
  slippage: SLIPPAGE,
  blocks: BLOCKS,
  contract: {
    [mainnet]: '0x459cb2d3baf7e61cfbd5fe362f289ae92b2babb0',
    [testnet]: '0x5f35fbabfe7226147914eb296253a68538ac33ee',
    [custom]: ''
  }
};
export const dexStore = newRidgeState<DexState>(initalState);

export function dexStoreSetFee(liquidityFee: number, protocolFee: number) {
  dexStore.set((state) => ({
    ...state,
    liquidityFee,
    protocolFee
  }));
}

export function dexStoreSetSettings(slippage: number, blocks: number) {
  dexStore.set((state) => ({
    ...state,
    slippage,
    blocks
  }));
}

export function dexStoreReset() {
  dexStore.reset();
}
