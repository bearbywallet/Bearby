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
  TouchableOpacity,
  StyleSheet
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import FastImage from 'react-native-fast-image';

import { BrowserCarditem } from 'app/components/browser';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { PINTA } from 'app/config';

type Prop = {
  onSelect: (name: number) => void;
  onBanner: (url: string) => void;
};
export const categories = [
  0,
  1,
  2,
  3,
  4,
  5
];

export const BrowserApps: React.FC<Prop> = ({ onSelect, onBanner }) => {
  const { colors } = useTheme();
  const browserState = keystore.app.store.useValue();
  const [loading, setLoading] = React.useState(true);

  // getBanners

  React.useEffect(() => {
    setLoading(true);
    keystore
      .app
      .getBanners()
      .finally(() => setLoading(false));
  }, []);

  return (
    <ScrollView style={styles.container}>
      {!loading && browserState ? (
        <TouchableOpacity onPress={() => onBanner(browserState.url)}>
          <FastImage
            source={{
              uri: `${PINTA}/${browserState.banner}`
            }}
            style={styles.banner}
          />
        </TouchableOpacity>
      ) : null}
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
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  banner: {
    marginTop: 16,
    borderRadius: 8,
    height: 100,
    width: '100%'
  },
  categoriesWrapper: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-around',
    paddingVertical: 10
  }
});
