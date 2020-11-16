/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { makeObservable, observable, computed } from 'mobx';
import { Account } from 'types';

export class AccountsStore {
  @observable
  public identities: Account[] = [];

  @observable
  public selectedAddress = 0;

  constructor() {
      makeObservable(this);
  }

  @computed
  get account() {
    return this.identities[this.selectedAddress];
  }
}
