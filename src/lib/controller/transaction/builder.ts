/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { GasState, Account, TxParams } from 'types';
import { ZilliqaMessage } from '@zilliqa-js/proto';
import BN from 'bn.js';
import Long from 'long';

import {
  tohexString,
  pack,
  hexToByteArray,
  toBech32Address,
  isAddress
} from 'app/utils';
import { networkStore } from 'app/lib/controller/network';
import { SchnorrControl } from 'app/lib/controller/elliptic';

export class Transaction {

  public static fromPayload(payload: TxParams, account: Account) {
    const gas = {
      gasPrice: payload.gasPrice,
      gasLimit: payload.gasLimit
    };
    return new Transaction(
      payload.amount,
      gas,
      account,
      payload.toAddr,
      payload.code,
      payload.data,
      payload.priority
    );
  }

  public amount: string;
  public code: string;
  public data: string;
  public gasLimit: Long;
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
    isAddress(toAddr);

    this.amount = amount;
    this.code = code;
    this.data = data;
    this.gasLimit = Long.fromNumber(Number(gas.gasLimit));
    this.gasPrice = gas.gasPrice;
    this.nonce = account.nonce;
    this.priority = priority;
    this.pubKey = account.pubKey;
    this.toAddr = tohexString(toAddr);
    this.version = version;
    this.signature = signature;
  }

  public get recipient() {
    return toBech32Address(this.toAddr);
  }

  public get fee(): GasState {
    return {
      gasPrice: String(this.gasPrice),
      gasLimit: String(this.gasLimit)
    };
  }

  public setPriority(priority: boolean) {
    this.priority = priority;
  }

  public encodeTransactionProto() {
    const amount = new BN(this.amount);
    const gasPrice = new BN(this.gasPrice);
    const msg = {
      version: this.version || 0,
      nonce: this.nonce || 0,
      // core protocol Schnorr expects lowercase, non-prefixed address.
      toaddr: hexToByteArray(tohexString(this.toAddr)),
      senderpubkey: ZilliqaMessage.ByteArray.create({
        data: hexToByteArray(this.pubKey || '00'),
      }),
      amount: ZilliqaMessage.ByteArray.create({
        data: Uint8Array.from(amount.toArrayLike(Buffer, undefined, 16)),
      }),
      gasprice: ZilliqaMessage.ByteArray.create({
        data: Uint8Array.from(gasPrice.toArrayLike(Buffer, undefined, 16)),
      }),
      gaslimit: this.gasLimit,
      code:
        this.code && this.code.length
          ? Uint8Array.from([...this.code].map((c) => c.charCodeAt(0)))
          : null,
      data:
        this.data && this.data.length
          ? Uint8Array.from([...this.data].map((c) => c.charCodeAt(0)))
          : null
    };
    const serialised = ZilliqaMessage.ProtoTransactionCoreInfo.create(msg);

    return Buffer.from(
      ZilliqaMessage.ProtoTransactionCoreInfo.encode(serialised).finish()
    );
  }

  public setVersion(chainId: number) {
    const { config, selected } = networkStore.get();
    const msg = config[selected].MSG_VERSION;

    this.version = pack(chainId, msg);

    return this.version;
  }
}
