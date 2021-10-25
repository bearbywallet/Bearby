/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import { StackNavigationProp } from '@react-navigation/stack';
import {
  StatusBar
} from 'react-native';
import { SafeWrapper } from 'app/components/safe-wrapper';

import LottieView from 'lottie-react-native';

import { keystore } from 'app/keystore';
import { RootParamList } from 'app/navigator';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

export const AuthLoadingPage: React.FC<Prop> = ({ navigation }) => {
  React.useEffect(() => {
    keystore.notificationManager.setNavigation(navigation);

    if (keystore.guard.self.isReady) {
      navigation.navigate('Unauthorized', { screen: 'Lock' });
    }

    keystore.sync().then(() => {
      const { isEnable, isReady } = keystore.guard.self;

      if (!isReady) {
        return navigation.navigate('Unauthorized', { screen: 'GetStarted' });
      }
      if (!isEnable && isReady) {
        return navigation.navigate('Unauthorized', { screen: 'Lock' });
      }

      navigation.navigate('App', { screen: 'Home' });
    })
    .catch((err) => {
      console.error('AuthLoadingPage.sync', err);
      return navigation.navigate('Unauthorized', { screen: 'GetStarted' });
    });
  }, [navigation]);

  return (
    <React.Fragment>
      <StatusBar barStyle="light-content" />
      <SafeWrapper>
        <LottieView
          source={require('app/assets/dark')}
          autoPlay
          loop
        />
      </SafeWrapper>
    </React.Fragment>
  );
};

export default AuthLoadingPage;
