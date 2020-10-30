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
import { LockPage } from './pages/lock';
import { AccountsPage } from './pages/accounts';
import { ConnectPage } from './pages/connect';
import { ContactsPage } from './pages/contacts';
import { CreateWalletPage } from './pages/create-wallet';
import { VerifyPage } from './pages/verify';

import {
  HomeIconSVG,
  TimerIconSVG
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
        name="Lock"
        component={LockPage}
        options={{
          tabBarLabel: I18n.t('home'),
          tabBarIcon: () => (
            <SvgXml xml={TimerIconSVG} />
          )
        }}
      />
      <Tab.Screen name="Accounts" component={AccountsPage} />
      <Tab.Screen name="Conect" component={ConnectPage} />
      <Tab.Screen name="Contacts" component={ContactsPage} />
      <Tab.Screen name="Create" component={CreateWalletPage} />
      <Tab.Screen name="Verify" component={VerifyPage} />
    </Tab.Navigator>
  );
}
