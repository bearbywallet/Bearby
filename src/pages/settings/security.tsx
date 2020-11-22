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
  SafeAreaView,
  Text,
  Button,
  ScrollView,
  StyleSheet
} from 'react-native';

import { Selector } from 'app/components/selector';
import { Switcher } from 'app/components/switcher';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { theme } from 'app/styles';

const times = [
  {
    time: 1,
    name: `1 ${i18n.t('hour')}`
  },
  {
    time: 3,
    name: `3 ${i18n.t('hours')}`
  },
  {
    time: 5,
    name: `5 ${i18n.t('hours')}`
  },
];
export const SecurityPage: React.FC = () => {
  const [biometric, setBiometric] = React.useState(keystore.guard.auth.secureKeychain.biometricEnable);
  const [hour, sethour] = React.useState(0);

  const hanldeChangeBiometric = React.useCallback((value) => {
    if (!value) {
      keystore.guard.auth.secureKeychain.reset();
      setBiometric(value);
    }
  }, [biometric]);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.titleWrapper}>
        <Text style={styles.title}>
          {i18n.t('security_title')}
        </Text>
      </View>
      <ScrollView>
        <Selector
          style={{ marginVertical: 16 }}
          title={i18n.t('security_lock')}
          items={times.map((item) => item.name)}
          selected={times[hour].name}
          onSelect={(_, index) => sethour(index)}
        />
        <Switcher
          style={styles.biometric}
          enabled={biometric}
          onChange={hanldeChangeBiometric}
        >
          {i18n.t('biometric_touch_id')}
        </Switcher>
        <Button
          title={i18n.t('security_btn0')}
          color={theme.colors.primary}
          onPress={() => null}
        />
        <Button
          title={i18n.t('security_btn1')}
          color={theme.colors.primary}
          onPress={() => null}
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
  biometric: {
    paddingVertical: 15,
    paddingHorizontal: 50
  }
});

export default SecurityPage;
