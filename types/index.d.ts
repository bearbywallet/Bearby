/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
export * from './store';
export * from './inpage';
export * from './ssn';

export interface ZilliqaNetwork {
  [key: string]: {
    PROVIDER: string;
    WS: string;
    MSG_VERSION: number
  }
}

type getBase64 = (event: string) => void;

export interface QrcodeType {
  toDataURL: (cb: getBase64) => void;
}

export interface PubNubMesage {
  channel: string;
  actualChannel?: string | null;
  subscribedChannel?: string;
  timetoken?: string;
  publisher?: string;
  userMetadata?: object;
  sendByPost?: boolean;
  storeInHistory?: boolean;
  message: {
      event: string;
      data?: object;
  };
}

export interface PubNubStatus {
  category: string;
  operation: string;
  affectedChannels: string[];
  subscribedChannels: string[];
  affectedChannelGroups: string[];
  lastTimetoken: number;
  currentTimetoken: string;
}

export interface PubNubSubscribePayload {
  channels: string[];
  withPresence: boolean;
}

export interface PubNubPublishStatus {
  error: boolean;
  operation: string;
  statusCode: number;
}

export interface PubNubPublishResponse {
  timetoken: string;
}

export interface PubNubEventListener {
  message?: (m: PubNubMesage) => void;
  presence?: (m: object) => void;
  signal?: (m: object) => void;
  objects?: (objectEvent: object) => void;
  messageAction?: (ma: object) => void;
  file?: (m: object) => void;
  status?: (s: PubNubStatus) => void;
}

export interface PubHubInstance {
  addListener: (payload: PubNubEventListener) => void;
  removeListener: (payload: PubNubEventListener) => void;
  removeAllListeners: () => void;
  stop: () => void;
  publish: (
    publishPayload: object,
    callback: (status: PubNubPublishStatus, response: PubNubPublishResponse) => void
  ) => void;
  subscribe: (paylaod: PubNubSubscribePayload) => void;
  unsubscribeAll: () => void;
}
