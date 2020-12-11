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
  Dimensions,
  TextInput,
  StyleSheet
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { SvgXml } from 'react-native-svg';

import { AccountMenu } from 'app/components/account-menu';
import { SimpleConfirm } from 'app/components/modals';
import { SearchIconSVG } from 'app/components/svg';
import { TabView, SceneMap } from 'react-native-tab-view';
import {
  BrowserNavBar,
  BrowserApps,
  BrowserFavorites
} from 'app/components/browser';

import { theme } from 'app/styles';
import { keystore } from 'app/keystore';
import i18n from 'app/lib/i18n';
import { RootParamList } from 'app/navigator';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

enum Tabs {
  apps = 'apps',
  favorites = 'favorites'
}

const { height, width } = Dimensions.get('window');
const initialLayout = { width };
export const BrowserHomePage: React.FC<Prop> = ({ navigation }) => {
  const accountState = keystore.account.store.useValue();

  const [isConfirmModal, setIsConfirmModal] = React.useState(false);
  const [index, setIndex] = React.useState(0);
  const [routes] = React.useState([
    { key: Tabs.apps, title: i18n.t('apps') },
    { key: Tabs.favorites, title: i18n.t('favorites') }
  ]);

  const account = React.useMemo(
    () => accountState.identities[accountState.selectedAddress],
    [accountState]
  );

  const handleRemoveAccount = React.useCallback(async() => {
    await keystore.account.removeAccount(account);
    setIsConfirmModal(false);
  }, [account, setIsConfirmModal]);
  const handleCreateAccount = React.useCallback(() => {
    navigation.navigate('Common', {
      screen: 'CreateAccount'
    });
  }, []);

  const renderScene = SceneMap({
    [Tabs.apps]: () => (
      <BrowserApps />
    ),
    [Tabs.favorites]: () => (
      <BrowserFavorites />
    )
  });

  return (
    <React.Fragment>
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          <AccountMenu
            accountName={account.name}
            onCreate={handleCreateAccount}
            onRemove={() => setIsConfirmModal(true)}
          />
          <View style={styles.headerWraper}>
            <Text style={styles.headerTitle}>
              {i18n.t('browser_title')}
            </Text>
          </View>
        </View>
        <View style={styles.main}>
          <View style={styles.inputWrapper}>
            <SvgXml xml={SearchIconSVG} />
            <TextInput
              style={styles.textInput}
              placeholder={i18n.t('browser_placeholder_input')}
              placeholderTextColor="#8A8A8F"
              onChangeText={() => null}
            />
          </View>
          <TabView
            style={styles.tabView}
            renderTabBar={BrowserNavBar}
            navigationState={{ index, routes }}
            renderScene={renderScene}
            onIndexChange={setIndex}
            initialLayout={initialLayout}
          />
        </View>
      </SafeAreaView>
      <SimpleConfirm
        title={i18n.t('remove_acc_title', {
          name: account.name || ''
        })}
        description={i18n.t('remove_seed_acc_des')}
        btns={[i18n.t('reject'), i18n.t('confirm')]}
        visible={isConfirmModal}
        onConfirmed={handleRemoveAccount}
        onTriggered={() => setIsConfirmModal(false)}
      />
    </React.Fragment>
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
    backgroundColor: theme.colors.background,
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
  },
  tabView: {
    marginTop: 15
  }
});

export default BrowserHomePage;
