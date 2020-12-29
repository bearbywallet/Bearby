/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { NativeModules } from 'react-native';
import { MNEMONIC_PACH } from 'app/config';
import { KeyPair } from 'types';

const { Crypto, CryptoModule } = NativeModules;

interface NativeKeyPair {
  private_key: string;
  public_key: string;
}

export class CryptoNativeModule {
  public createHDKeyPair: (mnemonic: string, passphrase: string, path: string, index: number) => Promise<NativeKeyPair>;
  public createHDKeyPairs: () => Promise<NativeKeyPair[]>;
  public generateMnemonic: (length: number) => Promise<string>;
  public mnemonicIsValid: (mnemonic: string) => Promise<string>;

  constructor() {
    if (Crypto) {
      this.createHDKeyPair = Crypto.createHDKeyPair;
      this.createHDKeyPairs = Crypto.createHDKeyPairs;
      this.generateMnemonic = Crypto.generateMnemonic;
      this.mnemonicIsValid = Crypto.mnemonicIsValid;
    } else if (CryptoModule) {
      this.createHDKeyPair = CryptoModule.createHDKeyPair;
      this.createHDKeyPairs = CryptoModule.createHDKeyPairs;
      this.generateMnemonic = CryptoModule.generateMnemonic;
      this.mnemonicIsValid = CryptoModule.mnemonicIsValid;
    } else {
      throw new Error('Incorect native modules');
    }
  }
}

/**
 * Mnemonic seed phrase contoller.
 */
export class Mnemonic {
  private _crypto = new CryptoNativeModule();

  /**
   * Check and validate the mnemonic seed phrase.
   * @param mnemonic - Mnemonic seed phrase.
   */
  public async validateMnemonic(mnemonic: string): Promise<boolean> {
    const checked = await this._crypto.mnemonicIsValid(mnemonic);

    return Number(checked) !== 0;
  }

  /**
   * Generate account keyPair private key and public key.
   * @param mnemonic - 12 or 24 mnemonic words.
   * @param index - Account index.
   * @example
   * import { Mnemonic } from 'lib/controller/mnemonic';
   * const mnemonicController = new Mnemonic();
   * const mnemonicPhrase = mnemonicController.generateMnemonic();
   * const pairs = mnemonicController.getKeyPair(mnemonicPhrase, 0);
   */
  public async getKeyPair(mnemonic: string, index: number = 0, passphrase = ''): Promise<KeyPair> {
    const { private_key, public_key } = await this._crypto.createHDKeyPair(
      mnemonic,
      passphrase,
      MNEMONIC_PACH,
      index
    );

    return {
      index,
      privateKey: private_key,
      publicKey: public_key
    };
  }

  /**
   * Generate mnemonic seed phrase.
   * @param len - a lenght of mnemonic seed in bytes.
   * @extends
   * new Mnemonic().generateMnemonic(128) => 12 words
   * new Mnemonic().generateMnemonic(256) => 24 words
   */
  public generateMnemonic(len: number = 128): Promise<string> {
    return this._crypto.generateMnemonic(len);
  }
}
