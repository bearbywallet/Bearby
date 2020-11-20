/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import Keychain from 'react-native-keychain';
import { sha256, Encryptor, EncryptedType } from 'app/lib/crypto';
import { MobileStorage } from 'app/lib';
import { SecureKeychain } from './secure-keychain';

const _storage = new MobileStorage();
const chain = new SecureKeychain(_storage);

export class KeychainControler {
  private _secureKeychain: SecureKeychain;
  private _encryptor: Encryptor;

  constructor(storage: MobileStorage) {
    this._encryptor = new Encryptor();
    this._secureKeychain = new SecureKeychain(storage);
  }

  public get hasAccess() {
    return Boolean(this._secureKeychain.accessControl);
  }

  public async reset() {
    await this._secureKeychain.reset();
  }

  public async sync() {
    await this._secureKeychain.sync();
  }

  public async initKeychain(password: string, biometric: Keychain.ACCESS_CONTROL) {
    const hashSum = await sha256(password);

    await this._secureKeychain.setAccessControl(biometric);
    await this._secureKeychain.createKeychain(hashSum);
  }

  public async encryptVault(decrypted: string, password: string) {
    const hashSum = await sha256(password);
    const encrypted = await this._encryptor.encrypt(hashSum, decrypted);

    return encrypted;
  }

  public async decryptVault(encrypted: EncryptedType, password?: string) {
    let hashSum: string;

    if (!password) {
      hashSum = await this._secureKeychain.getGenericPassword();

      return this._encryptor.decrypt(hashSum, encrypted);
    }

    hashSum = await sha256(password);

    return this._encryptor.decrypt(hashSum, encrypted);
  }
}
