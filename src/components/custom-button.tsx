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
  Text,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  ViewStyle
} from 'react-native';
import { theme } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  title: string;
  color?: string;
  disabled?: boolean;
  isLoading?: boolean;
  onPress?: () => void;
};

export const CustomButton: React.FC<Prop> = ({
  title,
  disabled,
  style,
  color,
  isLoading = false,
  onPress = () => null
}) => {
  return (
    <TouchableOpacity
      style={[styles.container, style, {
        opacity: (disabled || isLoading) ? 0.5 : 1
      }]}
      disabled={disabled || isLoading}
      onPress={onPress}
    >
      {isLoading ? (
        <ActivityIndicator
          animating={isLoading}
          color={theme.colors.black}
        />
      ) : (
        <Text style={[styles.text, { color }]}>
          {title}
        </Text>
      )}
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 8,
    paddingVertical: 11,
    borderRadius: 8,
    backgroundColor: theme.colors.primary,
    alignItems: 'center'
  },
  text: {
    color: theme.colors.black,
    fontSize: 17,
    lineHeight: 22
  }
});
