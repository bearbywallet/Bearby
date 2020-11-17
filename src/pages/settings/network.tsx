/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import { View, StyleSheet } from 'react-native';

import { colors } from 'app/styles';

export const NetworkPage = () => {

  return (
    <View style={styles.container} />
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.secondary
  }
});

export default NetworkPage;
