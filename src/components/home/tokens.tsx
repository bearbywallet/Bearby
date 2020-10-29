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
import I18n from '../../lib/i18n';
import { theme } from '../../styles';

export const HomeTokens = () => {
  return (
    <View style={styles.container}>
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
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    alignItems: 'center',

    backgroundColor: theme.colors.background,

    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    padding: 16
  }
});
