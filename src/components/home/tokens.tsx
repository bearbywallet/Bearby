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
import SettingsStore from 'app/store/settings';

import { TokenCard } from 'app/components/token-card';

export const HomeTokens = () => {
  const tokensState = useStore(TokensStore.store);
  const settingsState = useStore(SettingsStore.store);

  const tokensList = React.useMemo(
    () => tokensState.identities.filter(
      // Filtering the only selected netwrok tokens.
      (token) => Boolean(token.address[settingsState.netwrok])
    ),
    [settingsState.netwrok]
  );

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>
          {I18n.t('my_tokens')}
        </Text>
        <Text style={styles.manage}>
          {I18n.t('manage')}
        </Text>
      </View>
      <ScrollView >
        <View style={styles.list}>
          {tokensList.map((token, index) => (
            <TokenCard
              key={index}
              token={token}
              net={settingsState.netwrok}
              rate={settingsState.rate}
              selected={index === tokensState.selected}
              style={styles.token}
              onSelect={() => TokensStore.selectToken(index)}
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
    justifyContent: 'space-around',
    alignItems: 'center'
  },
  token: {
    marginTop: 16
  },
  title: {
    color: theme.colors.white,
    fontSize: 20
  },
  manage: {
    color: theme.colors.primary,
    fontSize: 20
  }
});
