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
import { Switcher } from 'app/components/switcher';
import { Button } from 'app/components/button';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { fonts } from 'app/styles';

export const BrowserSettingsPage = () => {
  const { colors } = useTheme();
  const searchEngineState = keystore.searchEngine.store.useValue();

  const [incognito, setIncognito] = React.useState(searchEngineState.incognito);
  const [cache, setCache] = React.useState(searchEngineState.cache);

  const engineList = React.useMemo(
    () => searchEngineState.identities.map((e) => e.name),
    [searchEngineState]
  );
  const selectedEngine = React.useMemo(
    () => searchEngineState.identities[searchEngineState.selected].name,
    [searchEngineState]
  );

  const handleSelect = React.useCallback(async(name) => {
    const findIndex = searchEngineState
      .identities
      .findIndex((e) => e.name === name);

    try {
      await keystore.searchEngine.changeEngine(findIndex);
    } catch {
      //
    }
  }, [searchEngineState]);
  const hanldeChangeIncognito = React.useCallback(() => {
    keystore.searchEngine.toggleIncognito(!incognito);
    setIncognito(!incognito);
  }, [incognito]);
  const hanldeChangeCache = React.useCallback(() => {
    keystore.searchEngine.toggleCache(!cache);
    setCache(!cache);
  }, [cache]);

  return (
    <ScrollView>
      <View style={styles.titleWrapper}>
        <Text style={[styles.title, {
          color: colors.text
        }]}>
          {i18n.t('browser_settings_title')}
        </Text>
        <Button
          title={i18n.t('reset')}
          color={colors.primary}
          onPress={() =>  keystore.searchEngine.reset()}
        />
      </View>
      <View style={styles.list}>
        <Selector
          title={i18n.t('browser_settings_selector_title')}
          items={engineList}
          selected={selectedEngine}
          onSelect={handleSelect}
        />
        <Switcher
          style={{
            ...styles.switcherContainer,
            backgroundColor: colors.card
          }}
          enabled={searchEngineState.dweb}
          onChange={() => keystore.searchEngine.toggleDweb(!searchEngineState.dweb)}
        >
          <View style={styles.switcherWrapper}>
            <Text style={[styles.someText, {
              color: colors.text
            }]}>
              {i18n.t('d_web')}
            </Text>
            <Text style={[styles.someLable, {
              color: colors.border
            }]}>
              {i18n.t('d_web_description')}
            </Text>
          </View>
        </Switcher>
        <Switcher
          style={{
            ...styles.switcherContainer,
            backgroundColor: colors.card
          }}
          enabled={incognito}
          onChange={hanldeChangeIncognito}
        >
          <View style={styles.switcherWrapper}>
            <Text style={[styles.someText, {
              color: colors.text
            }]}>
              {i18n.t('incognito')}
            </Text>
            <Text style={[styles.someLable, {
              color: colors.border
            }]}>
              {i18n.t('incognito_des')}
            </Text>
          </View>
        </Switcher>
        <Switcher
          style={{
            ...styles.switcherContainer,
            backgroundColor: colors.card
          }}
          enabled={cache}
          onChange={hanldeChangeCache}
        >
          <View style={styles.switcherWrapper}>
            <Text style={[styles.someText, {
              color: colors.text
            }]}>
              {i18n.t('cache')}
            </Text>
            <Text style={[styles.someLable, {
              color: colors.border
            }]}>
              {i18n.t('cache_des')}
            </Text>
          </View>
        </Switcher>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  titleWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 16,
    paddingHorizontal: 15
  },
  title: {
    fontSize: 30,
    fontFamily: fonts.Bold
  },
  switcherWrapper: {
    maxWidth: '70%'
  },
  list: {
    marginBottom: 100
  },
  someText: {
    fontSize: 17,
    fontFamily: fonts.Demi
  },
  someLable: {
    fontSize: 16,
    fontFamily: fonts.Regular
  },
  switcherContainer: {
    marginTop: 15,
    paddingVertical: 15,
    paddingHorizontal: 15
  }
});

export default BrowserSettingsPage;
