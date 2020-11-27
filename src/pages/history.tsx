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
  Dimensions,
  ScrollView,
  StyleSheet
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';

import { AccountMenu } from 'app/components/account-menu';
import { TransactionItem } from 'app/components/transaction-item';
import { SortingWrapper } from 'app/components/history/sort-wrapper';
import { TransactionModal } from 'app/components/modals';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { RootParamList } from 'app/navigator';
import { useStore } from 'effector-react';
import { keystore } from 'app/keystore';
import { TxStatsues } from 'app/config';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

const { width } = Dimensions.get('window');
export const HistoryPage: React.FC<Prop> = ({ navigation }) => {
  const accountsState = useStore(keystore.account.store);
  const tokensState = useStore(keystore.token.store);
  const settingsState = useStore(keystore.settings.store);
  const currencyState = useStore(keystore.currency.store);

  const [selectedToken, setSelectedToken] = React.useState(0);
  const [selectedStatus, setSelectedStatus] = React.useState(0);

  const [transactions, setTransactions] = React.useState([]);
  const [transactionModal, setTransactionModal] = React.useState(false);
  const [transactionIndex, setTransactionIndex] = React.useState(0);

  const account = React.useMemo(
    () => accountsState.identities[accountsState.selectedAddress],
    [accountsState]
  );

  const handleCreateAccount = React.useCallback(() => {
    navigation.navigate('Common', {
      screen: 'CreateAccount'
    });
  }, []);

  const showTxDetails = React.useCallback((index) => {
    setTransactionIndex(index);
    setTransactionModal(true);
  }, [setTransactionIndex, setTransactionModal]);

  React.useEffect(() => {
    // const selected = accountsState.identities[accountsState.selectedAddress];

    // keystore
    //   .viewblock
    //   .getAddress(selected.bech32)
    //   .then((info) => console.log(JSON.stringify(info, null, 4)))

    // keystore
    //   .viewblock
    //   .getTransactions(selected.bech32)
    //   .then((txns) => setTransactions(txns));
  }, [setTransactions]);

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
            onPress={() => null}
          />
        </View>
      </View>
      <View style={styles.main}>
        <SortingWrapper
          tokens={tokensState.identities}
          selectedToken={selectedToken}
          selectedStatus={selectedStatus}
          onSelectStatus={setSelectedStatus}
          onSelectToken={setSelectedToken}
        />
        <ScrollView style={styles.list}>
          <Text style={styles.date}>
            25.10.2020
          </Text>
          {transactions.map((tx, index) => (
            <TransactionItem
              transaction={tx}
              currency={currencyState}
              rate={settingsState.rate}
              tokens={tokensState.identities}
              status={TxStatsues.success}
              key={index}
              onSelect={() => showTxDetails(index)}
            />
          ))}
        </ScrollView>
      </View>
      <TransactionModal
        visible={transactionModal}
        transaction={transactions[transactionIndex]}
        onTriggered={() => setTransactionModal(false)}
      />
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
