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

import { theme } from 'app/styles';

export const CreateAccountNavBar: React.FC<SceneRendererProps> = (props) => {
  return (
    <TabBar
      {...props}
      indicatorStyle={styles.indicatorStyle}
      style={styles.bars}
    />
  );
};

const styles = StyleSheet.create({
  bars: {
    backgroundColor: 'transparent'
  },
  indicatorStyle: {
    backgroundColor: theme.colors.primary
  }
});
