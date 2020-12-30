/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { newRidgeState } from 'react-ridge-state';
import { SSN, SSNState } from 'types';

const initalState: SSNState = {
  selected: '',
  list: []
};
export const ssnStore = newRidgeState<SSNState>(initalState);

export function ssnStoreUpdate(list: SSN[]) {
  ssnStore.set((state) => ({
    ...state,
    list
  }));
}
export function selectSsnStoreUpdate(selected: string) {
  ssnStore.set((state) => ({
    ...state,
    selected
  }));
}
export function StoreUpdate(state: SSNState) {
  ssnStore.set(() => state);
}
export function ssnStoreReset() {
  ssnStore.reset();
}
