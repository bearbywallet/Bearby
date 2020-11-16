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
import MnemonicGenPage from 'app/pages/mnemonic-gen';
import MnemonicVerifypage from 'app/pages/mnemonic-verify';
import SetupPasswordPage from 'app/pages/setup-password';
import InitSuccessfullyPage from 'app/pages/init-successfully';
import HomePage from 'app/pages/home';

import { WalletContext } from './keystore';
import { theme } from './styles';
import i18n from 'app/lib/i18n';

export type RootStackParamList = {
  GetStarted: undefined;
  Privacy: undefined;
  Create: undefined;
  Lock: undefined;
  Restore: undefined;
  Mnemonic: undefined;
  MnemonicVerif: {
    phrase: string
  };
  SetupPassword: {
    phrase: string
  };
  InitSuccessfully: undefined;
  Home: undefined;
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

  const HanldeRoute = React.useCallback(({ route, navigation }) => {
    return {
      headerShown: false,
      gestureEnabled: true,
      cardOverlayEnabled: true,
      headerTintColor: theme.colors.white,
      headerStyle: {
        backgroundColor: theme.colors.black
      }
    };
  }, []);

  return (
    <Stack.Navigator
      headerMode={'screen'}
      initialRouteName={initialRouteName}
      screenOptions={HanldeRoute}
    >
      {/* <Stack.Screen
        name={'GetStarted'}
        component={GetStartedPage}
        options={{ title: '' }}
      />
      <Stack.Screen
        name={'Privacy'}
        component={PrivacyPage}
        options={{ title: i18n.t('privacy_title') }}
      />
      <Stack.Screen
        name={'Create'}
        component={CreateWalletPage}
        options={{ title: '' }}
      />
      <Stack.Screen
        name={'Lock'}
        component={LockPage}
      />
      <Stack.Screen
        name={'Restore'}
        component={RestorePage}
        options={{ title: '' }}
      />
      <Stack.Screen
        name={'Mnemonic'}
        component={MnemonicGenPage}
        options={{ title: '' }}
      />
      <Stack.Screen
        name={'MnemonicVerif'}
        component={MnemonicVerifypage}
        options={{ title: '' }}
      />
      <Stack.Screen
        name={'SetupPassword'}
        component={SetupPasswordPage}
        options={{ title: '' }}
      /> */}

      {/* guarded */}
      {/* <Stack.Screen
        name={'InitSuccessfully'}
        component={InitSuccessfullyPage}
        options={{ title: '' }}
      /> */}
      <Stack.Screen
        name={'Home'}
        component={HomePage}
        options={{ title: '' }}
      />
    </Stack.Navigator>
  );
}
