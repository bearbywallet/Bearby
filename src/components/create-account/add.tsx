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
  StyleSheet, View
} from 'react-native';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';

import { CustomButton } from 'app/components/custom-button';
import { Passwordinput } from 'app/components/password-input';
import { CustomTextInput } from 'app/components/custom-text-input';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { ProfileSVG } from 'app/components/svg';

type Prop = {
  biometricEnable: boolean;
  newIndex: number;
  onAdded: () => void;
};

export const AddAccount: React.FC<Prop> = ({
  biometricEnable,
  newIndex,
  onAdded
}) => {
  const [loading, setLoading] = React.useState(false);
  const [password, setPassword] = React.useState('');
  const [passwordError, setPasswordError] = React.useState(' ');
  const [name, setName] = React.useState(i18n.t('create_account_name', {
    number: newIndex
  }));

  const handleCreate = React.useCallback(async() => {
    setLoading(true);
    if (biometricEnable) {
      await keystore.addNextAccount(name);
      await keystore.transaction.sync();

      setLoading(false);
      return onAdded();
    }

    try {
      await keystore.addNextAccount(name, password);
      await keystore.transaction.sync();

      onAdded();
    } catch (err) {
      setPasswordError(i18n.t('lock_error'));
    }
    setLoading(false);
  }, [password, name, biometricEnable, onAdded]);

  return (
    <KeyboardAwareScrollView style={styles.container}>
      <CustomTextInput
        icon={ProfileSVG}
        onChangeText={setName}
        defaultValue={name}
        placeholder={i18n.t('pass_setup_input0')}
        labelText={i18n.t('pass_setup_label0')}
      />
      <View style={styles.wrapper}>
        {!biometricEnable ? (
          <Passwordinput
            passwordError={passwordError}
            placeholder={i18n.t('pass_setup_input1')}
            onChange={setPassword}
          />
        ) : null}
        <CustomButton
          isLoading={loading}
          title={i18n.t('create_account_btn')}
          onPress={handleCreate}
        />
      </View>
    </KeyboardAwareScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingVertical: 16
  },
  wrapper: {
    padding: 16
  }
});