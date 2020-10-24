/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { NativeModules } from 'react-native';

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

    return Number(checked) !== 0;
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
