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
  Switch,
  StyleSheet,
  ViewStyle
} from 'react-native';
import { theme } from 'app/styles';

type Prop = {
  enabled: boolean;
  style?: ViewStyle;
  onChange?: (enabled: boolean) => void;
};

/**
 * @example
 * import { Switcher } from 'app/components/switcher';
 */
export const Switcher: React.FC<Prop> = ({
  children,
  enabled,
  style,
  onChange = () => null
}) => {
  return (
    <View style={[styles.container, style]}>
      {children}
      <Switch
        style={{ marginLeft: 10 }}
        trackColor={{ false: theme.colors.muted, true: theme.colors.primary }}
        thumbColor={enabled ? theme.colors.white : theme.colors.muted}
        ios_backgroundColor="#3e3e3e"
        onValueChange={onChange}
        value={enabled}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  text: {
    color: '#8A8A8F',
    fontSize: 16,
    lineHeight: 21
  }
});
