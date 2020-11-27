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
  StyleSheet
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { useStore } from 'effector-react';

import { HomeAccount, HomeTokens } from 'app/components/home';
import { ReceiveModal } from 'app/components/modals';

import { theme } from 'app/styles';
import { RootParamList } from 'app/navigator';
import { keystore } from 'app/keystore';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

export const HomePage: React.FC<Prop> = ({ navigation }) => {
  const accountState = useStore(keystore.account.store);
  const settingsState = useStore(keystore.settings.store);
  const currencyState = useStore(keystore.currency.store);
  const netwrokState = useStore(keystore.network.store);
  const tokensState = useStore(keystore.token.store);

  const [isReceiveModal, setIsReceiveModal] = React.useState(false);

  const handleCreateAccount = React.useCallback(() => {
    navigation.navigate('Common', {
      screen: 'CreateAccount'
    });
  }, []);
  const handleSend = React.useCallback(() => {
    navigation.navigate('Common', {
      screen: 'Transfer'
    });
  }, []);

  return (
    <View style={styles.container}>
      <HomeAccount
        token={tokensState.identities[0]}
        rate={settingsState.rate[currencyState]}
        currency={currencyState}
        netwrok={netwrokState.selected}
        account={accountState.identities[accountState.selectedAddress]}
        onCreateAccount={handleCreateAccount}
        onReceive={() => setIsReceiveModal(true)}
        onSend={handleSend}
      />
      <HomeTokens />
      <ReceiveModal
        visible={isReceiveModal}
        onTriggered={() => setIsReceiveModal(false)}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
  }
});

export default HomePage;
