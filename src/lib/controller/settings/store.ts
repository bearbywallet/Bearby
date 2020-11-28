/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { ADDRESS_FORMATS, DEFAULT_CURRENCIES } from 'app/config';
import { newRidgeState } from 'react-ridge-state';
import { Settings } from 'types';

const initalState: Settings = {
  addressFormat: ADDRESS_FORMATS[0],
  rate: {
    [DEFAULT_CURRENCIES[0].toLowerCase()]: 0,
    [DEFAULT_CURRENCIES[1].toLowerCase()]: 0,
    [DEFAULT_CURRENCIES[2].toLowerCase()]: 0,
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
export function settingsStoreSetRate(rate: { [key: string]: number; }) {
  settingsStore.set((prevState) => ({
    ...prevState,
    rate
  }));
}
export function settingsStoreReset() {
  settingsStore.reset();
}
