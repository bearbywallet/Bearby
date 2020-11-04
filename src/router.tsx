/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import * as React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';

import CreateWalletPage from 'app/pages/create-wallet';
import GetStartedPage from 'app/pages/get-started';
import LockPage from 'app/pages/lock';
import RestorePage from 'app/pages/restore';
import { HomePage } from './pages/home';
import { BrowserPage } from './pages/browser';
import { SettingsPage } from './pages/settings';
import { HistoryPage } from './pages/history';

import { SvgXml } from 'react-native-svg';

import {
  HomeIconSVG,
  TimerIconSVG,
  BrowserIconSVG,
  SettingsIconSVG
} from 'app/components/svg';
import I18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { WalletContext } from './keystore';

const Stack = createStackNavigator();
const Tab = createBottomTabNavigator();
const tabBarOptions = {
  activeTintColor: theme.colors.primary,
  activeColor: theme.colors.white,
  labelStyle: {
    fontSize: 12
  },
  inactiveTintColor: theme.colors.muted,
  style: {
    backgroundColor: theme.colors.gray
  }
};
const screens = [
  CreateWalletPage,
  GetStartedPage,
  LockPage,
  RestorePage
];

export default function Navigator() {
  const keystore = React.useContext(WalletContext);

  const initialRouteName = React.useMemo(() => {
    const { isEnable } = keystore.guard;

    if (!isEnable) {
      return GetStartedPage.name;
    }

    return LockPage.name;
  }, [keystore]);

  if (!keystore.guard.isEnable) {
    return (
      <Stack.Navigator
        headerMode={'none'}
        initialRouteName={initialRouteName}
      >
        {screens.map((screen, index) => (
          <Stack.Screen
            key={index}
            name={screen.name}
            component={screen.component}
          />
        ))}
      </Stack.Navigator>
    );
  }

  return (
    <Tab.Navigator tabBarOptions={tabBarOptions}>
      <Tab.Screen
        name="Home"
        component={HomePage}
        options={{
          tabBarLabel: I18n.t('home'),
          tabBarIcon: ({ color }) => (
            <SvgXml
              xml={HomeIconSVG}
              fill={color}
            />
          )
        }}
      />
      <Tab.Screen
        name="History"
        component={HistoryPage}
        options={{
          tabBarLabel: I18n.t('history'),
          tabBarIcon: ({ color }) => (
            <SvgXml
              xml={TimerIconSVG}
              fill={color}
            />
          )
        }}
      />
      <Tab.Screen
        name="Browser"
        component={BrowserPage}
        options={{
          tabBarLabel: I18n.t('browser'),
          tabBarIcon: ({ color }) => (
            <SvgXml
              xml={BrowserIconSVG}
              fill={color}
            />
          )
        }}
      />
      <Tab.Screen
        name="Settings"
        component={SettingsPage}
        options={{
          tabBarLabel: I18n.t('settings'),
          tabBarIcon: ({ color }) => (
            <SvgXml
              xml={SettingsIconSVG}
              fill={color}
            />
          )
        }}
      />
    </Tab.Navigator>
  );
}
