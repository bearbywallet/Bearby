/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { Connect } from 'types';
import { newRidgeState } from 'react-ridge-state';

const initalState: Connect[] = [];
export const connectStore = newRidgeState<Connect[]>(initalState);

export function connectStoreUpdate(payload: Connect[]) {
  connectStore.set(() => payload);
}

export function connectStoreAdd(payload: Connect) {
  connectStore.set((state) => ([...state, payload]));
}

export function connectStoreRm(payload: Connect) {
  connectStore.set((state) => state.filter((el) => el.domain !== payload.domain));
}

export function connectStoreReset() {
  connectStore.reset();
}
