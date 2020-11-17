/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import { NavigationScreenProp, NavigationState } from 'react-navigation';
import {
  ActivityIndicator,
  StatusBar,
  View,
} from 'react-native';

import { keystore } from 'app/keystore';
import { theme } from 'app/styles';

type Prop = {
  navigation: NavigationScreenProp<NavigationState>;
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

      return navigation.navigate('App', { screen: 'Home' });
    });
  });

  return (
    <View style={{
      flex: 1,
      justifyContent: 'center',
      backgroundColor: theme.colors.black
    }}>
      <ActivityIndicator />
      <StatusBar barStyle="default" />
    </View>
  );
};

export default AuthLoadingPage;
