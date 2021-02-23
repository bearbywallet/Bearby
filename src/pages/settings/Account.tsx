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
  StyleSheet
} from 'react-native';
import SafeAreaView from 'react-native-safe-area-view';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';
import { useTheme } from '@react-navigation/native';

import { Button } from 'app/components/button';
import { CustomTextInput } from 'app/components/custom-text-input';
import { ProfileSVG } from 'app/components/svg';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { fonts } from 'app/styles';

export const AccountSettingsPage = () => {
  const { colors } = useTheme();
  const accountState = keystore.account.store.useValue();

  const account = React.useMemo(
    () => accountState.identities[accountState.selectedAddress],
    [accountState]
  );

  const hanldeResetName = React.useCallback(() => {
    const index = accountState.identities.findIndex(
      (acc) => acc.base16 === account.base16
    );
    const name = `${i18n.t('settings_item_account')} ${index}`;

    keystore.account.updateAccountName({
      ...account,
      name
    });
  }, [account, accountState]);
  const hanldeResetNonce = React.useCallback(() => {
    keystore.account.updateNonce(accountState.selectedAddress);
  }, [accountState]);
  const handleChangeName = React.useCallback((name: string) => {
    keystore.account.updateAccountName({
      ...account,
      name
    });
  }, [account, accountState]);

  return (
    <SafeAreaView style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <View style={styles.titleWrapper}>
        <Text style={[styles.title, {
          color: colors.text
        }]}>
          {i18n.t('account_settings_title')}
        </Text>
      </View>
      <KeyboardAwareScrollView>
        <View style={[styles.itemWrapper, {
          backgroundColor: colors.card
        }]}>
          <Button
            title={i18n.t('reset')}
            color={colors.primary}
            style={styles.resetBtn}
            onPress={hanldeResetName}
          />
          <CustomTextInput
            defaultValue={account.name}
            icon={ProfileSVG}
            labelText={i18n.t('pass_setup_label0')}
            placeholder={i18n.t('pass_setup_input0')}
            onChangeText={handleChangeName}
          />
        </View>
        <View style={[styles.itemWrapper, {
          backgroundColor: colors.card
        }]}>
          <Button
            title={i18n.t('reset')}
            color={colors.primary}
            style={styles.resetBtn}
            onPress={hanldeResetNonce}
          />
          <View style={{
            flexDirection: 'row',
            paddingHorizontal: 16
          }}>
            <Text style={[styles.title, {
              color: colors.notification
            }]}>
              #
            </Text>
            <View style={styles.infoWrapper}>
              <Text style={[styles.text, {
                color: colors.notification
              }]}>
                Nonce
              </Text>
              <Text style={[styles.text, {
                color: colors.text
              }]}>
                {account.nonce}
              </Text>
            </View>
          </View>
        </View>
      </KeyboardAwareScrollView>
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
  resetBtn: {
    alignSelf: 'flex-end',
    marginHorizontal: 16
  },
  itemWrapper: {
    marginTop: 30,
    paddingVertical: 10
  },
  infoWrapper: {
    paddingHorizontal: 16
  },
  text: {
    fontSize: 15,
    fontFamily: fonts.Demi
  }
});

export default AccountSettingsPage;
