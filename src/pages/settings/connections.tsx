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
  StyleSheet,
  SafeAreaView
} from 'react-native';

import { ConnectItem } from 'app/components/connect-item';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';

const items = [
  {
    domain: "ide.zilliqa.com",
    icon: "https://ide.zilliqa.com/favicon.png",
    title: "Neo Savant IDE"
  },
  {
    domain: "dragonzil.xyz",
    icon: "https://dragonzil.xyz/favicon.ico",
    title: "DragonZIL"
  },
  {
    domain: "zilflip.com",
    icon: "https://zilflip.com/play/img/favicon/favicon-16x16.png",
    title: "ZilFlip.com"
  },
  {
    domain: "d1u8g86549r102.cloudfront.net",
    icon: "https://d1u8g86549r102.cloudfront.net/favicon.png",
    title: "Snapshot"
  },
  {
    domain: "stake.zilliqa.com",
    icon: "https://stake.zilliqa.com/favicon.ico",
    title: "Zillion - Zilliqa Staking Application"
  }
];

export const ConnectionsPage = () => {

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.titleWrapper}>
        <Text style={styles.title}>
          {i18n.t('connections_title')}
        </Text>
        <Button
          title={i18n.t('connections_remove_all')}
          color={theme.colors.primary}
          onPress={() => null}
        />
      </View>
      <ScrollView style={styles.list}>
        {items.map((item, index) => (
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
  }
});

export default ConnectionsPage;
