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
  Text,
  Dimensions,
  SafeAreaView,
  StyleSheet
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { TabView, SceneMap } from 'react-native-tab-view';

import {
  AddAccount,
  CreateAccountNavBar,
  ImportAccount
} from 'app/components/create-account';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { RootParamList } from 'app/navigator';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

const { width } = Dimensions.get('window');
const initialLayout = { width };

enum Tabs {
  add = 'add',
  import = 'import'
}

export const CreateAccountPage: React.FC<Prop> = ({ navigation }) => {
  const authState = keystore.guard.auth.store.useValue();

  const [index, setIndex] = React.useState(0);
  const [routes] = React.useState([
    { key: Tabs.add, title: i18n.t('add_account') },
    { key: Tabs.import, title: i18n.t('import_account') }
  ]);

  const handleCreate = React.useCallback(() => {
    navigation.navigate('App', {
      screen: 'Home'
    });
  }, []);

  const renderScene = SceneMap({
    [Tabs.add]: () => (
      <AddAccount
        biometricEnable={authState.biometricEnable}
        newIndex={keystore.account.lastIndexSeed}
        onAdded={handleCreate}
      />
    ),
    [Tabs.import]: () => (
      <ImportAccount
        biometricEnable={authState.biometricEnable}
        onImported={handleCreate}
      />
    )
  });

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>
        {i18n.t('create_account_title')}
      </Text>
      <TabView
        style={styles.tabView}
        renderTabBar={CreateAccountNavBar}
        navigationState={{ index, routes }}
        renderScene={renderScene}
        onIndexChange={setIndex}
        initialLayout={initialLayout}
      />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  scene: {
    flex: 1,
  },
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
  },
  title: {
    textAlign: 'center',
    fontWeight: 'bold',
    color: theme.colors.white,
    fontSize: 34,
    lineHeight: 41,
    marginTop: 30
  },
  tabView: {
    backgroundColor: theme.colors.black
  }
});
