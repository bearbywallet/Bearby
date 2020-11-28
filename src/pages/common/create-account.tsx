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
  SafeAreaView,
  StyleSheet
} from 'react-native';
import { SvgXml } from 'react-native-svg';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';
import { StackNavigationProp } from '@react-navigation/stack';
import { useStore } from 'effector-react';

import { ProfileSVG, LockSVG } from 'app/components/svg';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
// import { MAX_NAME_DIFFICULTY } from 'app/config';
import { RootParamList } from 'app/navigator';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

export const CreateAccountPage: React.FC<Prop> = ({ navigation }) => {
  const accountState = keystore.account.store.useValue();
  const authState = useStore(keystore.guard.auth.store);

  const [password, setPassword] = React.useState('');
  const [passwordError, setPasswordError] = React.useState(' ');
  const [name, setName] = React.useState(i18n.t('create_account_name', {
    number: accountState.identities.length
  }));

  const handleCreate = React.useCallback(async() => {
    if (authState.biometricEnable) {
      await keystore.addNextAccount(name);

      return navigation.navigate('App', {
        screen: 'Home'
      });
    }

    try {
      await keystore.addNextAccount(name, password);
      await keystore.transaction.sync();

      return navigation.navigate('App', {
        screen: 'Home'
      });
    } catch (err) {
      setPasswordError(i18n.t('lock_error'));
    }
  }, [password, name]);

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>
        {i18n.t('create_account_title')}
      </Text>
      <KeyboardAwareScrollView style={styles.wrapper}>
        <View style={styles.elementWrapper}>
          <View style={styles.inputWrapper}>
            <SvgXml xml={ProfileSVG} />
            <TextInput
              style={styles.textInput}
              placeholder={i18n.t('pass_setup_input0')}
              defaultValue={name}
              placeholderTextColor="#2B2E33"
              onChangeText={setName}
            />
          </View>
          <Text style={styles.label}>
            {i18n.t('pass_setup_label0')}
          </Text>
        </View>
        {!authState.biometricEnable ? (
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
              <Text style={styles.errorMessage}>
                {passwordError}
              </Text>
            </View>
          </View>
        ) : null}
      </KeyboardAwareScrollView>
      <View style={{ marginBottom: '10%' }}>
        <Button
          title={i18n.t('create_account_btn')}
          color={theme.colors.primary}
          onPress={handleCreate}
        />
      </View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
  },
  title: {
    textAlign: 'center',
    fontWeight: 'bold',
    color: theme.colors.white,
    fontSize: 34,
    lineHeight: 41,
    marginTop: 30
  },
  errorMessage: {
    color: theme.colors.danger,
    marginTop: 4,
    lineHeight: 22
  },
  wrapper: {
    paddingHorizontal: 20,
    marginTop: 40,
    marginBottom: 60
  },
  elementWrapper: {
    marginVertical: 35
  },
  label: {
    marginVertical: 5,
    color: '#8A8A8F',
    marginLeft: 38
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
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
});
