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
  StyleSheet,
  Text,
  TextInput,
  Button,
  Dimensions
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';
import { SvgXml } from 'react-native-svg';

import CreateBackground from 'app/assets/get_started_1.svg';
import { LockSVG, FingerPrintIconSVG } from 'app/components/svg';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { keystore } from 'app/keystore';
import { RootParamList } from 'app/navigator';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

const { width } = Dimensions.get('window');
export const LockPage: React.FC<Prop> = ({ navigation }) => {
  const [biometric] = React.useState(keystore.guard.auth.secureKeychain.biometricEnable);
  const [password, setPassword] = React.useState('');
  const [passwordError, setPasswordError] = React.useState(' ');

  const color = React.useMemo(
    () => passwordError.length > 2 ? theme.colors.danger : '#666666',
    [passwordError]
  );

  const hanldeUnlock = React.useCallback(async() => {
    try {
      await keystore.guard.unlock(password);

      navigation.navigate('App', { screen: 'Home' });
    } catch (err) {
      // console.log(err);
      setPasswordError(i18n.t('lock_error'));
    }
  }, [password, setPasswordError]);
  const hanldeInputPassword = React.useCallback((value) => {
    setPassword(value);
    setPasswordError(' ');
  }, [setPassword]);
  const hanldeBiometricUnlock = React.useCallback(async() => {
    try {
      await  keystore.guard.unlock();

      return navigation.navigate('App', { screen: 'Home' });
    } catch (err) {
      setPasswordError(i18n.t('biometric_error'));
    }
  }, []);

  React.useEffect(() => {
    if (biometric) {
      hanldeBiometricUnlock();
    }
  }, []);

  return (
    <KeyboardAwareScrollView style={styles.container}>
      <View style={[StyleSheet.absoluteFill, styles.backgroundImage]}>
        <CreateBackground
          width={width + width / 2}
          height={width + width / 2}
        />
      </View>
      <View style={styles.pageContainer}>
        <Text style={styles.title}>
          {i18n.t('lock_title')}
        </Text>
        <View>
          <View style={[styles.inputWrapper, { borderBottomColor: color }]}>
            <SvgXml
              xml={LockSVG}
              fill={color}
            />
            <TextInput
              style={styles.textInput}
              secureTextEntry={true}
              placeholder={i18n.t('pass_setup_input1')}
              placeholderTextColor={color}
              onChangeText={hanldeInputPassword}
              onSubmitEditing={hanldeUnlock}
            />
            {biometric ? (
              <SvgXml
                xml={FingerPrintIconSVG}
                onTouchEnd={hanldeBiometricUnlock}
              />
            ) : null}
          </View>
          <Text style={styles.errorMessage}>
            {passwordError}
          </Text>
        </View>
        <Button
          title={i18n.t('lock_btn')}
          color={theme.colors.primary}
          onPress={hanldeUnlock}
        />
      </View>
    </KeyboardAwareScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
  },
  backgroundImage: {
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: '50%'
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    padding: 10,
    color: theme.colors.white,
    width: '84%'
  },
  errorMessage: {
    color: theme.colors.danger,
    marginTop: 4,
    lineHeight: 22
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    borderBottomWidth: 1
  },
  pageContainer: {
    paddingTop: '100%',
    padding: 60
  },
  title: {
    fontWeight: 'bold',
    color: theme.colors.white,
    lineHeight: 41,
    fontSize: 34
  }
});

export default LockPage;
