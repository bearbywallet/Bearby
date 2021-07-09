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
  Text,
  StyleSheet,
  ScrollView
} from 'react-native';
import { useTheme } from '@react-navigation/native';

import { BrowserAppItem } from './app-item';

import i18n from 'app/lib/i18n';
import { Connect } from 'types';
import { fonts } from 'app/styles';

type Prop = {
  connections: Connect[];
  onGoConnection: (connct: Connect) => void;
};
export const BrowserFavorites: React.FC<Prop> = ({
  connections,
  onGoConnection
}) => {
  const { colors } = useTheme();

  return (
    <ScrollView style={styles.container}>
      {connections.length === 0 ? (
        <Text style={[styles.havent, {
          color: colors.notification
        }]}>
          {i18n.t('havent_connections')}
        </Text>
      ) : null}
      {connections.map((item, index) => (
        <BrowserAppItem
          key={index}
          style={{
            marginTop: 10
          }}
          title={item.title}
          icon={item.icon}
          domain={item.domain}
          onPress={() => onGoConnection(item)}
        />
      ))}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    marginBottom: 231
  },
  havent: {
    fontSize: 17,
    fontFamily: fonts.Regular,
    paddingTop: 15
  },
});
