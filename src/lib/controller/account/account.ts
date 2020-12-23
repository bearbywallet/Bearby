/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { MobileStorage, buildObject } from 'app/lib/storage';
import {
  STORAGE_FIELDS,
  AccountTypes,
  ZILLIQA_KEYS,
  NONCE_DIFFICULTY
} from 'app/config';
import {
  getAddressFromPublicKey,
  toBech32Address,
  deppUnlink,
  getPubKeyFromPrivateKey
} from 'app/utils';
import {
  accountStore,
  accountStoreReset,
  accountStoreUpdate,
  accountStoreSelect
} from './sate';
import { AccountState, Account, KeyPair } from 'types';
import { TokenControll } from 'app/lib/controller/tokens';
import { ZilliqaControl } from 'app/lib/controller/zilliqa';
import { NetworkControll } from 'app/lib/controller/network';
import { ViewBlockControler } from 'app/lib/controller/viewblock';

export class AccountControler {
  public store = accountStore;
  private _storage: MobileStorage;
  private _token: TokenControll;
  private _zilliqa: ZilliqaControl;
  private _netwrok: NetworkControll;
  private _viewblock: ViewBlockControler;

  constructor(
    storage: MobileStorage,
    token: TokenControll,
    zilliqa: ZilliqaControl,
    netwrok: NetworkControll,
    viewblock: ViewBlockControler
  ) {
    this._storage = storage;
    this._token = token;
    this._zilliqa = zilliqa;
    this._netwrok = netwrok;
    this._viewblock = viewblock;
  }

  public get lastIndexPrivKey() {
    return this
      .store
      .get()
      .identities
      .filter((acc) => acc.type === AccountTypes.privateKey)
      .length;
  }

  public get lastIndexSeed() {
    return this
      .store
      .get()
      .identities
      .filter((acc) => acc.type === AccountTypes.Seed)
      .length;
  }

  public get lastIndexLedger() {
    return this
      .store
      .get()
      .identities
      .filter((acc) => acc.type === AccountTypes.Ledger)
      .length;
  }

  public async sync(): Promise<AccountState> {
    try {
      const accounts = await this._storage.get<string>(
        STORAGE_FIELDS.ACCOUNTS
      );

      if (typeof accounts === 'string') {
        const parsed = JSON.parse(accounts);

        accountStoreUpdate(parsed);
      }
    } catch (err) {
      console.error('lib/accounts/sync', err);
      //
    }

    return this.store.get();
  }

  public async fromKeyPairs(acc: KeyPair, type: AccountTypes, name = ''): Promise<Account> {
    const pubKey = acc.publicKey;
    const base16 = getAddressFromPublicKey(pubKey);
    const bech32 = toBech32Address(base16);
    const balance = await this._tokenBalance(base16);

    return {
      base16,
      bech32,
      name,
      type,
      pubKey,
      balance,
      index: Number(acc.index),
      nonce: 0 // TODO: check and update nonce.
    };
  }

  public getCurrentAccount() {
    const { identities, selectedAddress } = this.store.get();

    return identities[selectedAddress];
  }

  public reset() {
    accountStoreReset();

    return this.update(this.store.get());
  }

  public async removeAccount(account: Account) {
    const state = deppUnlink<AccountState>(this.store.get());

    state.identities = state.identities.filter(
      (acc) => account.base16 !== acc.base16
    );
    state.selectedAddress = state.identities.length - 1;

    await this.update(state);
  }

  public update(accountState: AccountState): Promise<void> {
    accountStoreUpdate(accountState);

    return this._storage.set(
      buildObject(STORAGE_FIELDS.ACCOUNTS, accountState)
    );
  }

  public async add(account: Account) {
    const accounts = await this._checkAccount(account);

    accounts
      .identities
      .push(account);
    accounts
      .selectedAddress = accounts.identities.length - 1;

    await this.update(accounts);

    return accounts;
  }

  public async fromPrivateKey(privatekey: string, name: string): Promise<Account> {
    const pubKey = getPubKeyFromPrivateKey(privatekey);
    const type = AccountTypes.privateKey;
    const base16 = getAddressFromPublicKey(pubKey);
    const bech32 = toBech32Address(base16);
    const balance = await this._tokenBalance(base16);
    const index = this.lastIndexPrivKey;

    return {
      base16,
      bech32,
      name,
      pubKey,
      type,
      balance,
      index,
      nonce: 0 // TODO: check and update nonce.
    };
  }

  public async selectAccount(index: number) {
    const { identities } = this.store.get();

    if (identities.length < index) {
      return null;
    }

    accountStoreSelect(index);

    await this.update(this.store.get());
  }

  public async updateNonce() {
    const state = this.store.get();
    const account = state.identities[state.selectedAddress];
    const { nonce } = await this._zilliqa.getBalance(account.base16);

    if (nonce < account.nonce && NONCE_DIFFICULTY < nonce - account.nonce) {
      throw new Error('nonce too hight');
    }

    if (nonce === account.nonce) {
      return null;
    }

    if (nonce > account.nonce) {
      state.identities[state.selectedAddress].nonce = nonce;
    }

    await this.update(state);
  }

  public async increaseNonce() {
    const state = this.store.get();

    state.identities[state.selectedAddress].nonce++;

    await this.update(state);
  }

  public async balanceUpdate() {
    const accounts = this.store.get();
    const account = accounts.identities[accounts.selectedAddress];

    account.balance = await this._tokenBalance(account.base16);

    await this.update(deppUnlink(accounts));
  }

  private async _checkAccount(account: Account) {
    const accounts = await this.sync();
    const isUnique = accounts.identities.some(
      (acc) => (acc.base16 === account.base16)
    );
    const isIndex = accounts.identities.some(
      (acc) => (acc.index === account.index) && (acc.type === account.type)
    );

    if (isUnique) {
      throw new Error('Account must be unique');
    } else if (isIndex) {
      throw new Error('Incorect index and account type');
    }

    return accounts;
  }

  private async _tokenBalance(base16: string) {
    const net = this._netwrok.selected;
    const tokens = this._token.store.get().map((t) => [t.symbol, '0']);
    const entries = ZILLIQA_KEYS.map((n) => [n, Object.fromEntries(tokens)]);
    const balances = Object.fromEntries(entries);

    for (const t of this._token.store.get()) {
      balances[net][t.symbol] = await this._zilliqa.handleBalance(base16, t);
    }

    return balances;
  }
}
