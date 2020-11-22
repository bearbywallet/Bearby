/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { GuardControler } from 'app/lib/controller/guard';
import { MobileStorage } from 'app/lib/storage';
import { Mnemonic } from 'app/lib/controller/mnemonic';
import { ZilliqaControl } from 'app/lib/controller/zilliqa';
import { NetworkControll } from 'app/lib/controller/network';
import { AccountControler } from 'app/lib/controller/account';
import { TokenControll } from 'app/lib/controller/tokens';
import { CurrencyControler } from 'app/lib/controller/currency';
import { ThemeControler } from 'app/lib/controller/theme';
import { ContactsControler } from 'app/lib/controller/contacts';
import { SettingsControler } from 'app/lib/controller/settings';
import { GasControler } from 'app/lib/controller/gas';

import { AccountTypes } from 'app/config';

const _storage = new MobileStorage();

export class WalletControler extends Mnemonic {
  public readonly guard = new GuardControler(_storage);
  public readonly network = new NetworkControll(_storage);
  public readonly account = new AccountControler(_storage);
  public readonly currency = new CurrencyControler(_storage);
  public readonly theme = new ThemeControler(_storage);
  public readonly settings = new SettingsControler(_storage);
  public readonly contacts = new ContactsControler(_storage);
  public readonly gas = new GasControler(_storage);
  public readonly zilliqa = new ZilliqaControl(this.network);
  public readonly token = new TokenControll(this.zilliqa, _storage, this.network);

  public async initWallet(password: string, mnemonic: string) {
    await this.network.sync();
    await this.guard.setupWallet(password, mnemonic);
  }

  public async addAccount(mnemonic: string, name: string) {
    const keyPairs = await this.getKeyPair(mnemonic);
    const account = this.account.fromKeyPairs(
      keyPairs,
      AccountTypes.Seed,
      name
    );

    return this.account.add(account);
  }

  public async sync() {
    await this.theme.sync();
    await this.guard.sync();
    await this.network.sync();
    await this.account.sync();
    await this.settings.sync();
    await this.currency.sync();
    await this.contacts.sync();
    await this.gas.sync();
  }
}
