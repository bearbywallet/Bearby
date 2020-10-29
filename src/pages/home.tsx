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
  StyleSheet,
  Text
} from 'react-native';
import { HomeAccount } from '../components/home';

import { theme } from '../styles';
import I18n from '../lib/i18n';


export const HomePage = () => {
  // const { colors } = useTheme();

  return (
    <View style={styles.container}>
      <HomeAccount />
      <View style={styles.center}>
        <View style={{
          width: '100%',
          flexDirection: 'row',
          justifyContent: 'space-between'
        }}>
          <Text>
            {I18n.t('my_tokens')}
          </Text>
          <Text>
            {I18n.t('manage')}
          </Text>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    backgroundColor: theme.colors.black
  },
  center: {
    flex: 1,
    flexDirection: 'column',
    alignItems: 'center',

    backgroundColor: theme.colors.background,

    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    padding: 16
  }
});
