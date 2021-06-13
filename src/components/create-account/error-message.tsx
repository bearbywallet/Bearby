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
  StyleSheet,
  View,
  Text
} from 'react-native';
import { useTheme } from '@react-navigation/native';

import { fonts } from 'app/styles';

type Prop = {
  title: string;
  message: string;
};
export const ErrorMessage: React.FC<Prop> = ({
  title,
  message
}) => {
  const { colors } = useTheme();

  return (
    <View style={styles.container}>
      <Text style={styles.title}>
        {title}
      </Text>
      <Text
        style={[styles.message, {
          color: colors.notification
        }]}
      >
        {message}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center'
  },
  title: {
    fontFamily: fonts.Bold,
    fontSize: 20,
    textAlign: 'center'
  },
  message: {
    fontFamily: fonts.Regular,
    fontSize: 16,
    textAlign: 'center'
  }
});
