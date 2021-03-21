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
import SafeAreaView from 'react-native-safe-area-view';

import LottieView from 'lottie-react-native';

import { keystore } from 'app/keystore';
import { RootParamList } from 'app/navigator';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

export const AuthLoadingPage: React.FC<Prop> = ({ navigation }) => {
  React.useEffect(() => {
    keystore.notificationManager.setNavigation(navigation);
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
    .catch(() => {
      return navigation.navigate('Unauthorized', { screen: 'Lock' });
    });
  }, []);

  return (
    <React.Fragment>
      <StatusBar barStyle="light-content" />
      <SafeAreaView style={{
        flex: 1
      }}>
        <LottieView
          source={require('app/assets/dark')}
          autoPlay
          loop
        />
      </SafeAreaView>
    </React.Fragment>
  );
};

export default AuthLoadingPage;
