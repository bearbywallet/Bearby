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
  ScrollView,
  StyleSheet
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import SafeAreaView from 'react-native-safe-area-view';

import { Selector } from 'app/components/selector';
import { Button } from 'app/components/button';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { fonts } from 'app/styles';

export const GeneralPage = () => {
  const { colors } = useTheme();
  const currencyState = keystore.currency.store.useValue();
  const themeState = keystore.theme.store.useValue();

  const hanldeReset = React.useCallback(() => {
    keystore.currency.reset();
    keystore.theme.reset();
  }, []);

  return (
    <SafeAreaView style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <View style={styles.titleWrapper}>
        <Text style={[styles.title, {
          color: colors.text
        }]}>
          {i18n.t('general_title')}
        </Text>
        <Button
          title={i18n.t('reset')}
          color={colors.primary}
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
    flex: 1
  },
  titleWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: '10%',
    paddingHorizontal: 15
  },
  title: {
    fontSize: 30,
    fontFamily: fonts.Bold
  },
  selector: {
    marginVertical: 16
  }
});

export default GeneralPage;
