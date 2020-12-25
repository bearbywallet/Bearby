/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import { StyleSheet } from 'react-native';
import { TabBar, SceneRendererProps } from 'react-native-tab-view';
import { useTheme } from '@react-navigation/native';

export const CreateAccountNavBar: React.FC<SceneRendererProps> = (props) => {
  const { colors } = useTheme();

  return (
    <TabBar
      {...props}
      indicatorStyle={{
        backgroundColor: colors.primary
      }}
      labelStyle={{
        color: colors.text
      }}
      style={styles.bars}
    />
  );
};

const styles = StyleSheet.create({
  bars: {
    backgroundColor: 'transparent'
  }
});
