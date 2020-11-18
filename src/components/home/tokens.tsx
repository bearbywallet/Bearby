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
  Button,
  ScrollView
} from 'react-native';

import I18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { useStore } from 'effector-react';

import { TokenCard } from 'app/components/token-card';
import { AddToken } from 'app/components/add-token';

import { keystore } from 'app/keystore';

export const HomeTokens: React.FC = () => {
  const tokensState = useStore(keystore.token.store);
  const settingsState = useStore(keystore.settings.store);
  const netwrokState = useStore(keystore.network.store);

  const tokensList = React.useMemo(
    () => tokensState.identities.filter(
      // Filtering the only selected netwrok tokens.
      (token) => Boolean(token.address[netwrokState.selected] && token.symbol !== 'ZIL')
    ),
    [netwrokState.selected]
  );

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>
          {I18n.t('my_tokens')}
        </Text>
        <Button
          title={I18n.t('manage')}
          color={theme.colors.primary}
          onPress={() => null}
        />
      </View>
      <ScrollView>
        <View style={styles.list}>
          {tokensList.map((token, index) => (
            <TokenCard
              key={index}
              token={token}
              net={'mainnet'}
              rate={settingsState.rate}
              style={styles.token}
            />
          ))}
          <AddToken style={styles.token}/>
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
    justifyContent: 'space-between'
  },
  token: {
    marginTop: 16
  },
  title: {
    color: theme.colors.white,
    fontSize: 20
  }
});
