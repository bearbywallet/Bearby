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
import { useTheme } from '@react-navigation/native';

import { BrowserCarditem } from 'app/components/browser';

import i18n from 'app/lib/i18n';
import { fonts } from 'app/styles';

type Prop = {
  onSelect: (name: number) => void;
};
export const categories = [
  0,
  1,
  2,
  3,
  4,
  5
];

export const BrowserApps: React.FC<Prop> = ({ onSelect }) => {
  const { colors } = useTheme();

  return (
    <ScrollView style={styles.container}>
      <Text style={[styles.namePlace, {
        color: colors.notification
      }]}>
        {i18n.t('categories')}
      </Text>
      <View style={styles.categoriesWrapper}>
        {categories.map((_, index) => (
          <BrowserCarditem
            style={{ marginTop: 15 }}
            key={index}
            el={index}
            title={i18n.t(`category_${index}`)}
            onPress={() => onSelect(index)}
          />
        ))}
      </View>
      {/* <Text style={styles.namePlace}>
        {i18n.t('top_aaps')}
      </Text> */}
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
    justifyContent: 'space-around',
    paddingVertical: 10
  },
  namePlace: {
    paddingTop: 15,
    fontFamily: fonts.Regular,
    fontSize: 17
  }
});
