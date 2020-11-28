/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import Keychain from 'react-native-keychain';
import { newRidgeState } from 'react-ridge-state';
import { AuthState } from 'types';

const initalState: AuthState = {
  accessControl: Keychain.ACCESS_CONTROL.BIOMETRY_ANY_OR_DEVICE_PASSCODE,
  biometricEnable: false,
  supportedBiometryType: null
};
export const authStore = newRidgeState<AuthState>(initalState);

export function authStoreUpdate(payload: AuthState) {
  authStore.set(() => payload);
}
export function setAuthStoreAccessControl(accessControl: Keychain.ACCESS_CONTROL) {
  authStore.set((prevState) => ({
    ...prevState,
    accessControl
  }));
}
export function setAuthStoreBiometricEnable(biometricEnable: boolean) {
  authStore.set((prevState) => ({
    ...prevState,
    biometricEnable
  }));
}
export function setAuthStoreSupportedBiometryType(
  supportedBiometryType: Keychain.BIOMETRY_TYPE
) {
  authStore.set((prevState) => ({
    ...prevState,
    supportedBiometryType
  }));
}
export function authStoreReset() {
  authStore.reset();
}
