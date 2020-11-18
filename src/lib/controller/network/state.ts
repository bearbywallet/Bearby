/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { createDomain, createEvent } from 'effector';
import { ZILLIQA } from 'app/config';
import { NetwrokState } from 'types';

export const networkStoreUpdate = createEvent<NetwrokState>();
export const setNetworkStore = createEvent<string>();
export const setConfigNetworkStore = createEvent<typeof ZILLIQA>();
export const networkStoreReset = createEvent();

const [mainnet] = Object.keys(ZILLIQA);
const networkDomain = createDomain();
const initalState: NetwrokState = {
  selected: mainnet,
  config: ZILLIQA
};
export const networkStore = networkDomain
  .store<NetwrokState>(initalState)
  .on(networkStoreUpdate, (_, payload) => payload)
  .on(setNetworkStore, (state, selected) => ({ ...state, selected }))
  .on(setConfigNetworkStore, (state, config) => ({ ...state, config }))
  .reset(networkStoreReset);
