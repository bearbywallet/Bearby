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
import SafeAreaView from 'react-native-safe-area-view';
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

  return (
    <SafeAreaView style={[styles.container, {
      backgroundColor: colors.background
    }]}>
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
      <ScrollView style={styles.list}>
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
  switcherWrapper: {
    maxWidth: '70%'
  },
  list: {
    marginTop: 16
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
    marginTop: 30,
    paddingVertical: 15,
    paddingHorizontal: 15
  }
});

export default BrowserSettingsPage;
