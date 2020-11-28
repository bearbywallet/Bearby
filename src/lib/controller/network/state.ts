/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { newRidgeState } from 'react-ridge-state';

import { ZILLIQA } from 'app/config';
import { NetwrokState } from 'types';

const [mainnet] = Object.keys(ZILLIQA);
const initalState: NetwrokState = {
  selected: mainnet,
  config: ZILLIQA
};
export const networkStore = newRidgeState<NetwrokState>(initalState);

export function networkStoreUpdate(payload: NetwrokState) {
  networkStore.set(() => payload);
}
export function setNetworkStore(selected: string) {
  networkStore.set((prevState) => ({
    ...prevState,
    selected
  }));
}
export function setConfigNetworkStore(config: typeof ZILLIQA) {
  networkStore.set((prevState) => ({
    ...prevState,
    config
  }));
}
export function networkStoreReset() {
  networkStore.reset();
}
