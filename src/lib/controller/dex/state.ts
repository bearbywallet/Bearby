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
import { NIL_ADDRESS, ZILLIQA_KEYS } from 'app/config/app-constants';


const [mainnet, testnet, custom] = ZILLIQA_KEYS;
const initalState: DexState = {
  liquidityFee: 9950,
  protocolFee: 500,
  slippage: SLIPPAGE,
  blocks: BLOCKS,
  rewarded: NIL_ADDRESS,
  contract: {
    [mainnet]: '0x30dfe64740ed459ea115b517bd737bbadf21b838',
    [testnet]: '0xb0c677b5ba660925a8f1d5d9687d0c2c379e16ee',
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

export function dexStoreUpdate(payload: DexState) {
  dexStore.set((state) => ({
    ...payload,
    contract: state.contract
  }));
}


export function dexStoreReset() {
  dexStore.reset();
}
