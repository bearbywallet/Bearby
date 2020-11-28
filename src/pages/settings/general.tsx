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
  Button,
  ScrollView,
  SafeAreaView,
  StyleSheet
} from 'react-native';

import { Selector } from 'app/components/selector';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { keystore } from 'app/keystore';

export const GeneralPage = () => {
  const currencyState = keystore.currency.store.useValue();
  const themeState = keystore.theme.store.useValue();

  const hanldeReset = React.useCallback(() => {
    keystore.currency.reset();
    keystore.theme.reset();
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.titleWrapper}>
        <Text style={styles.title}>
          {i18n.t('general_title')}
        </Text>
        <Button
          title={i18n.t('reset')}
          color={theme.colors.primary}
          onPress={hanldeReset}
        />
      </View>
      <ScrollView>
        <Selector
          style={styles.selector}
          items={keystore.currency.currencies}
          selected={currencyState}
          title={i18n.t('currency')}
          onSelect={(item) => keystore.currency.set(item)}
        />
        <Selector
          style={styles.selector}
          items={keystore.theme.themes}
          selected={themeState}
          title={i18n.t('theme')}
          onSelect={(item) => keystore.theme.set(item)}
        />
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
  },
  titleWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: '10%',
    paddingHorizontal: 15
  },
  title: {
    color: theme.colors.white,
    fontSize: 34,
    lineHeight: 41,
    fontWeight: 'bold'
  },
  selector: {
    marginVertical: 16
  }
});

export default GeneralPage;
