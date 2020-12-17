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
  StyleSheet
} from 'react-native';
import SafeAreaView from 'react-native-safe-area-view';

import { Selector } from 'app/components/selector';
import { Switcher } from 'app/components/switcher';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';

export const BrowserSettingsPage = () => {
  const searchEngineState = keystore.searchEngine.store.useValue();

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

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.titleWrapper}>
        <Text style={styles.title}>
          {i18n.t('browser_settings_title')}
        </Text>
        <Button
          title={i18n.t('reset')}
          color={theme.colors.primary}
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
          style={styles.switcherContainer}
          enabled={searchEngineState.dweb}
          onChange={() => keystore.searchEngine.toggleDweb(!searchEngineState.dweb)}
        >
          <View>
            <Text style={styles.someText}>
              {i18n.t('d_web')}
            </Text>
            <Text style={styles.someLable}>
              {i18n.t('d_web_description')}
            </Text>
          </View>
        </Switcher>
        <Switcher
          style={styles.switcherContainer}
          enabled={searchEngineState.incognito}
          onChange={() => keystore.searchEngine.toggleIncognito(!searchEngineState.incognito)}
        >
          <View>
            <Text style={styles.someText}>
              {i18n.t('incognito')}
            </Text>
            <Text style={styles.someLable}>
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
    backgroundColor: theme.colors.black,
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
    color: theme.colors.white,
    fontSize: 34,
    lineHeight: 41,
    fontWeight: 'bold'
  },
  list: {
    marginTop: 16
  },
  someText: {
    fontSize: 17,
    lineHeight: 22,
    color: theme.colors.white
  },
  someLable: {
    fontSize: 16,
    lineHeight: 21,
    color: '#8A8A8F'
  },
  switcherContainer: {
    marginTop: 30,
    backgroundColor: theme.colors.gray,
    paddingVertical: 15,
    paddingHorizontal: 15
  }
});

export default BrowserSettingsPage;
