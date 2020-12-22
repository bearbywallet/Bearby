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
  ScrollView,
  Button
} from 'react-native';
import SafeAreaView from 'react-native-safe-area-view';

import { Selector } from 'app/components/selector';
import { NetwrokConfig } from 'app/components/netwrok-config';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { SSN_ADDRESS } from 'app/config';

const netwroks = Object.keys(keystore.network.config);
export const NetworkPage = () => {
  const networkState = keystore.network.store.useValue();

  const handleReset = React.useCallback(async() => {
    await keystore.network.reset();
    await keystore.transaction.sync();
    await keystore.account.balanceUpdate();
  }, []);
  const handleNetwrokChange = React.useCallback(async(net) => {
    await keystore.network.changeNetwork(net);
    await keystore.transaction.sync();
    await keystore.account.balanceUpdate();
  }, []);

  React.useEffect(() => {
    const field = 'ssnlist';
    keystore.zilliqa.getSmartContractSubState(
      SSN_ADDRESS,
      field
    );
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.titleWrapper}>
        <Text style={styles.title}>
          {i18n.t('netwrok_title')}
        </Text>
        <Button
          title={i18n.t('reset')}
          color={theme.colors.primary}
          onPress={handleReset}
        />
      </View>
      <ScrollView>
        <Selector
          style={{ marginVertical: 16 }}
          title={i18n.t('netwrok_options')}
          items={netwroks}
          selected={networkState.selected}
          onSelect={handleNetwrokChange}
        />
        <NetwrokConfig
          config={networkState.config}
          selected={networkState.selected}
          onChange={(netConfig) => keystore.network.changeConfig(netConfig)}
        />
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
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
});

export default NetworkPage;
