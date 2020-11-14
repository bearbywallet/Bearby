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
  Text,
  StyleSheet
} from 'react-native';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';

export const SetupPasswordPage = () => {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>
        {i18n.t('password_title')}
      </Text>
      <View style={styles.wrapper}>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    backgroundColor: theme.colors.black
  },
  title: {
    textAlign: 'center',
    fontWeight: 'bold',
    color: theme.colors.white,
    fontSize: 34,
    lineHeight: 41
  },
  wrapper: {
    flex: 1
  }
});

export default SetupPasswordPage;
