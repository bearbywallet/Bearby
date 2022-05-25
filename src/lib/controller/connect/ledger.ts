import TransportBLE from '@ledgerhq/react-native-hw-transport-ble';
import { Transaction } from 'app/lib/controller/transaction';
import { NativeTransport } from 'types';

const CLA = 0xe0;
const INS = {
    getVersion: 0x01,
    getPublickKey: 0x02,
    getPublicAddress: 0x02,
    signTxn: 0x04,
    signHash: 0x08
};

const PubKeyByteLen = 33;
const SigByteLen = 64;
const HashByteLen = 32;
// https://github.com/Zilliqa/Zilliqa/wiki/Address-Standard#specification
const Bech32AddrLen = 'zil'.length + 1 + 32 + 6;

export class LedgerController {
  private _transport = TransportBLE;

  constructor(transport: NativeTransport<LedgerController>, scrambleKey = 'w0w') {
    this._transport = transport;
    transport.decorateAppAPIMethods(
        this,
        [
          'getVersion',
          'getPublicKey',
          'getPublicAddress',
          'signHash',
          'signTxn'
        ],
        scrambleKey
    );
  }

  public async getVersion(): Promise<string | null> {
    const P1 = 0x00;
    const P2 = 0x00;

    const response: number[] = await this._transport.send(CLA, INS.getVersion, P1, P2);
    let version = 'v';

    for (let i = 0; i < 3; ++i) {
        version += parseInt('0x' + response[i]);
        if (i !== 2) {
            version += '.';
        }
    }

    if (response[0] === 0 || response[0] === 1) {
      return version;
    }

    return null;
  }

  public async getPublicKey(index: number): Promise<string> {
    const P1 = 0x00;
    const P2 = 0x00;

    const payload = Buffer.alloc(4);
    payload.writeInt32LE(index);
    const response: Buffer = await this._transport.send(CLA, INS.getPublickKey, P1, P2, payload);

    return response.toString('hex').slice(0, PubKeyByteLen * 2);
  }

  public async getPublicAddress(index: number) {
    const P1 = 0x00;
    const P2 = 0x01;

    const payload = Buffer.alloc(4);
    payload.writeInt32LE(index);
    const response: Buffer = await this._transport.send(CLA, INS.getPublicAddress, P1, P2, payload);
    const publicKey = response.toString('hex').slice(0, PubKeyByteLen * 2);
    const pubAddr = response
        .slice(PubKeyByteLen, PubKeyByteLen + Bech32AddrLen)
        .toString('utf-8');
    return {
      pubAddr,
      publicKey
    };
  }

  public signTxn (keyIndex: number, txnParams: Transaction) {
    // https://github.com/Zilliqa/Zilliqa-JavaScript-Library/tree/dev/packages/zilliqa-js-account#interfaces
    const P1 = 0x00;
    const P2 = 0x00;

    const indexBytes = Buffer.alloc(4);
    indexBytes.writeInt32LE(keyIndex);

    let txnBytes = txnParams.encodedProto();

    const STREAM_LEN = 128; // Stream in batches of STREAM_LEN bytes each.
    let txn1Bytes;
    if (txnBytes.length > STREAM_LEN) {
      txn1Bytes = txnBytes.slice(0, STREAM_LEN);
      txnBytes = txnBytes.slice(STREAM_LEN, undefined);
    } else {
      txn1Bytes = txnBytes;
      txnBytes = Buffer.alloc(0);
    }

    const txn1SizeBytes = Buffer.alloc(4);
    txn1SizeBytes.writeInt32LE(txn1Bytes.length);
    const hostBytesLeftBytes = Buffer.alloc(4);
    hostBytesLeftBytes.writeInt32LE(txnBytes.length);
    // See signTxn.c:handleSignTxn() for sequence details of payload.
    // 1. 4 bytes for indexBytes.
    // 2. 4 bytes for hostBytesLeftBytes.
    // 3. 4 bytes for txn1SizeBytes (number of bytes being sent now).
    // 4. txn1Bytes of actual data.
    const payload = Buffer.concat([
      indexBytes,
      hostBytesLeftBytes,
      txn1SizeBytes,
      txn1Bytes
    ]);

    const transport = this._transport;
    return transport
      .send(CLA, INS.signTxn, P1, P2, payload)
      .then(function cb (response: Buffer) {
        // Keep streaming data into the device till we run out of it.
        // See signTxn.c:istream_callback() for how this is used.
        // Each time the bytes sent consists of:
        //  1. 4-bytes of hostBytesLeftBytes.
        //  2. 4-bytes of txnNSizeBytes (number of bytes being sent now).
        //  3. txnNBytes of actual data.
        if (txnBytes.length > 0) {
          let txnNBytes;
          if (txnBytes.length > STREAM_LEN) {
            txnNBytes = txnBytes.slice(0, STREAM_LEN);
            txnBytes = txnBytes.slice(STREAM_LEN, undefined);
          } else {
            txnNBytes = txnBytes;
            txnBytes = Buffer.alloc(0);
          }

          const txnNSizeBytes = Buffer.alloc(4);
          txnNSizeBytes.writeInt32LE(txnNBytes.length);
          hostBytesLeftBytes.writeInt32LE(txnBytes.length);
          const data = Buffer.concat([
            hostBytesLeftBytes,
            txnNSizeBytes,
            txnNBytes
          ]);
          return transport.send(CLA, INS.signTxn, P1, P2, data).then(cb);
        }
        return response;
      })
      .then((result: Buffer) => {
        return (result.toString('hex').slice(0, SigByteLen * 2));
      });
  }

  public async signHash(keyIndex: number, hash: string) {
    const P1 = 0x00;
    const P2 = 0x00;
    const indexBytes = Buffer.alloc(4);
    indexBytes.writeInt32LE(keyIndex);
    const hashBytes = Buffer.from(hash, "hex");
    const hashLen = hashBytes.length;
    if (hashLen <= 0) {
      throw Error(`Hash length ${hashLen} is invalid`);
    }
    if (hashLen > HashByteLen) {
      hashBytes.slice(0, HashByteLen);
    }
    const payload = Buffer.concat([indexBytes, hashBytes]);
    const result: Buffer = await this._transport.send(CLA, INS.signHash, P1, P2, payload);

    return (result.toString('hex').slice(0, SigByteLen * 2));
  }

}
