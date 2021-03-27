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
import { useTheme } from '@react-navigation/native';

import { TransactionItem } from 'app/components/transaction-item';
import { TransactionModal } from 'app/components/modals';
import { Button } from 'app/components/button';

import i18n from 'app/lib/i18n';
import { RootParamList } from 'app/navigator';
import { keystore } from 'app/keystore';
import { TxStatsues } from 'app/config';
import { StoredTx } from 'types';

import ZIlliqaLogo from 'app/assets/zilliqa.svg';
import { fonts } from 'app/styles';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

const { width } = Dimensions.get('window');
export const HistoryPage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();
  const tokensState = keystore.token.store.useValue();
  const settingsState = keystore.settings.store.useValue();
  const ssnState = keystore.ssn.store.useValue();
  const currencyState = keystore.currency.store.useValue();
  const transactionState = keystore.transaction.store.useValue();
  const networkState = keystore.network.store.useValue();

  const [transactionModal, setTransactionModal] = React.useState(false);
  const [transaction, setTransaction] = React.useState<null | StoredTx>();

  const [refreshing, setRefreshing] = React.useState(false);

  const dateTransactions = React.useMemo(() => {
    let lasDate: Date | null = null;

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
    });
  }, [
    transactionState,
    networkState,
    tokensState
  ]);
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
        `${ssnState.selected}: ${err.message}`,
        [
          { text: "OK" }
        ]
      );
    }
  }, [ssnState]);
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
          data={dateTransactions}
          renderItem={({ item }) => (
            <React.Fragment>
              {item.date ? (
                 <Text style={[styles.date, {
                  color: colors.border
                 }]}>
                  {new Date(item.tx.timestamp).toDateString()}
                </Text>
              ) : null}
              <TransactionItem
                transaction={item.tx}
                netwrok={networkState.selected}
                currency={currencyState}
                settings={settingsState}
                tokens={tokensState}
                status={TxStatsues.success}
                onSelect={() => showTxDetails(item.tx)}
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
          ListEmptyComponent={() => (
            <Text
              style={[styles.noTxns, {
                color: colors.border
              }]}
            >
              {i18n.t('havent_txns')}
            </Text>
          )}
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
    top: -120,
    right: -30
  },
  noTxns: {
    fontFamily: fonts.Demi,
    fontSize: 16,
    padding: 16
  }
});
