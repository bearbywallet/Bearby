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
  StyleSheet
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import SafeAreaView from 'react-native-safe-area-view';
import { StackNavigationProp } from '@react-navigation/stack';
import { TabView, SceneMap } from 'react-native-tab-view';

import {
  AddAccount,
  CreateAccountNavBar,
  ImportAccount
} from 'app/components/create-account';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { RootParamList } from 'app/navigator';
import { fonts } from 'app/styles';

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
  const { colors } = useTheme();
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
    <SafeAreaView style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <Text style={[styles.title, {
        color: colors.text
      }]}>
        {i18n.t('create_account_title')}
      </Text>
      <TabView
        style={{
          backgroundColor: colors.background
        }}
        renderTabBar={(props) => <CreateAccountNavBar {...props} />}
        navigationState={{ index, routes }}
        renderScene={renderScene}
        onIndexChange={setIndex}
        initialLayout={initialLayout}
      />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  title: {
    textAlign: 'center',
    fontFamily: fonts.Bold,
    fontSize: 30
  }
});
