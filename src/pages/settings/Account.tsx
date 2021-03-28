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
  StyleSheet,
  ActivityIndicator
} from 'react-native';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';
import { useTheme } from '@react-navigation/native';

import { Button } from 'app/components/button';
import { CustomTextInput } from 'app/components/custom-text-input';
import ProfileSVG from 'app/assets/icons/profile.svg';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { fonts } from 'app/styles';
import { AccountTypes } from 'app/config';

export const AccountSettingsPage: React.FC = () => {
  const { colors } = useTheme();
  const accountState = keystore.account.store.useValue();
  const [loading, setLoading] = React.useState(false);
  const [nonce, setNonce] = React.useState(0);

  const account = React.useMemo(
    () => accountState.identities[accountState.selectedAddress],
    [accountState]
  );

  const hanldeResetName = React.useCallback(() => {
    const index = accountState.identities.findIndex(
      (acc) => acc.base16 === account.base16
    );
    let name = '';

    if (account.type === AccountTypes.Seed) {
      name = `Account ${index}`;
    } else if (account.type === AccountTypes.privateKey) {
      name = `Imported ${index}`;
    } else if (account.type === AccountTypes.Ledger) {
      name = `Ledger ${index}`;
    }

    keystore.account.updateAccountName({
      ...account,
      name
    });
  }, [account, accountState]);
  const hanldeResetNonce = React.useCallback(async() => {
    setLoading(true);
    setNonce(await keystore.transaction.resetNonce(account));
    setLoading(false);
  }, [account]);
  const handleChangeName = React.useCallback((name: string) => {
    keystore.account.updateAccountName({
      ...account,
      name
    });
  }, [account, accountState]);

  React.useEffect(() => {
    setLoading(true);

    keystore
      .transaction
      .calcNextNonce(account)
      .then((n) => {
        setNonce(n - 1);
        setLoading(false);
      })
      .catch((err) => null)
      .finally(() => setLoading(false));
  }, []);

  return (
    <View>
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
            Icon={ProfileSVG}
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
              {loading ? (
                <ActivityIndicator
                animating={loading}
                color={colors.primary}
              />
              ) : (
                <Text style={[styles.text, {
                  color: colors.text
                }]}>
                  {nonce}
                </Text>
              )}
            </View>
          </View>
        </View>
      </KeyboardAwareScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  titleWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 16,
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
