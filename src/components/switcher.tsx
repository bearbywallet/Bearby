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
  Switch,
  StyleSheet,
  ViewStyle
} from 'react-native';
import { useTheme } from '@react-navigation/native';

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
  const { colors } = useTheme();

  return (
    <View style={[styles.container, style]}>
      {children}
      <Switch
        style={{ marginLeft: 10 }}
        trackColor={{ false: colors.notification, true: colors.primary }}
        thumbColor={colors.background}
        ios_backgroundColor={colors.text}
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
  }
});
