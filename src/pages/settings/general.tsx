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

import { Selector } from 'app/components/selector';
import { Button } from 'app/components/button';
import { Switcher } from 'app/components/switcher';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { fonts } from 'app/styles';
import { DropMenu } from 'app/components/drop-menu';


export const GeneralPage = () => {
  const { colors } = useTheme();
  const currencyState = keystore.currency.store.useValue();
  const settingsState = keystore.settings.store.useValue();
  const themeState = keystore.theme.store.useValue();
  const notificationState = keystore.notificationManager.store.useValue();

  const currencyList = React.useMemo(() => {
    return Object.keys(settingsState.rate).map((key) => ({
      name: key.toUpperCase(),
      value: `${settingsState.rate[key]} ZIL`
    }));
  }, [settingsState]);

  const hanldeReset = React.useCallback(() => {
    keystore.currency.reset();
    keystore.theme.reset();
    keystore.notificationManager.reset();
    keystore.settings.rateUpdate();
  }, []);
  const hanldeToggleNotification = React.useCallback(() => {
    keystore.notificationManager.toggleNotification();
  }, [notificationState]);

  const hanldeSelectedCurrency = React.useCallback(async(item) => {
    const newCurrency = String(item.name).toLowerCase();

    if (settingsState.rate[newCurrency]) {
      keystore.currency.set(newCurrency);
    }
  }, [settingsState]);

  return (
    <React.Fragment>
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
      <ScrollView style={styles.list}>
        <DropMenu
          selected={{
            name: String(currencyState).toUpperCase()
          }}
          title={i18n.t('currency')}
          list={currencyList}
          onUpdate={() => keystore.settings.rateUpdate()}
          onSelect={hanldeSelectedCurrency}
        />
        <Selector
          style={styles.selector}
          items={keystore.theme.themes}
          selected={themeState}
          title={i18n.t('theme')}
          onSelect={(item) => keystore.theme.set(item)}
        />
        <Switcher
          style={{
            backgroundColor: colors.card,
            padding: 15
          }}
          enabled={notificationState.enabled}
          onChange={hanldeToggleNotification}
        >
          <View style={styles.switcherWrapper}>
            <Text style={[styles.someText, {
              color: colors.text
            }]}>
              {i18n.t('notification')}
            </Text>
            <Text style={[styles.someLable, {
              color: colors.border
            }]}>
              {i18n.t('notification_des')}
            </Text>
          </View>
        </Switcher>
      </ScrollView>
    </React.Fragment>
  );
};

const styles = StyleSheet.create({
  list: {
    paddingBottom: 100,
    paddingTop: 30
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
  },
  someLable: {
    fontSize: 16,
    fontFamily: fonts.Regular
  },
  someText: {
    fontSize: 17,
    fontFamily: fonts.Demi
  },
  switcherWrapper: {
    maxWidth: '70%'
  }
});

export default GeneralPage;
