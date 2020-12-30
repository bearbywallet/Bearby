/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { ADDRESS_FORMATS } from 'app/config';
import { newRidgeState } from 'react-ridge-state';
import { Settings } from 'types';
import { tokensStore } from 'app/lib/controller/tokens/state';

const [zil] = tokensStore.get();
const initalState: Settings = {
  addressFormat: ADDRESS_FORMATS[0],
  rate: {
    [zil.symbol]: 0
  }
};
export const settingsStore = newRidgeState<Settings>(initalState);

export function settingsStoreUpdate(payload: Settings) {
  settingsStore.set(() => payload);
}
export function settingsStoreSetAddressFormat(addressFormat: string) {
  settingsStore.set((prevState) => ({
    ...prevState,
    addressFormat
  }));
}
export function settingsStoreReset() {
  settingsStore.reset();
}
