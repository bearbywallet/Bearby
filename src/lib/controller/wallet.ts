/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { GuardControler } from './guard';
import { Mnemonic } from './mnemonic';

export class WalletControler extends Mnemonic {
  private _guard = new GuardControler();

  public initWallet(password: string, mnemonic: string) {
    return this._guard.setupWallet(password, mnemonic);
  }

  public unlockWallet(password: string) {
    return this._guard.unlock(password);
  }
}
