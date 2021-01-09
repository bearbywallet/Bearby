/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import { createStackNavigator, StackNavigationOptions } from '@react-navigation/stack';
import { useTheme } from '@react-navigation/native';

import LetStartPage from 'app/pages/let-start';
import GetStartedPage from 'app/pages/get-started';
import LockPage from 'app/pages/lock';
import RestorePage from 'app/pages/restore';
import PrivacyPage from 'app/pages/privacy';
import MnemonicGenPage from 'app/pages/mnemonic-gen';
import MnemonicVerifyPage from 'app/pages/mnemonic-verify';
import SetupPasswordPage from 'app/pages/setup-password';
import InitSuccessfullyPage from 'app/pages/init-successfully';

export type UnauthorizedStackParamList = {
  GetStarted: undefined;
  Privacy: undefined;
  LetStart: undefined;
  Lock: undefined;
  Restore: undefined;
  Mnemonic: undefined;
  MnemonicVerif: {
    phrase: string;
  };
  SetupPassword: {
    phrase: string
  };
  InitSuccessfully: undefined;
};

const UnauthorizedStack = createStackNavigator<UnauthorizedStackParamList>();
export const Unauthorized: React.FC = () => {
  const { colors } = useTheme();

  const headerOptions: StackNavigationOptions = React.useMemo(() => ({
    headerTintColor: colors.text,
    headerStyle: {
      backgroundColor: colors.background,
      elevation: 0,
      shadowOpacity: 0
    },
    headerTitleStyle: {
      fontWeight: 'bold'
    }
  }), [colors]);

  return (
    <UnauthorizedStack.Navigator>
      <UnauthorizedStack.Screen
        name="GetStarted"
        component={GetStartedPage}
        options={{
          header: () => null,
          title: ''
        }}
      />
      <UnauthorizedStack.Screen
        name="Lock"
        component={LockPage}
        options={{
          header: () => null,
          title: ''
        }}
      />
      <UnauthorizedStack.Screen
        name="SetupPassword"
        component={SetupPasswordPage}
        options={{
          header: () => null,
          title: ''
        }}
      />
      <UnauthorizedStack.Screen
        name="InitSuccessfully"
        component={InitSuccessfullyPage}
        options={{
          header: () => null,
          title: ''
        }}
      />
      <UnauthorizedStack.Screen
        name="Privacy"
        component={PrivacyPage}
        options={headerOptions}
      />
      <UnauthorizedStack.Screen
        name="LetStart"
        component={LetStartPage}
        options={{
          ...headerOptions,
          title: ''
        }}
      />
      <UnauthorizedStack.Screen
        name="Restore"
        component={RestorePage}
        options={headerOptions}
      />
      <UnauthorizedStack.Screen
        name="Mnemonic"
        component={MnemonicGenPage}
        options={{
          ...headerOptions,
          title: ''
        }}
      />
      <UnauthorizedStack.Screen
        name="MnemonicVerif"
        component={MnemonicVerifyPage}
        options={{
          ...headerOptions,
          title: ''
        }}
      />
    </UnauthorizedStack.Navigator>
  );
};
