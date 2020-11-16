/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { NetworkControll } from 'app/lib/controller/network';

export class ZilliqaControl {
  private _network: NetworkControll;

  constructor(network: NetworkControll) {
    this._network = network;
  }
}
