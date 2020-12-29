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
  TouchableOpacity,
  Text,
  StyleSheet,
  Dimensions,
  ViewStyle
} from 'react-native';

type Prop = {
  count?: number | string;
  style?: ViewStyle;
  onPress?: () => void;
};

const { width } = Dimensions.get('window');
export const Chip: React.FC<Prop> = ({ children, count, style, onPress }) => {
  const { colors } = useTheme();

  return (
    <TouchableOpacity
      style={[styles.container, {
        backgroundColor: colors.card
      }, style]}
      onPress={onPress}
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
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: (width / 100) * 1,
    borderRadius: 10,
    flexDirection: 'row',
    minWidth: (width / 100) * 17
  },
  count: {
    fontSize: (width / 100) * 4,
    lineHeight: 18
  },
  text: {
    fontSize: (width / 100) * 3,
    lineHeight: 18,
    marginLeft: 4
  }
});
