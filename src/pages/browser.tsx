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
  SafeAreaView,
  View,
  Text,
  ScrollView,
  Dimensions,
  TextInput,
  StyleSheet
} from 'react-native';
import { SvgXml } from 'react-native-svg';

import { AccountMenu } from 'app/components/account-menu';
import { SearchIconSVG } from 'app/components/svg';

import { theme } from 'app/styles';
import { keystore } from 'app/keystore';
import i18n from 'app/lib/i18n';

const { height, width } = Dimensions.get('window');
export const BrowserPage = () => {
  const accountState = keystore.account.store.useValue();

  const account = React.useMemo(
    () => accountState.identities[accountState.selectedAddress],
    [accountState]
  );

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <AccountMenu
          accountName={account.name}
          onCreate={() => null}
        />
        <View style={styles.headerWraper}>
          <Text style={styles.headerTitle}>
            {i18n.t('browser_title')}
          </Text>
        </View>
      </View>
      <ScrollView style={styles.main}>
        <View style={styles.inputWrapper}>
          <SvgXml xml={SearchIconSVG} />
          <TextInput
            style={styles.textInput}
            placeholder={i18n.t('browser_placeholder_input')}
            placeholderTextColor="#8A8A8F"
            onChangeText={() => null}
          />
        </View>
      </ScrollView>
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
    color: theme.colors.white,
    textAlign: 'left'
  },
  headerWraper: {
    width: '100%'
  },
  main: {
    backgroundColor: theme.colors.gray,
    height: height - 100,
    borderTopEndRadius: 16,
    borderTopStartRadius: 16,
    padding: 15
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    padding: 10,
    borderBottomColor: '#8A8A8F',
    borderBottomWidth: 1,
    color: theme.colors.white,
    width: width - 60
  },
  inputWrapper: {
    width: '100%',
    flexDirection: 'row',
    alignItems: 'center'
  }
});

export default BrowserPage;
