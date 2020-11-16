/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { sha256, Encryptor, EncryptedType } from 'app/lib/crypto';

export interface Auth {
  getEncrypted: () => EncryptedType;
  setPassword: (password: string) => Promise<void>;
  encryptVault: (decrypted: string) => Promise<EncryptedType>;
  decryptVault: () => Promise<string>;
}

export async function AuthControler(password?: string, encryptedContent?: EncryptedType): Promise<Auth> {
  const encryptor = new Encryptor();
  let _hashSum = password ? await sha256(password) : null;
  let _encrypted = encryptedContent;
  const checkPassword = () => {
    if (!_hashSum) {
      throw new Error('password isnot initialized');
    }
  };

  return {
    getEncrypted() {
      if (!_encrypted) {
        throw new Error('encrypted has not initialized');
      }

      return _encrypted;
    },
    async setPassword(_password: string) {
      _hashSum = await sha256(_password);
    },
    async encryptVault(decrypted: string) {
      checkPassword();

      _encrypted = await encryptor.encrypt(_hashSum, decrypted);

      return _encrypted;
    },
    decryptVault() {
      checkPassword();

      if (!_encrypted) {
        throw new Error('encrypted has not initialized');
      }

      return encryptor.decrypt(_hashSum, _encrypted);
    }
  };
}
