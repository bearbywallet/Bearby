/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { newRidgeState } from 'react-ridge-state';
import { createDomain, createEvent } from 'effector';
import { AccountState } from 'types';

const initalState: AccountState = {
  identities: [],
  selectedAddress: 0
};
export const accountStore = newRidgeState<AccountState>(initalState);

export function accountStoreUpdate(payload: AccountState) {
  accountStore.set(() => payload);
}
export function accountStoreSelect(selectedAddress: number) {
  accountStore.set((prevState) => ({
    ...prevState,
    selectedAddress
  }));
}
export function accountStoreReset() {
  accountStore.reset();
}
