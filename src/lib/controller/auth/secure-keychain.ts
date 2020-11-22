/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { sha256, Encryptor, EncryptedType } from 'app/lib/crypto';
import DeviceInfo from 'react-native-device-info';
import Keychain from 'react-native-keychain';
import { MobileStorage, buildObject } from 'app/lib';
import { STORAGE_FIELDS } from 'app/config';

const _encryptor = new Encryptor();
const _options = {
  service: 'com.zilpay',
  accessible: Keychain.ACCESSIBLE.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
  securityLevel: Keychain.SECURITY_LEVEL.SECURE_HARDWARE,
  storage: Keychain.STORAGE_TYPE.RSA,
  authenticationPrompt: {
    title: 'Authentication needed',
    subtitle: 'Subtitle',
    description: 'Some descriptive text',
    cancel: 'Cancel',
  }
};

export class SecureKeychain {
  /**
   * All variants of access to storage.
   */
  public static readonly ACCESS_CONTROLS = Keychain.ACCESS_CONTROL;
  public static readonly BIOMETRY_TYPES = Keychain.BIOMETRY_TYPE;

  /**
   * Selected by user for example `TouchID`.
   */
  public accessControl: Keychain.ACCESS_CONTROL | undefined;
  /**
   * Support of phone some Biometry.
   */
  public supportedBiometryType: Keychain.BIOMETRY_TYPE | null = null;

  public biometricEnable = false;

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
    this.biometricEnable = false;
  }

  /**
   * Sync with storage.
   */
  public async sync() {
    this.supportedBiometryType = await this.getSupportedBiometryType();

    const accessControl = await this._storage.get<string>(
      STORAGE_FIELDS.ACCESS_CONTROL
    );

    if (!accessControl) {
      this.accessControl = await this.getAccessControl();
    }

    if (typeof accessControl === 'string') {
      this.accessControl = accessControl as Keychain.ACCESS_CONTROL;
      this.biometricEnable = true;
    }
  }

  public async getAccessControl() {
    this.supportedBiometryType = await this.getSupportedBiometryType();

    if (this.supportedBiometryType === Keychain.BIOMETRY_TYPE.TOUCH_ID) {
      return Keychain.ACCESS_CONTROL.BIOMETRY_CURRENT_SET;
    } else if (this.supportedBiometryType === Keychain.BIOMETRY_TYPE.FINGERPRINT) {
      return Keychain.ACCESS_CONTROL.BIOMETRY_CURRENT_SET;
    } else if (this.supportedBiometryType === Keychain.BIOMETRY_TYPE.FACE_ID) {
      return Keychain.ACCESS_CONTROL.BIOMETRY_CURRENT_SET;
    } else if (this.supportedBiometryType === Keychain.BIOMETRY_TYPE.FACE) {
      return Keychain.ACCESS_CONTROL.BIOMETRY_CURRENT_SET;
    }

    return Keychain.ACCESS_CONTROL.DEVICE_PASSCODE;
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
    await this._storage.set(
      buildObject(STORAGE_FIELDS.ACCESS_CONTROL, String(this.accessControl))
    );

    const name = DeviceInfo.getApplicationName();
    const encrypted = await this._encryptPassword(password);
    const jsonEncrypted = JSON.stringify(encrypted);
    const options = {
      ..._options,
      accessControl: this.accessControl
    };

    await Keychain.setGenericPassword(name, jsonEncrypted, options);
  }

  /**
   * Get content from secure storage and decrypt it.
   */
  public async getGenericPassword() {
    const options = {
      ..._options,
      accessControl: this.accessControl
    };
    const credentials = await Keychain.getGenericPassword(options);

    if (!credentials || !credentials.password) {
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
