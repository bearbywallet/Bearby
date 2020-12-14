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
  ScrollView,
  Text,
  StyleSheet
} from 'react-native';

import { BrowserCarditem, BrowserAppItem } from 'app/components/browser';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';

type Prop = {
};
export const categories = [
  'games',
  'finance',
  'social',
  'high_risk',
  'exchanges',
  'gambling'
];

const topAps = [
  'DragonZIL',
  'Stake',
  'SocialPay'
];

export const BrowserApps: React.FC<Prop> = ({}) => {
  return (
    <ScrollView style={styles.container}>
      <Text style={styles.namePlace}>
        {i18n.t('categories')}
      </Text>
      <View style={styles.categoriesWrapper}>
        {categories.map((c, index) => (
          <BrowserCarditem
            style={{ marginTop: 15 }}
            key={index}
            el={c}
            title={i18n.t(c)}
          />
        ))}
      </View>
      <Text style={styles.namePlace}>
        {i18n.t('top_aaps')}
      </Text>
      <View style={{
        paddingHorizontal: 15,
        paddingBottom: 120
      }}>
        {topAps.map((app, index) => (
          <BrowserAppItem
            style={{ marginTop: 15 }}
            key={index}
            title={app}
          />
        ))}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  categoriesWrapper: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-around'
  },
  namePlace: {
    paddingTop: 15,
    fontWeight: 'bold',
    fontSize: 17,
    lineHeight: 22,
    color: theme.colors.muted
  }
});
