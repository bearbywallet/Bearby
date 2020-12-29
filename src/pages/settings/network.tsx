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
  ScrollView
} from 'react-native';
import SafeAreaView from 'react-native-safe-area-view';
import { useTheme } from '@react-navigation/native';

import { Selector } from 'app/components/selector';
import { NetwrokConfig } from 'app/components/netwrok-config';
import { Button } from 'app/components/button';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
// import { SSN_ADDRESS } from 'app/config';

const netwroks = Object.keys(keystore.network.config);
export const NetworkPage = () => {
  const { colors } = useTheme();
  const networkState = keystore.network.store.useValue();

  const handleReset = React.useCallback(async() => {
    await keystore.network.reset();
    await keystore.transaction.sync();
    await keystore.account.balanceUpdate();
  }, []);
  const handleNetwrokChange = React.useCallback(async(net) => {
    await keystore.network.changeNetwork(net);
    await keystore.transaction.sync();
  }, []);

  // React.useEffect(() => {
  //   const field = 'ssnlist';

  //   keystore.zilliqa.getSmartContractSubState(
  //     SSN_ADDRESS,
  //     field
  //   );
  // }, []);

  return (
    <SafeAreaView style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <View style={styles.titleWrapper}>
        <Text style={[styles.title, {
          color: colors.text
        }]}>
          {i18n.t('netwrok_title')}
        </Text>
        <Button
          title={i18n.t('reset')}
          color={colors.primary}
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
    fontSize: 34,
    lineHeight: 41,
    fontWeight: 'bold'
  },
});

export default NetworkPage;
