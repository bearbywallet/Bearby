/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { createDomain, createEvent } from 'effector';
import { Settings } from 'types';
import { ADDRESS_FORMATS } from 'app/config';

export const settingsStoreUpdate = createEvent<Settings>();
export const settingsStoreSetAddressFormat = createEvent<string>();
export const settingsStoreSetRate = createEvent<number>();
export const settingsStoreReset = createEvent();

const SettingsDomain = createDomain();
const initalState: Settings = {
  addressFormat: ADDRESS_FORMATS[0],
  rate: 0.43243
};
export const settingsStore = SettingsDomain
  .store(initalState)
  .reset(settingsStoreReset)
  .on(settingsStoreUpdate, (_, payload) => payload)
  .on(settingsStoreSetRate, (state, rate) => ({ ...state, rate }))
  .on(settingsStoreSetAddressFormat, (state, addressFormat) => ({ ...state, addressFormat }));
