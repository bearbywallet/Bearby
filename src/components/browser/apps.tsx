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
  StyleSheet
} from 'react-native';

import { BrowserCarditem } from 'app/components/browser';

import i18n from 'app/lib/i18n';

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
  return (
    <ScrollView
      style={styles.container}
      showsVerticalScrollIndicator={false}
    >
      <View style={styles.categoriesWrapper}>
        {categories.map((el) => (
          <BrowserCarditem
            style={{ marginTop: 15 }}
            key={el}
            el={el}
            title={i18n.t(`category_${el}`)}
            onPress={() => onSelect(el)}
          />
        ))}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 100,
    marginBottom: 225
  },
  categoriesWrapper: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    paddingVertical: 10,
    paddingHorizontal: 10
  }
});
