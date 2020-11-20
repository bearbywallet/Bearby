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

const _private = new WeakMap();
const _encryptor = new Encryptor();
const _options = {
  service: 'com.zilpay',
  accessible: Keychain.ACCESSIBLE.WHEN_UNLOCKED_THIS_DEVICE_ONLY
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

  private _storage: MobileStorage;

  constructor(storage: MobileStorage) {
    this._storage = storage;
  }

  /**
   * Reset all params.
   */
  public async reset() {
    await this._storage.rm(STORAGE_FIELDS.BIOMETRY_CHOSEN);
    await Keychain.resetGenericPassword(_options);
    this.accessControl = undefined;
  }

  /**
   * Sync with storage.
   */
  async sync() {
    this.supportedBiometryType = await this.getSupportedBiometryType();

    let biometryType = await this._storage.get<string>(
      STORAGE_FIELDS.BIOMETRY_CHOSEN
    );

    if (typeof biometryType === 'string') {
      this.accessControl = biometryType as Keychain.ACCESS_CONTROL;
    }
  }

  public async setAccessControl(value: Keychain.ACCESS_CONTROL) {
    this.accessControl = value;

    await this._storage.set(
      buildObject(STORAGE_FIELDS.BIOMETRY_CHOSEN, value)
    );
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
    if (!this.accessControl) {
      throw new Error('Need accessControl');
    }

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
   * Create some sha256 hashSum from some device and app params.
   */
  private async _entropy() {
    const name = DeviceInfo.getApplicationName();
    const buildNumber = DeviceInfo.getApplicationName();
    const id = DeviceInfo.getUniqueId();
    const buildID = await DeviceInfo.getBuildId();
    const fingerPrint = await DeviceInfo.getFingerprint();
    const ipAddress = await DeviceInfo.getIpAddress();
  
    return sha256(name + buildNumber + id + buildID + fingerPrint + ipAddress);
  }

  /**
   * Encrypt password via entropy.
   * @param password - User password.
   */
  private async _encryptPassword(password: string) {
    const salt = await this._entropy();
    const encrypted = await _encryptor.encrypt(salt, password);

    return encrypted;
  }

  /**
   * Decrypt password content.
   * @param encrypted - password cipher.
   * @retunrs - User password.
   */
  private async _decryptPassword(encrypted: EncryptedType) {
    const salt = await this._entropy();
    const decrypted = await _encryptor.decrypt(salt, encrypted);

    return decrypted;
  }
}
