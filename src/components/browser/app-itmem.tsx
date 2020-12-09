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
  TouchableOpacity,
  StyleSheet,
  Dimensions,
  ViewStyle
} from 'react-native';
import { theme } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  title: string;
  onPress?: () => void;
};

const { width } = Dimensions.get('window');
export const BrowserAppItem: React.FC<Prop> = ({ title, style, onPress }) => {
  return (
    <TouchableOpacity
      style={[styles.container, style]}
      onPress={onPress}
    >
      <Text style={styles.title}>
        {title}
      </Text>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 10,
    minHeight: width / 5,
    borderRadius: 8,
    backgroundColor: theme.colors.gray,
    justifyContent: 'flex-end'
  },
  title: {
    fontSize: 17,
    lineHeight: 22,
    color: theme.colors.white
  }
});
