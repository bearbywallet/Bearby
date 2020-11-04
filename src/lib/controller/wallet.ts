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

const _storage = new MobileStorage();

export class WalletControler extends Mnemonic {
  public guard = new GuardControler(_storage);
  public network = new NetworkControll(_storage);
  public account = new AccountControler(_storage);
  public zilliqa = new ZilliqaControl(this.network);
  public token = new TokenControll(this.zilliqa, _storage, this.network);

  public async initWallet(password: string, mnemonic: string) {
    await this.network.sync();
    await this.guard.setupWallet(password, mnemonic);
    const keyPairs = await this.getKeyPair(mnemonic);
    const account = this.account.fromKeyPairs(
      keyPairs,
      AccountTypes.Seed
    );
    await this.account.reset();
    await this.account.add(account);
  }

  public unlockWallet(password: string) {
    return this.guard.unlock(password);
  }

  public async sync() {
    await this.network.sync();
    await this.guard.sync();
  }
}
