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
  ScrollView,
  SafeAreaView
} from 'react-native';

import { GasSelector } from 'app/components/gas-selector';
import { Selector } from 'app/components/selector';

import { theme } from 'app/styles';
import { keystore } from 'app/keystore';
import i18n from 'app/lib/i18n';

export const AdvancedPage = () => {
  const settingsState = keystore.settings.store.useValue();
  const gasState = keystore.gas.store.useValue();

  const hanldeReset = React.useCallback(() => {
    keystore.settings.reset();
    keystore.gas.reset();
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.titleWrapper}>
        <Text style={styles.title}>
          {i18n.t('advanced_title')}
        </Text>
        <Button
          title={i18n.t('reset')}
          color={theme.colors.primary}
          onPress={hanldeReset}
        />
      </View>
      <ScrollView>
        <GasSelector
          style={{ marginVertical: 16 }}
          gasLimit={gasState.gasLimit}
          gasPrice={gasState.gasPrice}
          onChange={(gas) => keystore.gas.changeGas(gas)}
        />
        <Selector
          style={{ marginVertical: 16 }}
          title={i18n.t('advanced_selector_title')}
          items={keystore.settings.formats}
          selected={settingsState.addressFormat}
          onSelect={(format) => keystore.settings.setFormat(format)}
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
  }
});

export default AdvancedPage;
