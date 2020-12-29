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
  TextInput,
  Keyboard,
  ScrollView,
  ActivityIndicator,
  StyleSheet
} from 'react-native';
import { SvgXml } from 'react-native-svg';
import { StackNavigationProp } from '@react-navigation/stack';
import { RouteProp, useTheme } from '@react-navigation/native';

import { ProfileSVG, LockSVG } from 'app/components/svg';
import { Switcher } from 'app/components/switcher';
import { Button } from 'app/components/button';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { UnauthorizedStackParamList } from 'app/navigator/unauthorized';
import { PASSWORD_DIFFICULTY, MAX_NAME_DIFFICULTY } from 'app/config';

type Prop = {
  navigation: StackNavigationProp<UnauthorizedStackParamList>;
  route: RouteProp<UnauthorizedStackParamList, 'SetupPassword'>;
};

export const SetupPasswordPage: React.FC<Prop> = ({ navigation, route }) => {
  const { colors } = useTheme();
  const authState = keystore.guard.auth.store.useValue();

  const [mnemonicPhrase] = React.useState(String(route.params.phrase));
  const [loading, setLoading] = React.useState(false);

  const [accountName, setAccountName] = React.useState('Account 0');
  const [password, setPassword] = React.useState('');
  const [passwordConfirm, setPasswordConfirm] = React.useState('');
  const [isBiometric, setIsBiometric] = React.useState(true);
  const [biometric, setBiometric] = React.useState<string>();

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
      console.error(err);
    }

    setLoading(false);
  }, [password, mnemonicPhrase, accountName, isBiometric, setLoading]);

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
        <View style={styles.elementWrapper}>
          <View style={styles.inputWrapper}>
            <SvgXml xml={ProfileSVG} />
            <TextInput
              style={[styles.textInput, {
                color: colors.text,
                borderBottomColor: colors.border
              }]}
              defaultValue={accountName}
              placeholder={i18n.t('pass_setup_input0')}
              placeholderTextColor={colors.card}
              onChangeText={setAccountName}
            />
          </View>
          <Text style={[styles.label, {
            color: colors.border
          }]}>
            {i18n.t('pass_setup_label0')}
          </Text>
        </View>
        {authState.biometricEnable ? (
          <Switcher
            style={styles.biometric}
            enabled={isBiometric}
            onChange={setIsBiometric}
          >
            <Text style={[styles.label, {
              color: colors.border
            }]}>
              {biometric}
            </Text>
          </Switcher>
        ) : null}
        <View style={styles.elementWrapper}>
          <View style={styles.inputWrapper}>
            <SvgXml xml={LockSVG} />
            <TextInput
              style={[styles.textInput, {
                color: colors.text,
                borderBottomColor: colors.border
              }]}
              secureTextEntry={true}
              placeholder={i18n.t('pass_setup_input1')}
              placeholderTextColor={colors.notification}
              onChangeText={setPassword}
            />
          </View>
          <View style={{ marginLeft: 39 }}>
            <TextInput
              style={[styles.textInput, {
                color: colors.text,
                borderBottomColor: colors.border
              }]}
              secureTextEntry={true}
              placeholder={i18n.t('pass_setup_input2')}
              placeholderTextColor={colors.notification}
              onChangeText={setPasswordConfirm}
            />
          </View>
          <Text style={[styles.label, {
            color: colors.border
          }]}>
            {i18n.t('pass_setup_label1')}
          </Text>
          <Text style={[styles.label, {
            color: colors.border
          }]}>
            {i18n.t('pass_setup_label2')}
          </Text>
        </View>
      </View>
      {loading ? (
        <ActivityIndicator
          animating={loading}
          color={colors.primary}
        />
      ) : (
        <Button
          title={i18n.t('pass_setup_btn')}
          color={colors.primary}
          disabled={disabledContinue}
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
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    padding: 10,
    borderBottomWidth: 1,
    width: '90%'
  },
  biometric: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  elementWrapper: {
    marginVertical: 35
  },
  label: {
    marginVertical: 5,
    marginLeft: 38
  },
  title: {
    textAlign: 'center',
    fontWeight: 'bold',
    fontSize: 34,
    lineHeight: 41,
    marginTop: 30
  },
  wrapper: {
    paddingHorizontal: 20,
    marginTop: 40,
    marginBottom: 60
  }
});

export default SetupPasswordPage;
