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
export const setAuthStoreBiometricEnable = createEvent<boolean>();
export const setAuthStoreSupportedBiometryType = createEvent<Keychain.BIOMETRY_TYPE>();
export const authStoreReset = createEvent();

const AuthDomain = createDomain();
const initalState: AuthState = {
  accessControl: Keychain.ACCESS_CONTROL.BIOMETRY_ANY_OR_DEVICE_PASSCODE,
  biometricEnable: false,
  supportedBiometryType: null
};
export const authStore = AuthDomain
  .store<AuthState>(initalState)
  .on(authStoreUpdate, (_, payload) => payload)
  .on(setAuthStoreAccessControl, (state, accessControl) => ({
    ...state,
    accessControl
  }))
  .on(setAuthStoreBiometricEnable, (state, biometricEnable) => ({
    ...state,
    biometricEnable
  }))
  .on(setAuthStoreSupportedBiometryType, (state, supportedBiometryType) => ({
    ...state,
    supportedBiometryType
  }))
  .reset(authStoreReset);
