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
  StyleSheet,
  ViewStyle
} from 'react-native';
import { theme } from 'app/styles';

type Prop = {
  count?: number | string;
  style?: ViewStyle;
  onPress?: () => void;
};

export const Chip: React.FC<Prop> = ({ children, count, style, onPress }) => {
  return (
    <View
      style={[styles.container, style]}
      onTouchEnd={onPress}
    >
      {count && !isNaN(Number(count)) ? (
        <Text style={styles.count}>
          {count}
        </Text>
      ) : null}
      <Text style={styles.text}>
        {children}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 8,
    backgroundColor: theme.colors.gray,
    borderRadius: 10,
    flexDirection: 'row',
    minWidth: 100
  },
  count: {
    color: '#666666',
    fontSize: 16,
    lineHeight: 18
  },
  text: {
    color: theme.colors.white,
    fontSize: 16,
    lineHeight: 18,
    marginLeft: 4
  }
});
