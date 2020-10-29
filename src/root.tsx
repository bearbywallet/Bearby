/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import * as React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';

import { HomePage } from './pages/home';
import { LockPage } from './pages/lock';
import { AccountsPage } from './pages/accounts';
import { ConnectPage } from './pages/connect';
import { ContactsPage } from './pages/contacts';
import { CreateWalletPage } from './pages/create-wallet';
import { VerifyPage } from './pages/verify';

import { theme } from './styles';
import { StatusBar } from 'react-native';

const Tab = createBottomTabNavigator();

export default function Root() {
  return (
    <NavigationContainer theme={theme}>
      <StatusBar barStyle="light-content"/>
      <Tab.Navigator>
        <Tab.Screen name="Home" component={HomePage} />
        <Tab.Screen name="Lock" component={LockPage} />
        <Tab.Screen name="Accounts" component={AccountsPage} />
        <Tab.Screen name="Conect" component={ConnectPage} />
        <Tab.Screen name="Contacts" component={ContactsPage} />
        <Tab.Screen name="Create" component={CreateWalletPage} />
        <Tab.Screen name="Verify" component={VerifyPage} />
      </Tab.Navigator>
    </NavigationContainer>
  );
}
