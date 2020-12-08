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
  Button,
  TextInput,
  Dimensions,
  Text,
  StyleSheet
} from 'react-native';
import { SvgXml } from 'react-native-svg';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';

import { ProfileSVG, LockSVG } from 'app/components/svg';
import { CustomButton } from 'app/components/custom-button';
import { AccountName } from 'app/components/account-name';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { theme } from 'app/styles';

type Prop = {
  biometricEnable: boolean;
  newIndex: number;
  onAdded: () => void;
};

const { width } = Dimensions.get('window');
export const AddAccount: React.FC<Prop> = ({
  biometricEnable,
  newIndex,
  onAdded
}) => {
  const [password, setPassword] = React.useState('');
  const [passwordError, setPasswordError] = React.useState(' ');
  const [name, setName] = React.useState(i18n.t('create_account_name', {
    number: newIndex
  }));

  const handleCreate = React.useCallback(async() => {
    if (biometricEnable) {
      await keystore.addNextAccount(name);
      await keystore.transaction.sync();

      return onAdded();
    }

    try {
      await keystore.addNextAccount(name, password);
      await keystore.transaction.sync();

      return onAdded();
    } catch (err) {
      setPasswordError(i18n.t('lock_error'));
    }
  }, [password, name, biometricEnable, onAdded]);

  return (
    <KeyboardAwareScrollView style={styles.wrapper}>
      <AccountName
        style={styles.elementWrapper}
        name={name}
        setName={setName}
      />
      {!biometricEnable ? (
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
      <CustomButton
        title={i18n.t('create_account_btn')}
        onPress={handleCreate}
      />
    </KeyboardAwareScrollView>
  );
};

const styles = StyleSheet.create({
  errorMessage: {
    color: theme.colors.danger,
    marginTop: 4,
    lineHeight: 22
  },
  wrapper: {
    paddingHorizontal: 20
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
    marginLeft: 15,
    borderBottomColor: '#2B2E33',
    borderBottomWidth: 1,
    color: theme.colors.white,
    width: width - 100
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center'
  }
});