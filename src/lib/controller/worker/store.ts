/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { newRidgeState } from 'react-ridge-state';

const initalState: number = 0;
export const blockStore = newRidgeState<number>(initalState);

export function blockStoreUpdate(payload: number) {
  blockStore.set(() => payload);
}

export function blockStoreReset() {
  blockStore.reset();
}
