/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */

import React from 'react';
import {
  View,
  StyleSheet
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { HomeAccount, HomeTokens } from 'app/components/home';

import { theme } from 'app/styles';
import { RootParamList } from 'app/navigator';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

export const HomePage: React.FC<Prop> = ({ navigation }) => {
  const handleCreateAccount = React.useCallback(() => {
    navigation.navigate('Common', {
      screen: 'CreateAccount'
    });
  }, []);

  return (
    <View style={styles.container}>
      <HomeAccount onCreateAccount={handleCreateAccount}/>
      <HomeTokens />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
  }
});

export default HomePage;
