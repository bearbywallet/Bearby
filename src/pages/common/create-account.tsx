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
  Dimensions,
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import { SafeWrapper } from 'app/components/safe-wrapper';
import { StackNavigationProp } from '@react-navigation/stack';
import { TabView, SceneMap } from 'react-native-tab-view';

import {
  AddAccount,
  CreateAccountNavBar,
  ImportAccount,
  ScanningDevice
} from 'app/components/create-account';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { RootParamList } from 'app/navigator';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

const { width } = Dimensions.get('window');
const initialLayout = { width };

enum Tabs {
  Add = 'add',
  Import = 'import',
  Ledger = 'ledger'
}

export const CreateAccountPage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();
  const authState = keystore.guard.auth.store.useValue();

  const [index, setIndex] = React.useState(0);
  const [routes] = React.useState([
    { key: Tabs.Add, title: i18n.t('add_account') },
    { key: Tabs.Import, title: i18n.t('import_account') },
    { key: Tabs.Ledger, title: i18n.t('import_ledger') }
  ]);

  const handleCreate = React.useCallback(() => {
    navigation.navigate('App', {
      screen: 'Home'
    });
  }, []);

  const renderScene = SceneMap({
    [Tabs.Add]: () => (
      <AddAccount
        biometricEnable={authState.biometricEnable}
        newIndex={keystore.account.lastIndexSeed}
        onAdded={handleCreate}
      />
    ),
    [Tabs.Import]: () => (
      <ImportAccount
        biometricEnable={authState.biometricEnable}
        onImported={handleCreate}
      />
    ),
    [Tabs.Ledger]: () => (
      <ScanningDevice />
    )
  });

  return (
    <SafeWrapper>
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
    </SafeWrapper>
  );
};
