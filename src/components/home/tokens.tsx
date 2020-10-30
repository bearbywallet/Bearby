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
  StyleSheet,
  Text,
  ScrollView
} from 'react-native';
import I18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { useStore } from 'effector-react';

import TokensStore from 'app/store/tokens';

import { TokenCard } from 'app/components/token-card';

export const HomeTokens = () => {
  const tokensState = useStore(TokensStore.store);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text>
          {I18n.t('my_tokens')}
        </Text>
        <Text>
          {I18n.t('manage')}
        </Text>
      </View>
      <ScrollView >
        <View style={styles.list}>
          {tokensState.map((token, index) => (
            <TokenCard
              key={index}
              token={token}
              style={styles.token}
            />
          ))}
        </View>
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    alignItems: 'center',

    backgroundColor: theme.colors.background,

    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    padding: 16
  },
  header: {
    width: '100%',
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  list: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  token: {
    marginTop: 16
  }
});
