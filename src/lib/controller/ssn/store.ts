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
import { DEFAULT_SSN, ZILLIQA, ZILLIQA_KEYS } from 'app/config';

const [mainnet] = ZILLIQA_KEYS;
const initalState: SSNState = {
  selected: DEFAULT_SSN,
  list: [{
      address: '',
      name: DEFAULT_SSN,
      api: ZILLIQA[mainnet].PROVIDER,
      ok: true,
      id: 1,
      time: 291.0395320057869
  }]
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
