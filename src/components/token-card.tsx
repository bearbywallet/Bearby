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
  StyleSheet,
  Text,
  ViewStyle
} from 'react-native';
import { Token } from 'types';
import { theme } from 'app/styles';

export type Prop = {
  token: Token;
  style?: ViewStyle;
};

export const TokenCard: React.FC<Prop> = ({ token, style }) => {
  return (
    <View style={[styles.container, style]}>
      <Text>
        {token.symbol}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    borderRadius: 8,
    minHeight: 90,
    width: '45%',
    maxWidth: 150,
    backgroundColor: theme.colors.gray
  }
});
