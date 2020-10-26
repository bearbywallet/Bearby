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
import { AccountControler } from './account';
import { TokenControll } from './tokens';

import { AccountTypes } from '../../config';

export class WalletControler extends Mnemonic {
  private _storage = new MobileStorage();
  private _guard = new GuardControler(this._storage);
  private _network = new NetworkControll(this._storage);
  private _account = new AccountControler(this._storage);
  private _zilliqa = new ZilliqaControl(this._network);
  private _token = new TokenControll(this._zilliqa, this._storage, this._network);

  public async initWallet(password: string, mnemonic: string) {
    await this._network.sync();
    await this._guard.setupWallet(password, mnemonic);
    const keyPairs = await this.getKeyPair(mnemonic);
    const account = this._account.fromKeyPairs(
      keyPairs,
      AccountTypes.Seed
    );
    await this._account.reset();
    await this._account.add(account);
  }

  public unlockWallet(password: string) {
    return this._guard.unlock(password);
  }
}
