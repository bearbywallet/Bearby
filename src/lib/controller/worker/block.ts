/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import WebView from 'react-native-webview';
import BackgroundTimer from 'react-native-background-timer';
import { ZilliqaControl } from 'app/lib/controller/zilliqa';
import { BLOCK_INTERVAL, STORAGE_FIELDS, Messages } from 'app/config';
import { MobileStorage, buildObject } from 'app/lib/storage';
import { blockStore, blockStoreUpdate } from './store';
import { Message } from 'app/lib/controller/inject/message';

export class BlockControl {
  private _zilliqa: ZilliqaControl;
  private _storage: MobileStorage;
  private _webView: WebView | undefined;
  private _origin: string | undefined;

  constructor(
    storage: MobileStorage,
    zilliqa: ZilliqaControl
  ) {
    this._zilliqa = zilliqa;
    this._storage = storage;
  }

  public async sync() {
    const result = await this._storage.get(STORAGE_FIELDS.BLOCK_NUMBER);
    const blocknumber = Number(result);

    if (blocknumber > 0) {
      blockStoreUpdate(blocknumber);
    }
  }

  public updateWebView(webView: WebView | undefined, origin = '') {
    this._webView = webView;
    this._origin = origin;
  }

  public async subscriber(cb: (blocknumber: number) => void) {
    await this.sync();

    BackgroundTimer.runBackgroundTimer(async() => {
      const lastBalockNumber = blockStore.get();
      const result = await this._zilliqa.getLatestTxBlock();
      const blockNumber = Number(result.header.BlockNum);

      if (lastBalockNumber === blockNumber) {
        return null;
      }

      blockStoreUpdate(blockNumber);
      cb(blockNumber);

      await this._cache();

      if (this._webView && this._origin) {
        const { TxnHashes } = await this._zilliqa.getRecentTransactions();
        const m = new Message(Messages.block, {
          origin: this._origin,
          data: {
            block: {
              TxBlock: result,
              TxHashes: [TxnHashes]
            }
          }
        });
        this._webView.postMessage(m.serialize);
      }
    }, BLOCK_INTERVAL);
  }

  private async _cache() {
    const blocknumber = blockStore.get();

    await this._storage.set(
      buildObject(STORAGE_FIELDS.BLOCK_NUMBER, String(blocknumber))
    );
  }
}
