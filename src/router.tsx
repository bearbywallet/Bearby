/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import * as React from 'react';
import { createAppContainer, createSwitchNavigator, NavigationScreenConfig } from 'react-navigation';
import { createStackNavigator } from 'react-navigation-stack';

import LetStartPage from 'app/pages/let-start';
import GetStartedPage from 'app/pages/get-started';
import LockPage from 'app/pages/lock';
import RestorePage from 'app/pages/restore';
import PrivacyPage from 'app/pages/privacy';
import MnemonicGenPage from 'app/pages/mnemonic-gen';
import MnemonicVerifyPage from 'app/pages/mnemonic-verify';
import SetupPasswordPage from 'app/pages/setup-password';
import InitSuccessfullyPage from 'app/pages/init-successfully';
import HomePage from 'app/pages/home';
import AuthLoadingPage from 'app/pages/auth-loading';

import { theme } from './styles';

const AppStack = createStackNavigator({
  Home: {
    screen: HomePage,
    navigationOptions: {
      header: () => null,
      title: ''
    }
  }
});
const AuthStack = createStackNavigator({
  GetStarted: {
    screen: GetStartedPage,
    navigationOptions: {
      header: () => null,
      title: ''
    }
  },
  Lock: {
    screen: LockPage,
    navigationOptions: {
      header: () => null,
      title: ''
    }
  },
  SetupPassword: {
    screen: SetupPasswordPage,
    navigationOptions: {
      header: () => null
    }
  },
  InitSuccessfully: {
    screen: InitSuccessfullyPage,
    navigationOptions: {
      header: () => null
    }
  },
  Privacy: {
    screen: PrivacyPage,
    navigationOptions: {
      headerTintColor: theme.colors.white,
      headerStyle: {
        backgroundColor: theme.colors.black
      },
      headerTitleStyle: {
        fontWeight: 'bold'
      }
    }
  },
  LetStart: {
    screen: LetStartPage,
    navigationOptions: {
      title: '',
      headerTintColor: theme.colors.white,
      headerStyle: {
        backgroundColor: theme.colors.black
      },
      headerTitleStyle: {
        fontWeight: 'bold'
      }
    }
  },
  Restore: {
    screen: RestorePage,
    navigationOptions: {
      headerTintColor: theme.colors.white,
      headerStyle: {
        backgroundColor: theme.colors.black
      },
      headerTitleStyle: {
        fontWeight: 'bold'
      }
    }
  },
  Mnemonic: {
    screen: MnemonicGenPage,
    navigationOptions: {
      headerTintColor: theme.colors.white,
      headerStyle: {
        backgroundColor: theme.colors.black
      },
      headerTitleStyle: {
        fontWeight: 'bold'
      }
    }
  },
  MnemonicVerif: {
    screen: MnemonicVerifyPage,
    navigationOptions: {
      headerTintColor: theme.colors.white,
      headerStyle: {
        backgroundColor: theme.colors.black
      },
      headerTitleStyle: {
        fontWeight: 'bold'
      }
    }
  }
});

const GuardStack = createSwitchNavigator(
  {
    AuthLoading: AuthLoadingPage,
    App: AppStack,
    Auth: AuthStack,
  },
  {
    initialRouteName: 'AuthLoading',
  }
);

export default createAppContainer(GuardStack);
