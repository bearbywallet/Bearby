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
  Text,
  Button,
  ScrollView,
  StyleSheet
} from 'react-native';
import SafeAreaView from 'react-native-safe-area-view';

import { ConnectItem } from 'app/components/connect-item';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';

export const ConnectionsPage = () => {
  const connectState = keystore.connect.store.useValue();

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.titleWrapper}>
        <Text style={styles.title}>
          {i18n.t('connections_title')}
        </Text>
        <Button
          title={i18n.t('connections_remove_all')}
          color={theme.colors.primary}
          onPress={() => keystore.connect.reset()}
        />
      </View>
      <ScrollView style={styles.list}>
        {connectState.length === 0 ? (
          <Text style={styles.noConnect}>
            {i18n.t('havent_connections')}
          </Text>
        ) : null}
        {connectState.map((item, index) => (
          <ConnectItem
            key={index}
            connect={item}
          />
        ))}
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: theme.colors.black,
    flex: 1
  },
  titleWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: '10%',
    paddingHorizontal: 15
  },
  title: {
    color: theme.colors.white,
    fontSize: 34,
    lineHeight: 41,
    fontWeight: 'bold'
  },
  list: {
    backgroundColor: theme.colors.black,
    marginTop: 16
  },
  noConnect: {
    color: theme.colors.muted,
    fontSize: 17,
    lineHeight: 22,
    paddingLeft: 15
  }
});

export default ConnectionsPage;
