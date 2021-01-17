/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import PushNotificationIOS from '@react-native-community/push-notification-ios';
import RNPushNotification, { ReceivedNotification } from 'react-native-push-notification';
import {
  notificationStoreReset,
  notificationStore,
  notificationStoreUpdate
} from './store';

import { StackNavigationProp } from '@react-navigation/stack';
import { RootParamList } from 'app/navigator';
import { MobileStorage, buildObject, NetworkControll } from 'app/lib';
import { STORAGE_FIELDS } from 'app/config';
import { NotificationState } from 'types';
import { viewTransaction, Device } from 'app/utils';

export type MessageNotification = {
  title: string;
  message: string;
  userInfo: {
    hash: string;
  }
};
export type NotificationPermissions = {
  alert: boolean;
  badge: boolean;
  sound: boolean;
};

const CHANNEL_ID = 'default-channel-id';

export class NotificationManager {
  public store = notificationStore;
  private _navigation: StackNavigationProp<RootParamList> | undefined;
  private _storage: MobileStorage;
  private _netwrok: NetworkControll;

  constructor(storage: MobileStorage, netwrok: NetworkControll) {
    this._storage = storage;
    this._netwrok = netwrok;
  }

  public setNavigation(navigation: StackNavigationProp<RootParamList>) {
    this._navigation = navigation;
  }

  public async reset() {
    notificationStoreReset();

    await this._storage.set(
      buildObject(STORAGE_FIELDS.NOTIFICATION, this.store.get())
    );
  }

  public async sync() {
    const data = await this._storage.get(STORAGE_FIELDS.NOTIFICATION);

    try {
      if (typeof data === 'string') {
        const state = JSON.parse(data);

        await this._update(state);
      }
    } catch {
      await this.reset();
    }

    if (this.store.get().enabled) {
      RNPushNotification.configure({
        requestPermissions: Device.isIos(),
        popInitialNotification: true,
        onNotification: (n) => this.onNotification(n)
      });

      RNPushNotification.createChannel(
        {
          channelId: CHANNEL_ID,
          channelName: 'Default channel'
        },
        () => null
      );
    }
  }

  public onNotification(notification: Omit<ReceivedNotification, 'userInfo'>) {
    if (!notification || !notification.data || !this._navigation) {
      return null;
    }
    const net = this._netwrok.selected;
    const hash = notification.data['hash'];

    const url = viewTransaction(hash, net);

    this._navigation.navigate('Browser', {
      screen: 'Web',
      params: {
        url
      }
    });
  }

  public async toggleNotification() {
    const state = this.store.get();

    await this._update({
      ...state,
      enabled: !state.enabled
    });
  }

  public abandonPermissions() {
    if (Device.isIos()) {
      PushNotificationIOS.abandonPermissions();
    }
  }

  public setBadgeNumber(count: number) {
    if (count < 0) {
      count = 0;
    }

    if (Device.isIos()) {
      PushNotificationIOS.setApplicationIconBadgeNumber(count);
    }
  }

  public getBadgeNumber(): Promise<number> {
    return new Promise((resolve) => {
      if (Device.isIos()) {
        return PushNotificationIOS.getApplicationIconBadgeNumber(resolve);
      }

      return resolve(0);
    });
  }

  public getPermissions() {
    return new Promise((resolve) => {
      if (Device.isIos()) {
        PushNotificationIOS.checkPermissions(resolve);
      }

      resolve({
        alert: true,
        badge: true,
        sound: true
      });
    });
  }

  public localNotification(message: MessageNotification) {
    if (this.store.get().enabled) {
      RNPushNotification.localNotification({
        ...message,
        channelId: 'default-channel-id'
      });
    }
  }

  public requestPermissions(permissions: NotificationPermissions) {
      if (Device.isIos()) {
        return PushNotificationIOS.requestPermissions(permissions);
      }
  }

  private async _update(state: NotificationState) {
    notificationStoreUpdate(state);

    await this._storage.set(
      buildObject(STORAGE_FIELDS.NOTIFICATION, this.store.get())
    );
  }
}
