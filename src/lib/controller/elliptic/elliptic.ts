/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { eddsa } from 'elliptic';

export class SchnorrControl {
  private _ed25519 = new eddsa('ed25519');
  private _key: eddsa.KeyPair;

  constructor(privateKey: string) {
    this._key = this._ed25519.keyFromSecret(privateKey);
  }

  public sign(msg: string) {
    return this._key.sign(msg).toHex();
  }
}
