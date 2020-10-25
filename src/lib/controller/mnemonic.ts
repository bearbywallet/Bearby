/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { NativeModules } from 'react-native';
import { MNEMONIC_PACH } from '../../config';
// import { getAddressFromPublicKey } from '../../utils';

const { Crypto } = NativeModules;

/**
 * Mnemonic seed phrase contoller.
 */
export class Mnemonic {
  /**
   * Check and validate the mnemonic seed phrase.
   * @param mnemonic - Mnemonic seed phrase.
   */
  public async validateMnemonic(mnemonic: string): Promise<boolean> {
    const checked = await Crypto.mnemonicIsValid(mnemonic);
    // const { publicKey } = await this.getKeyPair(mnemonic);
    // const address = await getAddressFromPublicKey(publicKey);

    // console.log(mnemonic)
    // console.log(publicKey)
    // console.log(address)

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
  public async getKeyPair(mnemonic: string, index: number = 0, passphrase = '') {
    const { private_key, public_key } = await Crypto.createHDKeyPair(
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
    return Crypto.generateMnemonic(len);
  }
}
