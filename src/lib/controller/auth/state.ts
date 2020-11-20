/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { createDomain, createEvent } from 'effector';
import Keychain from 'react-native-keychain';
import { AuthState } from 'types';

export const authStoreUpdate = createEvent<AuthState>();
export const setAuthStoreAccessControl = createEvent<Keychain.ACCESS_CONTROL>();
export const authStoreReset = createEvent();

const AuthDomain = createDomain();
const initalState: AuthState = {
};
export const authStore = AuthDomain
  .store<AuthState>(initalState)
  .on(authStoreUpdate, (_, payload) => payload)
  .reset(authStoreReset);
