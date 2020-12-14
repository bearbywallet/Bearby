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
  StatusBar,
  SafeAreaView
} from 'react-native';
import LottieView from 'lottie-react-native';

import { keystore } from 'app/keystore';
import { RootParamList } from 'app/navigator';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

export const AuthLoadingPage: React.FC<Prop> = ({ navigation }) => {
  React.useEffect(() => {
    keystore.sync().then(() => {
      const { isEnable, isReady } = keystore.guard.self;

      if (!isReady) {
        return navigation.navigate('Unauthorized', { screen: 'GetStarted' });
      }
      if (!isEnable && isReady) {
        return navigation.navigate('Unauthorized', { screen: 'Lock' });
      }

      navigation.navigate('App', { screen: 'Home' });
    });
  });

  return (
    <React.Fragment>
      <StatusBar barStyle="light-content" />
      <SafeAreaView style={{
        flex: 1,
        backgroundColor: '#09090c'
      }}>
        <LottieView
          source={require('app/assets/loader')}
          autoPlay
          loop
        />
      </SafeAreaView>
    </React.Fragment>
  );
};

export default AuthLoadingPage;
