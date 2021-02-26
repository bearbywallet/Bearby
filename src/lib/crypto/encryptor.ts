/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { NativeModules } from 'react-native';
import { sha256 } from './sha256';

const Aes = NativeModules.Aes;

export type EncryptedType = {
  iv: string;
  cipher: string;
};

/**
 * Class that exposes two public methods: Encrypt and Decrypt
 * This is used by the KeyringController to encrypt / decrypt the state
 * which contains sensitive seed words and addresses
 */
export class Encryptor {
  private _salt: string;

  constructor(salt = 'ZilPay') {
    this._salt = salt;
  }

  /**
   * Encrypts a string using a password (and AES encryption with native libraries).
   * @param password - Password used for decryption.
   * @param content - A content for encrypt.
   */
  public async encrypt(password: string, content: string): Promise<EncryptedType> {
    const key = await this._generateKey(
      password,
      this._salt,
      5000,
      256
    );
    const iv = await this._randomKey();
    const cipher = await Aes.encrypt(content, key, iv);

    return { iv, cipher };
  }

  /**
   * Decrypts an encrypted encryptedString.
   * using a password (and AES deccryption with native libraries)
   * @param encryptedData - encryptedString - String to decrypt.
   * @param password - Password used for decryption.
   */
  public async decrypt(password: string, encryptedData: EncryptedType): Promise<string> {
    const key = await this._generateKey(
      password,
      this._salt,
      5000,
      256
    );

    return Aes.decrypt(encryptedData.cipher, key, encryptedData.iv);
  }

  private _generateKey(password: string, salt: string, cost: number, length: number) {
    return Aes.pbkdf2(password, salt, cost, length);
  }

  private _randomKey() {
    return Aes.randomKey(16);
  }
}
