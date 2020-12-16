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
  ScrollView,
  Text,
  StyleSheet
} from 'react-native';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';

type Prop = {
};

export const BrowserFavorites: React.FC<Prop> = ({}) => {
  return (
    <ScrollView style={styles.container}>
      <Text style={styles.havent}>
        {i18n.t('havent_connections')}
      </Text>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  havent: {
    fontSize: 17,
    lineHeight: 22,
    color: theme.colors.muted,
    paddingTop: 15
  },
});
