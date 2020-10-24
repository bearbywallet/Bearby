/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import { View, StyleSheet, Text } from 'react-native';
// import { useTheme } from '@react-navigation/native';

import { colors } from '../styles';
// import { WalletControler } from '../lib/controller';

// const wallet = new WalletControler();

// async function test() {
//   const seed = await wallet.generateMnemonic();
//   const password = '123';

//   await wallet.initWallet(password, seed);
// };

// test();

export const HomePage = () => {
  // const { colors } = useTheme();

  return (
    <View style={styles.container}>
      <Text>
        dasdsa
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.primary
  }
});
