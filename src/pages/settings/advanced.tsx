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
  ScrollView
} from 'react-native';
import SafeAreaView from 'react-native-safe-area-view';
import { useTheme } from '@react-navigation/native';

import { GasSelector } from 'app/components/gas-selector';
import { Selector } from 'app/components/selector';

import { keystore } from 'app/keystore';
import i18n from 'app/lib/i18n';
import { DEFAULT_GAS } from 'app/config';

export const AdvancedPage: React.FC = () => {
  const { colors } = useTheme();
  const settingsState = keystore.settings.store.useValue();
  const gasState = keystore.gas.store.useValue();

  const hanldeReset = React.useCallback(() => {
    keystore.settings.reset();
    keystore.gas.reset();
  }, []);

  return (
    <SafeAreaView style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <View style={styles.titleWrapper}>
        <Text style={[styles.title, {
          color: colors.text
        }]}>
          {i18n.t('advanced_title')}
        </Text>
        <Button
          title={i18n.t('reset')}
          color={colors.primary}
          onPress={hanldeReset}
        />
      </View>
      <ScrollView>
        <GasSelector
          style={{ marginVertical: 16 }}
          selectedColor={colors.background}
          gasLimit={gasState.gasLimit}
          gasPrice={gasState.gasPrice}
          defaultGas={DEFAULT_GAS}
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
    fontSize: 34,
    lineHeight: 41,
    fontWeight: 'bold'
  }
});

export default AdvancedPage;
