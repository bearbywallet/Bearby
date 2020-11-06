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

import CreateWalletPage from 'app/pages/create-wallet';
import GetStartedPage from 'app/pages/get-started';
import LockPage from 'app/pages/lock';
import RestorePage from 'app/pages/restore';
import PrivacyPage from 'app/pages/privacy';

import { WalletContext } from './keystore';

export type RootStackParamList = {
  GetStarted: undefined;
  Privacy: undefined;
  Create: undefined;
  Lock: undefined;
  Restore: undefined;
};

const Stack = createStackNavigator<RootStackParamList>();

export default function Navigator() {
  const keystore = React.useContext(WalletContext);

  const initialRouteName = React.useMemo(() => {
    const { isEnable } = keystore.guard;

    if (!isEnable) {
      return 'GetStarted';
    }

    return 'Lock';
  }, [keystore]);

  return (
    <Stack.Navigator
      headerMode={'none'}
      initialRouteName={initialRouteName}
    >
      <Stack.Screen
        name={'GetStarted'}
        component={GetStartedPage}
      />
      <Stack.Screen
        name={'Privacy'}
        component={PrivacyPage}
      />
      <Stack.Screen
        name={'Create'}
        component={CreateWalletPage}
      />
      <Stack.Screen
        name={'Lock'}
        component={LockPage}
      />
      <Stack.Screen
        name={'Restore'}
        component={RestorePage}
      />
    </Stack.Navigator>
  );
}
