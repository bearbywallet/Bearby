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
import FastImage from 'react-native-fast-image';
import { useTheme } from '@react-navigation/native';

import { BrowserCarditem } from 'app/components/browser';

import i18n from 'app/lib/i18n';
import { Device } from 'app/utils';

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
  // const browserState = keystore.app.store.useValue();

  // const handleBanner = React.useCallback(() => {
  //   if (browserState?.url) {
  //     onBanner(browserState?.url);
  //   }
  // }, [browserState]);

  return (
    <ScrollView style={styles.container}>
      {/* <TouchableOpacity onPress={handleBanner}>
        <FastImage
          source={{
            uri: `${ipfsURL}/${String(browserState?.banner)}`
          }}
          style={[styles.banner, {
            backgroundColor: colors['card1']
          }]}
        />
      </TouchableOpacity> */}
      {Device.isIos() ? null : (
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
      )}
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
    justifyContent: 'space-between',
    paddingVertical: 10,
    paddingHorizontal: 10
  }
});
