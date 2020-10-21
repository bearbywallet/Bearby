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
import { createStackNavigator } from '@react-navigation/stack';

import { HomePage } from './pages/home';
import { LockPage } from './pages/lock';
import { AccountsPage } from './pages/accounts';
import { ConnectPage } from './pages/connect';
import { ContactsPage } from './pages/contacts';
import { CreateWalletPage } from './pages/create-wallet';
import { VerifyPage } from './pages/verify';

import { theme } from './styles';

const Stack = createStackNavigator();

export default function Root() {
  return (
    <NavigationContainer theme={theme}>
      <Stack.Navigator headerMode="float">
        <Stack.Screen name="Home" component={HomePage} />
        <Stack.Screen name="Lock" component={LockPage} />
        <Stack.Screen name="Accounts" component={AccountsPage} />
        <Stack.Screen name="Conect" component={ConnectPage} />
        <Stack.Screen name="Contacts" component={ContactsPage} />
        <Stack.Screen name="Create" component={CreateWalletPage} />
        <Stack.Screen name="Verify" component={VerifyPage} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
