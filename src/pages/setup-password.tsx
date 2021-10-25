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
  Keyboard,
  ScrollView,
  Dimensions,
  ActivityIndicator,
  StyleSheet
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { RouteProp, useTheme } from '@react-navigation/native';

import ProfileSVG from 'app/assets/icons/profile.svg';
import LockSVG from 'app/assets/icons/lock.svg';

import { Switcher } from 'app/components/switcher';
import { Button } from 'app/components/button';
import { CustomTextInput } from 'app/components/custom-text-input';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { UnauthorizedStackParamList } from 'app/navigator/unauthorized';
import { PASSWORD_DIFFICULTY, MAX_NAME_DIFFICULTY } from 'app/config';
import { fonts } from 'app/styles';

type Prop = {
  navigation: StackNavigationProp<UnauthorizedStackParamList>;
  route: RouteProp<UnauthorizedStackParamList, 'SetupPassword'>;
};

const { width } = Dimensions.get('window');
export const SetupPasswordPage: React.FC<Prop> = ({ navigation, route }) => {
  const { colors } = useTheme();
  const authState = keystore.guard.auth.store.useValue();

  const [mnemonicPhrase] = React.useState(String(route.params.phrase));
  const [loading, setLoading] = React.useState(false);

  const [accountName, setAccountName] = React.useState(`${i18n.t('settings_item_account')} 0`);
  const [password, setPassword] = React.useState('');
  const [passwordConfirm, setPasswordConfirm] = React.useState('');
  const [isBiometric, setIsBiometric] = React.useState(Boolean(authState.supportedBiometryType));
  const [biometric, setBiometric] = React.useState<string>();
  const [error, setError] = React.useState<string>();

  const disabledContinue = React.useMemo(() => {
    if (!passwordConfirm || !password) {
      return true;
    }

    const isConfirmed = passwordConfirm === password;
    const isDifficulty = String(password).length < PASSWORD_DIFFICULTY;
    const isNameLength = String(accountName).length > MAX_NAME_DIFFICULTY;

    return !isConfirmed || isDifficulty || isNameLength;
  }, [password, passwordConfirm, accountName]);

  /**
   * Create Keystore and account by KeyPairs.
   */
  const handleCreate = React.useCallback(async() => {
    const isConfirmed = passwordConfirm === password;
    const isDifficulty = String(password).length < PASSWORD_DIFFICULTY;
    const isNameLength = String(accountName).length > MAX_NAME_DIFFICULTY;

    if (!isConfirmed) {
      setError(i18n.t('pass_setup_error0'));

      return null;
    } else if (isDifficulty) {
      setError(i18n.t('pass_setup_error1'));

      return null;
    } else if (isNameLength) {
      setError(i18n.t('pass_setup_error2'));

      return null;
    }

    setLoading(true);

    try {
      await keystore.initWallet(password, mnemonicPhrase);
      await keystore.account.reset();
      await keystore.addAccount(mnemonicPhrase, accountName);

      if (isBiometric) {
        await keystore.guard.auth.initKeychain(password);
      }

      navigation.navigate('InitSuccessfully');
    } catch (err) {
      setError((err as Error).message);
    }

    setLoading(false);
  }, [
    password,
    passwordConfirm,
    mnemonicPhrase,
    accountName,
    isBiometric,
    setLoading
  ]);

  React.useEffect(() => {
    const { accessControl } = authState;

    if (!accessControl) {
      setBiometric(i18n.t('biometric_pin'));
    } else {
      setBiometric(i18n.t('biometric_touch_id'));
    }
  }, []);
  React.useEffect(() => {
    if (!disabledContinue) {
      Keyboard.dismiss();
    }
  }, [disabledContinue]);

  React.useEffect(() => {
    setError(undefined);
  }, [accountName, passwordConfirm]);

  return (
    <ScrollView style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <Text style={[styles.title, {
        color: colors.text
      }]}>
        {i18n.t('password_title')}
      </Text>
      <View style={styles.wrapper}>
        <CustomTextInput
          Icon={ProfileSVG}
          defaultValue={accountName}
          placeholder={i18n.t('pass_setup_input0')}
          onChangeText={setAccountName}
          labelText={i18n.t('pass_setup_label0')}
        />
        {authState.supportedBiometryType ? (
          <Switcher
            style={styles.biometric}
            enabled={isBiometric}
            onChange={setIsBiometric}
          >
            <Text style={{
              color: colors.border
            }}>
              {biometric}
            </Text>
          </Switcher>
        ) : null}
        <View style={styles.elementWrapper}>
          <CustomTextInput
            Icon={LockSVG}
            placeholder={i18n.t('pass_setup_input1')}
            onChangeText={setPassword}
            secureTextEntry
          />
          <CustomTextInput
            placeholder={i18n.t('pass_setup_input2')}
            onChangeText={setPasswordConfirm}
            labelText={i18n.t('pass_setup_label1') + ' ' + i18n.t('pass_setup_label2')}
            secureTextEntry
          />
        </View>
        <Text style={[styles.error, {
          color: colors['danger']
        }]}>
          {error}
        </Text>
      </View>
      {loading ? (
        <ActivityIndicator
          animating={loading}
          color={colors.primary}
        />
      ) : (
        <Button
          style={{
            marginBottom: 30
          }}
          title={i18n.t('pass_setup_btn')}
          color={colors.primary}
          onPress={handleCreate}
        />
      )}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  error: {
    fontSize: 13,
    textAlign: 'center',
    fontFamily: fonts.Demi
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    padding: 5,
    fontFamily: fonts.Demi,
    borderBottomWidth: 1,
    width
  },
  biometric: {
    paddingLeft: 50,
    paddingHorizontal: 10,
    flexDirection: 'row',
    alignItems: 'center'
  },
  elementWrapper: {
    width,
    marginVertical: 15
  },
  title: {
    textAlign: 'center',
    fontFamily: fonts.Bold,
    fontSize: 34,
    lineHeight: 41,
    marginTop: 30
  },
  wrapper: {
    marginTop: 40,
    marginBottom: 60
  }
});

export default SetupPasswordPage;
