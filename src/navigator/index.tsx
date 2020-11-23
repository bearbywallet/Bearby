/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';

import { createStackNavigator } from '@react-navigation/stack';
import { NavigatorScreenParams } from '@react-navigation/native';

import { TabNavigator, TabStackParamList } from './tab-navigator';
import { Unauthorized, UnauthorizedStackParamList } from './unauthorized';
import { PreLoading, PreLoadingStackParamList } from './pre-loading';
import { Settings, SettingsStackParamList } from './settings';
import { Common, CommonStackParamList } from './common';

export type RootParamList = {
  Loading: NavigatorScreenParams<PreLoadingStackParamList>;
  Unauthorized: NavigatorScreenParams<UnauthorizedStackParamList>;
  App: NavigatorScreenParams<TabStackParamList>;
  SettingsPages: NavigatorScreenParams<SettingsStackParamList>;
  Common: NavigatorScreenParams<CommonStackParamList>;
};

const Stack = createStackNavigator<RootParamList>();

export default () => (
  <Stack.Navigator
    headerMode="none"
    initialRouteName="Loading"
    screenOptions={{ gestureEnabled: false }}
  >
    <Stack.Screen
      name="Loading"
      component={PreLoading}
    />
    <Stack.Screen
      name="Unauthorized"
      component={Unauthorized}
    />
    <Stack.Screen
      name="App"
      component={TabNavigator}
      options={{
        title: ''
      }}
    />
    <Stack.Screen
      name="Common"
      component={Common}
      options={{
        title: ''
      }}
    />
    <Stack.Screen
      name="SettingsPages"
      component={Settings}
    />
  </Stack.Navigator>
);
