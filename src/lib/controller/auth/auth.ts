/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { sha256, Encryptor, EncryptedType } from 'app/lib/crypto';
import { MobileStorage, buildObject } from 'app/lib';
import { STORAGE_FIELDS } from 'app/config';
import { SecureKeychain } from './secure-keychain';
import {
  authStore,
  setAuthStoreBiometricEnable,
  authStoreReset
} from './state';

export class KeychainControler {
  public store = authStore;
  public secureKeychain: SecureKeychain;
  private _storage: MobileStorage;
  private _encryptor: Encryptor;

  constructor(storage: MobileStorage) {
    this._storage = storage;
    this._encryptor = new Encryptor();
    this.secureKeychain = new SecureKeychain(storage);
  }

  public async reset() {
    authStoreReset();
    await this.secureKeychain.reset();
  }

  public async sync() {
    await this.secureKeychain.sync();
  }

  public async updateBiometric(value: boolean) {
    if (value) {
      const { accessControl } = authStore.getState();

      await this._storage.set(
        buildObject(STORAGE_FIELDS.ACCESS_CONTROL, String(accessControl))
      );

      setAuthStoreBiometricEnable(value);

      return value;
    }

    await this.reset();

    return value;
  }

  public async initKeychain(password: string) {
    const hashSum = await sha256(password);

    await this.secureKeychain.createKeychain(hashSum);
  }

  public async encryptVault(decrypted: string, password: string) {
    const hashSum = await sha256(password);
    const encrypted = await this._encryptor.encrypt(hashSum, decrypted);

    return encrypted;
  }

  public async decryptVault(encrypted: EncryptedType, password?: string) {
    let hashSum: string;

    if (!password) {
      hashSum = await this.secureKeychain.getGenericPassword();

      return this._encryptor.decrypt(hashSum, encrypted);
    }

    hashSum = await sha256(password);

    return this._encryptor.decrypt(hashSum, encrypted);
  }
}
