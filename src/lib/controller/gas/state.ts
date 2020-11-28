/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { DEFAULT_GAS } from 'app/config';
import { newRidgeState } from 'react-ridge-state';
import { GasState } from 'types';

const initalState: GasState = DEFAULT_GAS;
export const gasStore = newRidgeState<GasState>(initalState);

export function gasStoreUpdate(payload: GasState) {
  gasStore.set(() => payload);
}
export function gasStoreReset() {
  gasStore.reset();
}
