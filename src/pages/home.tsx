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
import { HomeAccount, HomeTokens } from 'app/components/home';

import { theme } from 'app/styles';

export const HomePage = () => {
  return (
    <View style={styles.container}>
      <HomeAccount />
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
