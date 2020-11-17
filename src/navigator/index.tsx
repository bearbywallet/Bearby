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

import { TabNavigator } from './tab-navigator';
import { Unauthorized } from './unauthorized';
import { PreLoading } from './pre-loading';
import { Settings } from './settings';

const Stack = createStackNavigator();

export default () => (
  <Stack.Navigator
    headerMode="none"
    initialRouteName="Loading"
  >
    <Stack.Screen name="Loading" component={PreLoading} />
    <Stack.Screen name="Unauthorized" component={Unauthorized} />
    <Stack.Screen name="App" component={TabNavigator} />
    <Stack.Screen name="SettingsPages" component={Settings} />
  </Stack.Navigator>
);
