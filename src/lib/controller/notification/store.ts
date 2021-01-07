/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { newRidgeState } from 'react-ridge-state';
import { NotificationState } from 'types';

const initalState: NotificationState = {
  enabled: true
};
export const notificationStore = newRidgeState<NotificationState>(initalState);

export function notificationStoreUpdate(state: NotificationState) {
  notificationStore.set(() => state);
}
export function notificationStoreReset() {
  notificationStore.reset();
}
