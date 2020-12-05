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
  SafeAreaView,
  Text,
  Button,
  FlatList,
  Dimensions,
  RefreshControl,
  StyleSheet
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { RouteProp } from '@react-navigation/native';

import { AccountMenu } from 'app/components/account-menu';
import { TransactionItem } from 'app/components/transaction-item';
import { SortingWrapper } from 'app/components/history/sort-wrapper';
import { TransactionModal } from 'app/components/modals';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { RootParamList } from 'app/navigator';
import { TabStackParamList } from 'app/navigator/tab-navigator';
import { keystore } from 'app/keystore';
import { TxStatsues, ZILLIQA_KEYS } from 'app/config';
import { toBech32Address } from 'app/utils';
import { Transaction } from 'types';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
  route: RouteProp<TabStackParamList, 'History'>;
};

const { width } = Dimensions.get('window');
export const HistoryPage: React.FC<Prop> = ({ navigation, route }) => {
  const accountState = keystore.account.store.useValue();
  const tokensState = keystore.token.store.useValue();
  const settingsState = keystore.settings.store.useValue();
  const currencyState = keystore.currency.store.useValue();
  const transactionState = keystore.transaction.store.useValue();
  const networkState = keystore.network.store.useValue();

  const [selectedToken, setSelectedToken] = React.useState(
    route.params?.tokenIndex || 0
  );
  const [selectedStatus, setSelectedStatus] = React.useState(0);

  const [isDate, setIsDate] = React.useState(false);

  const [transactionModal, setTransactionModal] = React.useState(false);
  const [transaction, setTransaction] = React.useState<null | Transaction>();

  const [refreshing, setRefreshing] = React.useState(false);

  const account = React.useMemo(
    () => accountState.identities[accountState.selectedAddress],
    [accountState]
  );
  const cusstomTokens = React.useMemo(() => {
    const cusstomToken = {
      address: {
        [ZILLIQA_KEYS[0]]: '',
        [ZILLIQA_KEYS[1]]: '',
        [ZILLIQA_KEYS[2]]: ''
      },
      decimals: 0,
      name: 'All',
      symbol: ''
    };
    return [cusstomToken, ...tokensState.identities];
  }, [tokensState]);

  const dateTransactions = React.useMemo(() => {
    let lasDate: Date | null = null;
    let tokenAddress: string;
    const [zilliqa] = tokensState.identities;
    const token = cusstomTokens[selectedToken];

    if (token && selectedToken !== 0) {
      tokenAddress = toBech32Address(token.address[networkState.selected]);
    }

    return transactionState.map((tx) => {
      let date: Date | null = new Date(tx.timestamp);

      if (!lasDate) {
        lasDate = date;
      } else if (lasDate.getDay() >= date.getDay()) {
        date = null;
      } else if (lasDate.getDay() < date.getDay()) {
        lasDate = date;
      }

      return {
        tx,
        date
      };
    }).filter(({ tx }) => {
      switch (selectedStatus) {
        case 1:
          return tx.receiptSuccess === null;
        case 2:
          return !tx.receiptSuccess;
        case 3:
          return tx.receiptSuccess;
        default:
          break;
      }

      return true;
    }).filter(({ tx }) => {
      if (!tokenAddress || selectedToken === 0) {
        return true;
      }

      if (token.symbol === zilliqa.symbol && !tx.data) {
        return true;
      }

      return tokenAddress === tx.to;
    }).sort((a, b) => {
      if (isDate && a.tx.timestamp < b.tx.timestamp) {
        return -1;
      }

      return 1;
    });
  }, [
    isDate,
    transactionState,
    selectedStatus,
    selectedToken,
    networkState,
    tokensState,
    cusstomTokens
  ]);

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
    await keystore.transaction.forceUpdate();
    setRefreshing(false);
  }, [setRefreshing]);

  React.useEffect(() => {
    keystore.transaction.sync();
  }, []);
  React.useEffect(() => {
    if (route.params && route.params.tokenIndex) {
      setSelectedToken(route.params.tokenIndex + 1);
    }
  }, [setSelectedToken, route.params]);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <AccountMenu
          accountName={account.name}
          onCreate={handleCreateAccount}
        />
        <View style={styles.headerWraper}>
          <Text style={styles.headerTitle}>
            {i18n.t('history')}
          </Text>
          <Button
            title={i18n.t('history_btn0')}
            color={theme.colors.primary}
            onPress={() => keystore.transaction.reset()}
          />
        </View>
      </View>
      <View style={styles.main}>
        <SortingWrapper
          tokens={cusstomTokens}
          account={account}
          isDate={isDate}
          selectedToken={selectedToken}
          selectedStatus={selectedStatus}
          onSelectStatus={setSelectedStatus}
          onSelectToken={setSelectedToken}
          onSelectDate={setIsDate}
        />
        <FlatList
          data={dateTransactions}
          renderItem={({ item }) => (
            <React.Fragment>
              {item.date ? (
                 <Text style={styles.date}>
                  {item.date.toDateString()}
                </Text>
              ) : null}
              <TransactionItem
                transaction={item.tx}
                currency={currencyState}
                rate={settingsState.rate[currencyState]}
                tokens={tokensState.identities}
                status={TxStatsues.success}
                onSelect={() => showTxDetails(item.tx)}
              />
            </React.Fragment>
          )}
          refreshControl={
            <RefreshControl
                refreshing={refreshing}
                tintColor={theme.colors.primary}
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
          onTriggered={() => setTransactionModal(false)}
        />
      ) : null}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
  },
  header: {
    alignItems: 'center',
    padding: 15,
    paddingBottom: 30
  },
  headerTitle: {
    fontSize: 34,
    lineHeight: 41,
    fontWeight: 'bold',
    color: theme.colors.white
  },
  headerWraper: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: width - 30
  },
  main: {
    flex: 1,
    borderTopEndRadius: 16,
    borderTopStartRadius: 16,
    backgroundColor: '#18191D'
  },
  date: {
    fontSize: 16,
    lineHeight: 21,
    color: '#8A8A8F'
  },
  list: {
    paddingHorizontal: 15
  }
});
