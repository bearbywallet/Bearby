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
  Dimensions,
  ScrollView
} from 'react-native';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';

import { TokenCard } from 'app/components/token-card';
import { AddToken } from 'app/components/add-token';
import { SimpleConfirm } from 'app/components/modals';

import { keystore } from 'app/keystore';
import { Token } from 'types';

type Prop = {
  onSelectToken: (index: number) => void;
};

const { width, height } = Dimensions.get('window');
export const HomeTokens: React.FC<Prop> = ({ onSelectToken }) => {
  const settingsState = keystore.settings.store.useValue();
  const currencyState = keystore.currency.store.useValue();
  const netwrokState = keystore.network.store.useValue();
  const accountState = keystore.account.store.useValue();
  const tokens = keystore.token.store.useValue();

  const [tokenForRemove, setTokenForRemove] = React.useState<Token>();
  const [isRemove, setIsRemove] = React.useState(false);

  const tokensList = React.useMemo(
    () => tokens.filter(
      // Filtering the only selected netwrok tokens.
      (token) => Boolean(token.address[netwrokState.selected] && token.symbol !== 'ZIL')
    ),
    [tokens, netwrokState.selected]
  );
  const account = React.useMemo(
    () => accountState.identities[accountState.selectedAddress],
    [accountState]
  );
  const hasNonDefault = React.useMemo(
    () => tokensList.filter((t) => !t.default).length > 0,
    [tokensList]
  );

  const hanldeAddtoken = React.useCallback(async(token, cb) => {
    try {
      await keystore.token.addToken(token);

      cb();
    } catch {
      //
    }
  }, []);
  const hanldeRemoveToken = React.useCallback(async() => {
    if (tokenForRemove) {
      await keystore.token.removeToken(tokenForRemove);
    }

    setTokenForRemove(undefined);
  }, [tokenForRemove, setTokenForRemove]);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>
          {i18n.t('my_tokens')}
        </Text>
        {hasNonDefault ? (
          <Button
            title={i18n.t('manage')}
            color={theme.colors.primary}
            onPress={() => setIsRemove(!isRemove)}
          />
        ) : null}
      </View>
        <View style={styles.list}>
          {tokensList.map((token, index) => (
            <TokenCard
              key={index}
              account={account}
              canRemove={isRemove}
              token={token}
              currency={currencyState}
              net={netwrokState.selected}
              rate={settingsState.rate[currencyState]}
              style={styles.token}
              onPress={() => onSelectToken(index + 1)}
              onRemove={setTokenForRemove}
            />
          ))}
          <AddToken
            style={styles.token}
            account={account}
            onAddToken={hanldeAddtoken}
          />
        </View>
        <SimpleConfirm
          visible={Boolean(tokenForRemove)}
          title={i18n.t('remove_token', { name: tokenForRemove?.symbol })}
          btns={[i18n.t('reject'), i18n.t('confirm')]}
          description={i18n.t('remove_token_description')}
          onTriggered={() => setTokenForRemove(undefined)}
          onConfirmed={hanldeRemoveToken}
        />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 2,
    flexDirection: 'column',
    alignItems: 'center',

    backgroundColor: theme.colors.background,
    minHeight: height / 1.7,
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
    width: width - 32,
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
