/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import { StyleSheet, Text } from 'react-native';
import { TabBar, SceneRendererProps } from 'react-native-tab-view';
import { useTheme } from '@react-navigation/native';
import { fonts } from 'app/styles';

export const CreateAccountNavBar: React.FC<SceneRendererProps> = (props: SceneRendererProps) => {
  const { colors } = useTheme();

  return (
    <TabBar
      {...props}
      navigationState={props['navigationState']}
      indicatorStyle={{
        backgroundColor: colors.primary
      }}
      renderLabel={({ route }) => (
        <Text style={[styles.tabTitle, {
          color: colors.text
        }]}>
          {route.title}
        </Text>
      )}
      style={styles.bars}
    />
  );
};

const styles = StyleSheet.create({
  bars: {
    backgroundColor: 'transparent'
  },
  tabTitle: {
    textAlign: 'center',
    fontFamily: fonts.Demi,
    fontSize: 16
  }
});
