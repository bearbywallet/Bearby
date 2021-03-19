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
  FlatList,
  Dimensions,
  RefreshControl,
  Alert,
  StyleSheet
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { RouteProp, useTheme } from '@react-navigation/native';

import { AccountMenu } from 'app/components/account-menu';
import { TransactionItem } from 'app/components/transaction-item';
import { TransactionModal } from 'app/components/modals';
import { Button } from 'app/components/button';

import i18n from 'app/lib/i18n';
import { RootParamList } from 'app/navigator';
import { TabStackParamList } from 'app/navigator/tab-navigator';
import { keystore } from 'app/keystore';
import { TxStatsues, ZILLIQA_KEYS, TokenTypes } from 'app/config';
import { toBech32Address } from 'app/utils';
import { StoredTx } from 'types';

import ZIlliqaLogo from 'app/assets/zilliqa.svg';
import { fonts } from 'app/styles';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

const { width } = Dimensions.get('window');
export const HistoryPage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();
  const accountState = keystore.account.store.useValue();
  const tokensState = keystore.token.store.useValue();
  const settingsState = keystore.settings.store.useValue();
  const currencyState = keystore.currency.store.useValue();
  const transactionState = keystore.transaction.store.useValue();
  const networkState = keystore.network.store.useValue();

  const [transactionModal, setTransactionModal] = React.useState(false);
  const [transaction, setTransaction] = React.useState<null | StoredTx>();

  const [refreshing, setRefreshing] = React.useState(false);

  const account = React.useMemo(
    () => accountState.identities[accountState.selectedAddress],
    [accountState]
  );

  const handleCreateAccount = React.useCallback(() => {
    navigation.navigate('Common', {
      screen: 'CreateAccount'
    });
  }, []);

  const showTxDetails = React.useCallback((tx) => {
    setTransaction(tx);
    setTransactionModal(true);
  }, [setTransaction, setTransactionModal]);

  const hanldeRefresh = React.useCallback(async() => {
    setRefreshing(true);
    try {
      await keystore.transaction.checkProcessedTx();
      setRefreshing(false);
    } catch (err) {
      setRefreshing(false);
      Alert.alert(
        i18n.t('update'),
        err.message,
        [
          { text: "OK" }
        ]
      );
    }
  }, [setRefreshing]);
  const hanldeViewBlock = React.useCallback((url: string) => {
    navigation.navigate('Browser', {
      screen: 'Web',
      params: {
        url
      }
    });
    setTransactionModal(false);
  }, [navigation]);

  return (
    <View style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <View style={styles.header}>
        <ZIlliqaLogo
          style={[StyleSheet.absoluteFill, styles.logo]}
          width={width}
          height={width}
        />
        <AccountMenu
          accountName={account.name}
          onCreate={handleCreateAccount}
        />
        <View style={styles.headerWraper}>
          <Text style={[styles.headerTitle, {
            color: colors.text
          }]}>
            {i18n.t('history')}
          </Text>
          <Button
            title={i18n.t('history_btn0')}
            color={colors.primary}
            onPress={() => keystore.transaction.reset()}
          />
        </View>
      </View>
      <View style={[styles.main, {
        backgroundColor: colors.card
      }]}>
        <FlatList
          data={transactionState}
          renderItem={(data) => (
            <React.Fragment>
              <Text style={[styles.date, {
                color: colors.border
              }]}>
                {new Date(data.item.timestamp).toDateString()}
              </Text>
              <TransactionItem
                transaction={data.item}
                netwrok={networkState.selected}
                currency={currencyState}
                settings={settingsState}
                tokens={tokensState}
                status={TxStatsues.success}
                onSelect={() => showTxDetails(data.item)}
              />
            </React.Fragment>
          )}
          refreshControl={
            <RefreshControl
                refreshing={refreshing}
                tintColor={colors.primary}
                onRefresh={hanldeRefresh}
            />
          }
          keyExtractor={(_, index) => String(index)}
        />
      </View>
      {transaction ? (
        <TransactionModal
          visible={transactionModal}
          transaction={transaction}
          onViewBlock={hanldeViewBlock}
          onTriggered={() => setTransactionModal(false)}
        />
      ) : null}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  header: {
    alignItems: 'center',
    marginTop: '5%',
    padding: 15
  },
  headerTitle: {
    fontSize: 30,
    fontFamily: fonts.Bold
  },
  headerWraper: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    width: width - 30
  },
  main: {
    flex: 1,
    borderTopEndRadius: 16,
    borderTopStartRadius: 16,
    paddingTop: 16
  },
  date: {
    fontSize: 13,
    fontFamily: fonts.Regular,
    lineHeight: 21,
    paddingLeft: 5
  },
  list: {
    paddingHorizontal: 15
  },
  logo: {
    top: -150,
    right: -30
  }
});
