/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { GasState, Account } from 'types';

import { tohexString, pack } from 'app/utils';
import { networkStore } from 'app/lib/controller/network';
import { SchnorrControl } from 'app/lib/controller/elliptic';

export class Transaction {
  public amount: string;
  public code: string;
  public data: string;
  public gasLimit: string;
  public gasPrice: string;
  public nonce: number;
  public priority: boolean;
  public pubKey: string;
  public toAddr: string;
  public version?: number;
  public signature?: string;

  constructor(
    amount: string,
    gas: GasState,
    account: Account,
    toAddr: string,
    code = '',
    data = '',
    priority = false,
    version?: number,
    signature?: string
  ) {
    this.amount = amount;
    this.code = code;
    this.data = data;
    this.gasLimit = gas.gasLimit;
    this.gasPrice = gas.gasPrice;
    this.nonce = account.nonce;
    this.priority = priority;
    this.pubKey = account.pubKey;
    this.toAddr = tohexString(toAddr);
    this.version = version;
    this.signature = signature;
  }

  public setVersion(chainId: number) {
    const { config, selected } = networkStore.get();
    const msg = config[selected].MSG_VERSION;

    this.version = pack(chainId, msg);

    return this.version;
  }
}
