/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { GuardControler } from './guard';
import { MobileStorage } from '../storage';
import { Mnemonic } from './mnemonic';
import { ZilliqaControl } from './zilliqa';
import { NetworkControll } from './network';

export class WalletControler extends Mnemonic {
  private _storage = new MobileStorage();
  private _guard = new GuardControler(this._storage);
  private _zilliqa = new ZilliqaControl();
  private _network = new NetworkControll(this._storage);

  public async initWallet(password: string, mnemonic: string) {
    await this._network.sync();
    await this._guard.setupWallet(password, mnemonic);
  }

  public unlockWallet(password: string) {
    return this._guard.unlock(password);
  }
}
