/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { newRidgeState } from 'react-ridge-state';
import { AccountState } from 'types';
import { deppUnlink } from 'app/utils/deep-unlink';

const initalState: AccountState = {
  identities: [],
  selectedAddress: 0
};
export const accountStore = newRidgeState<AccountState>(initalState);

export function accountStoreUpdate(payload: AccountState) {
  accountStore.set(() => deppUnlink(payload));
}
export function accountStoreSelect(selectedAddress: number) {
  accountStore.set((prevState) => deppUnlink({
    ...prevState,
    selectedAddress
  }));
}
export function accountStoreReset() {
  accountStore.reset();
}
