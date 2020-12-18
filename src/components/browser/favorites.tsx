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

import { BrowserAppItem } from './app-item';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { Connect } from 'types';

type Prop = {
  connections: Connect[];
  onGoConnection: (connct: Connect) => void;
};

export const BrowserFavorites: React.FC<Prop> = ({ connections, onGoConnection }) => {
  return (
    <ScrollView style={styles.container}>
      {connections.length === 0 ? (
        <Text style={styles.havent}>
          {i18n.t('havent_connections')}
        </Text>
      ) : null}
      {connections.map((c, index) => (
        <BrowserAppItem
          key={index}
          style={{
            marginTop: 15
          }}
          title={c.title}
          icon={c.icon}
          domain={c.domain}
          onPress={() => onGoConnection(c)}
        />
      ))}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingHorizontal: 15
  },
  havent: {
    fontSize: 17,
    lineHeight: 22,
    color: theme.colors.muted,
    paddingTop: 15
  },
});
