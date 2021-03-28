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
  StatusBar,
  StyleSheet,
  ViewProps,
  SafeAreaView as SafeAreaViewIOS
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Device } from 'app/utils';

export const SafeWrapper: React.FC<ViewProps> = ({
  children,
  ...props
}) => {
  const { colors } = useTheme();

  if (Device.isIos()) {
    return (
      <SafeAreaViewIOS
        style={[styles.container, {
          backgroundColor: colors.background
        }]}
        {...props}
      >
        {children}
      </SafeAreaViewIOS>
    );
  }

  return (
    <View
      style={[styles.container, {
        backgroundColor: colors.background
      }]}
      {...props}
    >
      <View style={{
        height: StatusBar.currentHeight
      }}/>
      {children}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  }
});
