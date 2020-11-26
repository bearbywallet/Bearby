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
  TouchableOpacity,
  StyleSheet
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { SvgXml } from 'react-native-svg';

import { AccountMenu } from 'app/components/account-menu';
import { ArrowIconSVG } from 'app/components/svg';
import { TransactionItem } from 'app/components/transaction-item';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { RootParamList } from 'app/navigator';
import { useStore } from 'effector-react';
import { keystore } from 'app/keystore';
import { TxStatsues } from 'app/config';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

const TEST = [
  0,
  1,
  2,
  3,
  4
];

const { width } = Dimensions.get('window');
export const HistoryPage: React.FC<Prop> = ({ navigation }) => {
  const accountsState = useStore(keystore.account.store);

  const account = React.useMemo(
    () => accountsState.identities[accountsState.selectedAddress],
    [accountsState]
  );

  const handleCreateAccount = React.useCallback(() => {
    navigation.navigate('Common', {
      screen: 'CreateAccount'
    });
  }, []);

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
        <View style={styles.sortWrapper}>
          <TouchableOpacity style={styles.sorted}>
            <Text style={styles.sortedText}>
              Status
            </Text>
            <SvgXml
              xml={ArrowIconSVG}
              fill={'#666666'}
              style={{ marginLeft: 5 }}
            />
          </TouchableOpacity>
          <TouchableOpacity style={styles.sorted}>
            <Text style={styles.sortedText}>
              Token
            </Text>
            <SvgXml
              xml={ArrowIconSVG}
              fill={'#666666'}
              style={{ marginLeft: 5 }}
            />
          </TouchableOpacity>
          <TouchableOpacity style={styles.sorted}>
            <Text style={styles.sortedText}>
              Date
            </Text>
            <SvgXml
              xml={ArrowIconSVG}
              fill={'#666666'}
              style={{ marginLeft: 5 }}
            />
          </TouchableOpacity>
        </View>
        <ScrollView style={styles.list}>
          <Text style={styles.date}>
            25.10.2020
          </Text>
          {TEST.map((tx, index) => (
            <TransactionItem
              status={TxStatsues.success}
              key={index}
            />
          ))}
        </ScrollView>
      </View>
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
  sortWrapper: {
    flexDirection: 'row',
    paddingHorizontal: 30
  },
  date: {
    fontSize: 16,
    lineHeight: 21,
    color: '#8A8A8F'
  },
  list: {
    paddingHorizontal: 15
  },
  sorted: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 15
  },
  sortedText: {
    color: theme.colors.white,
    fontSize: 13,
    lineHeight: 17
  }
});
