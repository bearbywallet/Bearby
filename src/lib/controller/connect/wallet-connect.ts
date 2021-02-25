/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import PubNub from 'pubnub';

import {
	PubHubInstance,
	PubNubMesage,
	PubNubPublishStatus,
	PubNubPublishResponse,
	PubNubDataResult
} from 'types';
import { WalletConnectTypes } from 'app/config';
import EventEmitter from 'events';

type MessageResponse = {
	status: PubNubPublishStatus;
	response: PubNubPublishResponse;
};

const PUB_KEY = 'pub-c-59f9788d-7754-46e8-b653-71566255aac1';
const SUB_KEY = 'sub-c-2b8cbe56-766b-11eb-b2c3-2e58680e8335';
const EXPIRED_CODE_TIMEOUT = 30000;

export class PubNubWrapper {
	public static FIELD = 'zilpay-sync';

	private _event = new EventEmitter();
	private _pubnub: PubHubInstance;
	private _cipherKey: string;
	private _channelName: string;

	constructor(channelName: string, cipherKey?: string) {
		if (!cipherKey) {
			this._cipherKey = PubNub.generateUUID();
		} else {
			this._cipherKey = cipherKey;
		}

		this._pubnub = new PubNub({
			cipherKey: this._cipherKey,
			publishKey: PUB_KEY,
			subscribeKey: SUB_KEY,
			ssl: true
		});
		this._channelName = channelName;
		this._startListener();
		this._pubnub.subscribe({
			channels: [this._channelName],
			withPresence: false
		});
	}

	public async startSync(): Promise<PubNubDataResult> {
		const payload = {
			message: {
				event: WalletConnectTypes.Start
			},
			channel: this._channelName,
			sendByPost: false,
			storeInHistory: false
		};
		await this._sendMessage(payload);

		return new Promise((resolve, reject) => {
			this._event.once(WalletConnectTypes.SyncDone, (data) => {
				try {
					resolve(JSON.parse(data))
				} catch (err) {
					reject(err);
				}
			});
			this._event.once(WalletConnectTypes.SyncError, (err) => reject(err));
		});
	}

	public async endSync() {
		const payload = {
			message: {
				event: WalletConnectTypes.EndSync
			},
			channel: this._channelName,
			sendByPost: false,
			storeInHistory: false
		};
		await this._sendMessage(payload);

		this.disconnectWebsockets();
	}

	public disconnectWebsockets() {
		this._pubnub.removeAllListeners();
		this._pubnub.stop();
		this._pubnub.unsubscribeAll();
		this._event.removeAllListeners();
	}

	private _sendMessage(payload: PubNubMesage): Promise<MessageResponse> {
		return new Promise((resolve) => {
			this._pubnub.publish(payload, (status, response) => {
				resolve({
					status,
					response
				});
			})
		});
	}

	private _startListener() {
		this._pubnub.addListener({
			status: (event) => {
				if (event.category === "PNConnectedCategory") {
					this.startSync();
				}
			},
			message: ({ channel, message }) => {
				if (channel !== this._channelName || !message) {
					this.disconnectWebsockets();

					return false;
				}

				switch (message.event) {
					case WalletConnectTypes.SyncError:
						this._event.emit(WalletConnectTypes.SyncError, message.data);
						this.endSync();
						break;
					case WalletConnectTypes.SyncingData:
						this._event.emit(WalletConnectTypes.SyncDone, message.data);
						this.endSync();
						break;
					case WalletConnectTypes.EndSync:
						this.endSync();
						break;
					default:
						break;
				}
			}
		});
	}
}
