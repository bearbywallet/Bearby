/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { Encryptor, EncryptedType } from 'app/lib/crypto';
import DeviceInfo from 'react-native-device-info';
import Keychain from 'react-native-keychain';
import { MobileStorage, buildObject } from 'app/lib';
import { STORAGE_FIELDS } from 'app/config';
import {
  setAuthStoreAccessControl,
  setAuthStoreBiometricEnable,
  setAuthStoreSupportedBiometryType,
  authStore
} from './state';

import i18n from 'app/lib/i18n';

const _encryptor = new Encryptor();
const _options = {
  service: 'com.zilpay',
  accessible: Keychain.ACCESSIBLE.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
  securityLevel: Keychain.SECURITY_LEVEL.SECURE_HARDWARE,
  storage: Keychain.STORAGE_TYPE.RSA,
  authenticationPrompt: {
    title: i18n.t('biometric_promt_titie')
  }
};

export class SecureKeychain {
  private _storage: MobileStorage;

  constructor(storage: MobileStorage) {
    this._storage = storage;
  }

  /**
   * Reset all params.
   */
  public async reset() {
    await Keychain.resetGenericPassword();
    await this._storage.rm(STORAGE_FIELDS.ACCESS_CONTROL);
    setAuthStoreBiometricEnable(false);
  }

  /**
   * Sync with storage.
   */
  public async sync() {
    const supportedBiometryType = await this.getSupportedBiometryType();

    if (supportedBiometryType) {
      setAuthStoreSupportedBiometryType(supportedBiometryType);
    }

    const accessControl = await this._storage.get<string>(
      STORAGE_FIELDS.ACCESS_CONTROL
    ) as Keychain.ACCESS_CONTROL;

    if (typeof accessControl === 'string') {
      setAuthStoreAccessControl(accessControl);
      setAuthStoreBiometricEnable(true);
    }
  }

  /**
   * @retunrs once of {
   *  "FACE": "Face",
   *  "FACE_ID": "FaceID",
   *  "FINGERPRINT": "Fingerprint",
   *  "IRIS": "Iris",
   *  "TOUCH_ID": "TouchID"
   * }
   */
  public getSupportedBiometryType() {
    return Keychain.getSupportedBiometryType();
  }

  /**
   * Create encrypt session of wallet.
   * @param password - User password.
   */
  public async createKeychain(password: string) {
    const { accessControl } = authStore.getState();

    const name = DeviceInfo.getApplicationName();
    const encrypted = await this._encryptPassword(password);
    const jsonEncrypted = JSON.stringify(encrypted);
    const options = {
      ..._options,
      accessControl
    };

    await Keychain.setGenericPassword(name, jsonEncrypted, options);
    await this._storage.set(
      buildObject(STORAGE_FIELDS.ACCESS_CONTROL, String(accessControl))
    );

    setAuthStoreBiometricEnable(true);
  }

  /**
   * Get content from secure storage and decrypt it.
   */
  public async getGenericPassword() {
    const { accessControl } = authStore.getState();
    const options = {
      ..._options,
      accessControl
    };
    const credentials = await Keychain.getGenericPassword(options);

    if (!credentials || !credentials.password) {
      this.reset();

      // Rejcet isEnable

      throw new Error('Fail credentials');
    }

    const cipher = JSON.parse(credentials.password);
    const decrypted = await this._decryptPassword(cipher);

    return decrypted;
  }

  /**
   * Encrypt password via entropy.
   * @param password - User password.
   */
  private async _encryptPassword(password: string) {
    const name = DeviceInfo.getApplicationName();
    const encrypted = await _encryptor.encrypt(name, password);

    return encrypted;
  }

  /**
   * Decrypt password content.
   * @param encrypted - password cipher.
   * @retunrs - User password.
   */
  private async _decryptPassword(encrypted: EncryptedType) {
    const name = DeviceInfo.getApplicationName();
    const decrypted = await _encryptor.decrypt(name, encrypted);

    return decrypted;
  }
}
