/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import * as React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { SvgXml } from 'react-native-svg';

import { HomePage } from './pages/home';
import { BrowserPage } from './pages/browser';
import { SettingsPage } from './pages/settings';
import { HistoryPage } from './pages/history';


import {
  HomeIconSVG,
  TimerIconSVG,
  BrowserIconSVG,
  SettingsIconSVG
} from 'app/components/svg';
import I18n from 'app/lib/i18n';
import { theme } from 'app/styles';

const Tab = createBottomTabNavigator();
const tabBarOptions = {
  activeTintColor: theme.colors.white,
  style: {
    backgroundColor: theme.colors.gray
  }
};

export default function Router() {
  return (
    <Tab.Navigator tabBarOptions={tabBarOptions}>
      <Tab.Screen
        name="Home"
        component={HomePage}
        options={{
          tabBarLabel: I18n.t('home'),
          tabBarIcon: () => (
            <SvgXml xml={HomeIconSVG} />
          )
        }}
      />
      <Tab.Screen
        name="History"
        component={HistoryPage}
        options={{
          tabBarLabel: I18n.t('history'),
          tabBarIcon: () => (
            <SvgXml xml={TimerIconSVG} />
          )
        }}
      />
      <Tab.Screen
        name="Browser"
        component={BrowserPage}
        options={{
          tabBarLabel: I18n.t('browser'),
          tabBarIcon: () => (
            <SvgXml xml={BrowserIconSVG} />
          )
        }}
      />
      <Tab.Screen
        name="Settings"
        component={SettingsPage}
        options={{
          tabBarLabel: I18n.t('settings'),
          tabBarIcon: () => (
            <SvgXml xml={SettingsIconSVG} />
          )
        }}
      />
    </Tab.Navigator>
  );
}
