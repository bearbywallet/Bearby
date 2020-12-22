/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { NativeModules } from 'react-native';

const Aes = NativeModules.Aes;

/**
 * Method for get hashsum from content.
 * @param content - Some string for hasing.
 */
export function sha256(content: string): Promise<string> {
  return Aes.sha256(content);
}
