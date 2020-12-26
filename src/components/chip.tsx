/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { useTheme } from '@react-navigation/native';
import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  ViewStyle
} from 'react-native';

type Prop = {
  count?: number | string;
  style?: ViewStyle;
  onPress?: () => void;
};

export const Chip: React.FC<Prop> = ({ children, count, style, onPress }) => {
  const { colors } = useTheme();

  return (
    <View
      style={[styles.container, {
        backgroundColor: colors.card
      }, style]}
      onTouchEnd={onPress}
    >
      {count && !isNaN(Number(count)) ? (
        <Text style={[styles.count, {
          color: colors.notification
        }]}>
          {count}
        </Text>
      ) : null}
      <Text style={[styles.text, {
        color: colors.text
      }]}>
        {children}
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 8,
    borderRadius: 10,
    flexDirection: 'row',
    minWidth: 100
  },
  count: {
    fontSize: 16,
    lineHeight: 18
  },
  text: {
    fontSize: 16,
    lineHeight: 18,
    marginLeft: 4
  }
});
