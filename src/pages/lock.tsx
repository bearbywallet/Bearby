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
import { NavigationScreenProp, NavigationState } from 'react-navigation';
import { SvgXml } from 'react-native-svg';

import CreateBackground from 'app/assets/get_started_1.svg';
import { LockSVG } from 'app/components/svg';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { keystore } from 'app/keystore';

type Prop = {
  navigation: NavigationScreenProp<NavigationState>;
};

const { width } = Dimensions.get('window');
export const LockPage: React.FC<Prop> = ({ navigation }) => {

  const [password, setPassword] = React.useState('');
  const [passwordError, setPasswordError] = React.useState(' ');

  const color = React.useMemo(
    () => passwordError.length > 2 ? theme.colors.danger : '#666666',
    [passwordError]
  );

  const hanldeUnlock = React.useCallback(async() => {
    try {
      await keystore.unlockWallet(password);
      await keystore.sync();

      navigation.navigate('Home');
    } catch (err) {
      setPasswordError(i18n.t('lock_error'));
    }
  }, [password, setPasswordError]);
  const hanldeInputPassword = React.useCallback((value) => {
    setPassword(value);
    setPasswordError(' ');
  }, [setPassword]);

  return (
    <SafeAreaView style={styles.container}>
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
    </SafeAreaView>
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
    width: '100%'
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
    justifyContent: 'space-evenly',
    alignItems: 'center',
    height: '100%',
    paddingTop: '100%',
    paddingHorizontal: 60
  },
  title: {
    fontWeight: 'bold',
    color: theme.colors.white,
    lineHeight: 41,
    fontSize: 34
  }
});

export default LockPage;
