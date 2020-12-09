/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { sha256, Encryptor, EncryptedType } from 'app/lib/crypto';
import { MobileStorage } from 'app/lib';
import { SecureKeychain } from './secure-keychain';
import {
  authStore,
  authStoreReset
} from './state';

export class KeychainControler {
  public store = authStore;
  public secureKeychain: SecureKeychain;
  private _encryptor: Encryptor;

  constructor(storage: MobileStorage) {
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

  public async initKeychain(password: string) {
    const hashSum = await sha256(password);

    await this.secureKeychain.createKeychain(hashSum);
  }

  public async encryptVault(decrypted: string, password?: string) {
    let hashSum: string;

    if (!password) {
      hashSum = await this.secureKeychain.getGenericPassword();

      return this._encryptor.encrypt(hashSum, decrypted);
    }

    hashSum = await sha256(password);

    return this._encryptor.encrypt(hashSum, decrypted);
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
