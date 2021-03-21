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
  isAddress,
  toChecksumAddress
} from 'app/utils';
import { toLi, fromLI, gasToFee } from 'app/filters';
import { networkStore } from 'app/lib/controller/network';
import { SchnorrControl } from 'app/lib/controller/elliptic';
import { DEFAULT_GAS } from 'app/config';

export enum TransactionMethods {
  Payment = 'Payment',
  Deploy = 'Deployed',
  Unexpected = 'Unexpected',
  Transfer = 'Transfer'
}

export enum TransactionTypes {
  Payment,
  triggered,
  Deploy
}

export interface ContractItemType {
  vname: string;
  type: string;
  value: string;
}

export class Transaction {

  public static fromPayload(payload: TxParams, account: Account, net: string) {
    const gasPrice = toLi(payload.gasPrice);
    const gas = {
      gasPrice: Number(gasPrice) < Number(DEFAULT_GAS.gasPrice) ? DEFAULT_GAS.gasPrice : gasPrice,
      gasLimit: payload.gasLimit
    };

    return new Transaction(
      payload.amount,
      gas,
      account,
      payload.toAddr,
      net,
      payload.nonce,
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
  public from: string;
  public net: string;
  public version?: number;
  public signature?: string;
  public hash?: string;
  public direction?: string;
  public timestamp?: number;

  constructor(
    amount: string,
    gas: GasState,
    account: Account,
    toAddr: string,
    net: string,
    nonce: number,
    code = '',
    data = '',
    priority = false,
    version?: number,
    signature?: string
  ) {
    isAddress(toAddr);

    this.from = account.bech32;
    this.amount = amount;
    this.code = code;
    this.data = data;
    this.gasLimit = Long.fromNumber(Number(gas.gasLimit));
    this.gasPrice = gas.gasPrice;
    this.priority = priority;
    this.pubKey = account.pubKey;
    this.toAddr = toChecksumAddress(toAddr);
    this.version = version;
    this.signature = signature;
    this.net = net;
    this.nonce = nonce;
  }

  public get transactionType() {
    if (this.code) {
      return TransactionTypes.Deploy;
    }

    if (this.data) {
      return TransactionTypes.triggered;
    }

    return TransactionTypes.Payment;
  }

  public get tag() {
    if (this.data && this.code) {
      return TransactionMethods.Deploy;
    }

    if (this.data) {
      const parsed = JSON.parse(this.data);

      return parsed._tag;
    }

    return TransactionMethods.Payment;
  }

  public get tokenAmount() {
    try {
      const parsed = JSON.parse(this.data);

      if (parsed._tag === TransactionMethods.Transfer) {
        const param = parsed.params.find(
          (el: ContractItemType) => el.vname === 'amount'
        );

        if (param.value) {
          return param.value;
        }
      }

      return this.amount;
    } catch {
      return this.amount;
    }
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

  public get feeValue(): string {
    const { fee } = gasToFee(String(this.gasLimit), this.gasPrice);

    return fee.toString();
  }

  public get self(): TxParams {
    return {
      amount: this.amount,
      code: this.code,
      data: this.data,
      gasLimit: this.gasLimit.toString(),
      gasPrice: fromLI(this.gasPrice),
      nonce: this.nonce,
      priority: this.priority,
      pubKey: this.pubKey,
      signature: this.signature,
      toAddr: this.toAddr,
      version: this.version,
      hash: this.hash
    };
  }

  public get serialize() {
    return JSON.stringify(this.self);
  }

  public setPriority(priority: boolean) {
    this.priority = priority;
  }

  public setNonce(nonce: number) {
    this.nonce = nonce;
  }

  public setVersion(chainId: number) {
    const { config, selected } = networkStore.get();
    const msg = config[selected].MSG_VERSION;

    this.version = pack(chainId, msg);

    return this.version;
  }

  public async sign(privKey: string) {
    const bytes = this._encodeTransactionProto();
    const schnorrControl = new SchnorrControl(privKey);

    this.signature = await schnorrControl.getSignature(bytes);
  }

  private _encodeTransactionProto() {
    const amount = new BN(this.amount);
    const gasPrice = new BN(fromLI(this.gasPrice));
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
}
