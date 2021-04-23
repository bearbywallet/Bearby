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
import { TransactionsQueue } from 'app/lib/controller/transaction';
import { SearchController } from 'app/lib/controller/search-engine';
import { UnstoppableDomains } from 'app/lib/controller/unstoppabledomains';
import { InjectScript } from 'app/lib/controller';
import { ConnectController } from 'app/lib/controller/connect';
import { SSnController } from 'app/lib/controller/ssn';
import { WorkerController } from 'app/lib/controller/worker';
import { NotificationManager } from 'app/lib/controller/notification';
import { AppsController } from 'app/lib/controller/apps';
import { IPFS } from 'app/lib/controller/ipfs';

import { AccountTypes } from 'app/config';
import { Account } from 'types';
import { isPrivateKey } from 'app/utils';

const _storage = new MobileStorage();

export class WalletControler extends Mnemonic {
  public readonly ud = new UnstoppableDomains(_storage);
  public readonly app = new AppsController(_storage);
  public readonly guard = new GuardControler(_storage);
  public readonly network = new NetworkControll(_storage);
  public readonly notificationManager = new NotificationManager(_storage, this.network);
  public readonly currency = new CurrencyControler(_storage);
  public readonly theme = new ThemeControler(_storage);
  public readonly contacts = new ContactsControler(_storage);
  public readonly zilliqa = new ZilliqaControl(this.network);
  public readonly gas = new GasControler(_storage, this.zilliqa);
  public readonly ipfs = new IPFS(_storage);
  public readonly searchEngine = new SearchController(_storage, this.ud);
  public readonly token = new TokenControll(this.zilliqa, _storage, this.network);
  public readonly ssn = new SSnController(_storage, this.zilliqa, this.network);
  public readonly settings = new SettingsControler(
    _storage,
    this.zilliqa,
    this.token,
    this.network
  );
  public readonly account = new AccountControler(
    _storage,
    this.token,
    this.zilliqa,
    this.network
  );
  public readonly transaction = new TransactionsQueue(
    this.zilliqa,
    _storage,
    this.notificationManager
  );
  public readonly inpage = new InjectScript(this.account, this.network);
  public readonly connect = new ConnectController(_storage);
  public readonly worker = new WorkerController(
    this.transaction,
    this.account,
    this.zilliqa,
    _storage,
    this.app
  );

  public async initWallet(password: string, mnemonic: string) {
    await this.network.sync();
    await this.guard.setupWallet(password, mnemonic);
  }

  public async addAccount(mnemonic: string, name: string, index?: number) {
    const keyPairs = await this.getKeyPair(mnemonic, index);
    const account = await this.account.fromKeyPairs(
      keyPairs,
      AccountTypes.Seed,
      name
    );

    return this.account.add(account);
  }

  public async addNextAccount(name: string, password?: string) {
    const { identities } = this.account.store.get();
    const nextIndex = identities.filter(
      (acc) => acc.type === AccountTypes.Seed
    ).length;
    const mnemonic = await this.guard.getMnemonic(password);
    const keyPairs = await this.getKeyPair(mnemonic, nextIndex);

    const account = await this.account.fromKeyPairs(
      keyPairs,
      AccountTypes.Seed,
      name
    );

    await this.account.add(account);

    return account;
  }

  public async addPrivateKeyAccount(privatekey: string, name: string, password?: string) {
    isPrivateKey(privatekey);
    const { identities } = this.account.store.get();
    const nextIndex = identities.filter(
      (acc) => acc.type === AccountTypes.privateKey
    ).length;
    const account = await this.account.fromPrivateKey(privatekey, name);
    const encryptedPrivateKey = await this.guard.auth.encryptVault(
      privatekey, password
    );

    account.index = nextIndex;
    account.privKey = JSON.stringify(encryptedPrivateKey);

    await this.account.add(account);
  }

  public async getkeyPairs(account: Account, password?: string) {
    // Getting account by seed phrase.
    if (account.type === AccountTypes.Seed) {
      const mnemonic = await this.guard.getMnemonic(password);
      const keyPairs = await this.getKeyPair(mnemonic, account.index);

      return keyPairs;
    }

    // Getting account from chiper privateKey
    if (account.privKey && account.type === AccountTypes.privateKey) {
      const { index, pubKey } = account;
      const encrypted = JSON.parse(account.privKey);
      const privateKey = await this.guard.auth.decryptVault(encrypted, password);

      return {
        index,
        privateKey,
        publicKey: pubKey
      };
    }

    throw new Error('Incorect account type');
  }

  public async sync() {
    await this.theme.sync();
    await this.guard.sync();
    await this.network.sync();
    await this.account.sync();
    await this.token.sync();
    await this.settings.sync();
    await this.currency.sync();
    await this.contacts.sync();
    await this.gas.sync();
    await this.searchEngine.sync();
    await this.connect.sync();
    await this.inpage.sync();
    await this.ssn.sync();
    await this.notificationManager.sync();
    await this.transaction.sync();
    await this.ipfs.sync();
    this.worker.start();
  }
}
