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
  Button,
  Keyboard,
  ScrollView,
  ActivityIndicator,
  StyleSheet
} from 'react-native';
import { SvgXml } from 'react-native-svg';
import { StackNavigationProp } from '@react-navigation/stack';
import { RouteProp } from '@react-navigation/native';

import { ProfileSVG, LockSVG } from 'app/components/svg';
import { Switcher } from 'app/components/switcher';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { UnauthorizedStackParamList } from 'app/navigator/unauthorized';
import { PASSWORD_DIFFICULTY, MAX_NAME_DIFFICULTY } from 'app/config';

type Prop = {
  navigation: StackNavigationProp<UnauthorizedStackParamList>;
  route: RouteProp<UnauthorizedStackParamList, 'SetupPassword'>;
};

export const SetupPasswordPage: React.FC<Prop> = ({ navigation, route }) => {
  const authState = keystore.guard.auth.store.useValue();

  const [mnemonicPhrase] = React.useState(String(route.params.phrase));
  const [loading, setLoading] = React.useState(false);

  const [accountName, setAccountName] = React.useState('');
  const [password, setPassword] = React.useState('qazqaz');
  const [passwordConfirm, setPasswordConfirm] = React.useState('qazqaz');
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
    <ScrollView style={styles.container}>
      <Text style={styles.title}>
        {i18n.t('password_title')}
      </Text>
      <View style={styles.wrapper}>
        <View style={styles.elementWrapper}>
          <View style={styles.inputWrapper}>
            <SvgXml xml={ProfileSVG} />
            <TextInput
              style={styles.textInput}
              placeholder={i18n.t('pass_setup_input0')}
              placeholderTextColor="#2B2E33"
              onChangeText={setAccountName}
            />
          </View>
          <Text style={styles.label}>
            {i18n.t('pass_setup_label0')}
          </Text>
        </View>
        <Switcher
          style={styles.biometric}
          enabled={isBiometric}
          onChange={setIsBiometric}
        >
          <Text style={styles.label}>
            {biometric}
          </Text>
        </Switcher>
        <View style={styles.elementWrapper}>
          <View style={styles.inputWrapper}>
            <SvgXml xml={LockSVG} />
            <TextInput
              style={styles.textInput}
              secureTextEntry={true}
              placeholder={i18n.t('pass_setup_input1')}
              placeholderTextColor="#2B2E33"
              onChangeText={setPassword}
            />
          </View>
          <View style={{ marginLeft: 39 }}>
            <TextInput
              style={styles.textInput}
              secureTextEntry={true}
              placeholder={i18n.t('pass_setup_input2')}
              placeholderTextColor="#2B2E33"
              onChangeText={setPasswordConfirm}
            />
          </View>
          <Text style={styles.label}>
            {i18n.t('pass_setup_label1')}
          </Text>
          <Text style={styles.label}>
            {i18n.t('pass_setup_label2')}
          </Text>
        </View>
      </View>
      {loading ? (
        <ActivityIndicator
          animating={loading}
          color={theme.colors.primary}
        />
      ) : (
        <Button
          title={i18n.t('pass_setup_btn')}
          color={theme.colors.primary}
          disabled={disabledContinue}
          onPress={handleCreate}
        />
      )}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    padding: 10,
    borderBottomColor: '#2B2E33',
    borderBottomWidth: 1,
    color: theme.colors.white,
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
    color: '#8A8A8F',
    marginLeft: 38
  },
  title: {
    textAlign: 'center',
    fontWeight: 'bold',
    color: theme.colors.white,
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
