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
  StyleSheet,
  Text,
  View,
  Alert,
  NativeModules
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import SafeAreaView from 'react-native-safe-area-view';
import { StackNavigationProp } from '@react-navigation/stack';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';

import { QRScaner } from 'app/components/modals/qr-scaner';
import { CustomButton } from 'app/components/custom-button';
import { Passwordinput } from 'app/components/password-input';
import { Switcher } from 'app/components/switcher';

import { UnauthorizedStackParamList } from 'app/navigator/unauthorized';
import i18n from 'app/lib/i18n';
import { fonts } from 'app/styles';
import { PubNubWrapper } from 'app/lib/controller/connect';
import { sha256 } from 'app/lib/crypto';
import { PubNubDataResult, EncryptedWallet } from 'types';
import { keystore } from 'app/keystore';

type Prop = {
  navigation: StackNavigationProp<UnauthorizedStackParamList>;
};

const Aes = NativeModules.Aes;
const STEPS = [
  i18n.t('connect_step0'),
  i18n.t('connect_step1'),
  i18n.t('connect_step2'),
  i18n.t('connect_step3')
];

export const WalletConnectPage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();
  const authState = keystore.guard.auth.store.useValue();

  const [qrcodeModal, setQrcodeModal] = React.useState(false);
  const [isLoading, setIsLoading] = React.useState(false);
  const [password, setPassword] = React.useState<string>();
  const [passwordError, setPasswordError] = React.useState(' ');
  const [data, setData] = React.useState<PubNubDataResult>();
  const [isBiometric, setIsBiometric] = React.useState(Boolean(authState.supportedBiometryType));
  const [biometric, setBiometric] = React.useState<string>();

  const handleScan = React.useCallback(async(value) => {
    setIsLoading(true);

    if (value && value.search('zilpay-sync:') !== -1) {
      const field = PubNubWrapper.FIELD;
      const [channelName, cipherKey, iv] = value.replace(`${field}:`, '').split('|@|');
      const pubnubWrapper = new PubNubWrapper(channelName, cipherKey);

      try {
        const content = await pubnubWrapper.startSync();

        setData({
          ...content,
          iv
        });
      } catch (err) {
        Alert.alert(
          i18n.t('connect_invalid_qr_code_title'),
          err.message
        );
      }
    } else {
      Alert.alert(
        i18n.t('connect_invalid_qr_code_title'),
        i18n.t('connect_invalid_qr_code_des')
      );
    }

    setIsLoading(false);
  }, []);
  const hanldeChangePassword = React.useCallback((value) => {
    setPasswordError(' ');
    setPassword(value);
  }, []);
  const handleDecrypt = React.useCallback(async() => {
    setIsLoading(true);

    if (!data || !password) {
      Alert.alert(
        i18n.t('connect_invalid_qr_code_title'),
        i18n.t('connect_invalid_qr_code_des')
      );

      setIsLoading(false);

      return null;
    }

    try {
      const pwd = await sha256(password);
      const content = await Aes.decrypt(data.cipher, pwd, data.iv);
      const decrypted: EncryptedWallet = JSON.parse(JSON.parse(content));

      await keystore.initWallet(password, decrypted.decryptSeed);
      await keystore.account.reset();

      for (const iterator of data.wallet.identities) {
        if (iterator.hwType) {
          continue;
        } else if (iterator.isImport) {
          const found = decrypted.decryptImported.find(
            (el) => el.index === iterator.index
          );

          if (!found) {
            continue;
          }

          if (!iterator.name) {
            iterator.name = `Imported ${iterator.index}`;
          }

          await keystore.addPrivateKeyAccount(
            found.privateKey,
            iterator.name,
            password
          );
        } else {
          if (!iterator.name) {
            iterator.name = `Account ${iterator.index}`;
          }

          await keystore.addAccount(
            decrypted.decryptSeed,
            iterator.name,
            iterator.index
          );
        }
      }

      if (isBiometric) {
        await keystore.guard.auth.initKeychain(password);
      }

      navigation.navigate('InitSuccessfully');
    } catch (err) {
      console.log(err)
      setPasswordError(i18n.t('lock_error'));
    }

    setIsLoading(false);
  }, [password, data, isBiometric]);

  React.useEffect(() => {
    const { accessControl } = authState;

    if (!accessControl) {
      setBiometric(i18n.t('biometric_pin'));
    } else {
      setBiometric(i18n.t('biometric_touch_id'));
    }
  }, []);

  return (
    <React.Fragment>
      {!data ? (
        <SafeAreaView style={[styles.container, {
          backgroundColor: colors.background
        }]}>
          <Text style={[styles.title, {
            color: colors.text
          }]}>
            {i18n.t('connect_title')}
          </Text>
          <View>
            {STEPS.map((step, index) => (
              <Text
                style={[styles.stepText, {
                  color: colors.text
                }]}
                key={index}
              >
                {index + 1}. {step}
              </Text>
            ))}
          </View>
          <CustomButton
            style={styles.scanBtn}
            title={i18n.t('connect_scan_btn')}
            isLoading={isLoading}
            onPress={() => setQrcodeModal(true)}
          />
          <QRScaner
            visible={qrcodeModal}
            onTriggered={() => setQrcodeModal(false)}
            onScan={handleScan}
          />
        </SafeAreaView>
      ) : (
        <SafeAreaView style={[styles.container, {
          backgroundColor: colors.background
        }]}>
          <KeyboardAwareScrollView>
            <Text style={[styles.title, {
              color: colors.text
            }]}>
              {i18n.t('connect_title_decrypt')}
            </Text>
            <Passwordinput
              placeholder={i18n.t('pass_setup_input1')}
              onChange={hanldeChangePassword}
              passwordError={passwordError}
              onSubmitEditing={handleDecrypt}
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
            <CustomButton
              disabled={!password}
              title={i18n.t('confirm')}
              isLoading={isLoading}
              onPress={handleDecrypt}
            />
          </KeyboardAwareScrollView>
        </SafeAreaView>
      )}
    </React.Fragment>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center'
  },
  title: {
    fontFamily: fonts.Bold,
    textAlign: 'center',
    fontSize: 17,
    lineHeight: 40,
    marginVertical: 30
  },
  stepText: {
    fontFamily: fonts.Regular,
    fontSize: 14,
    lineHeight: 30
  },
  biometric: {
    paddingBottom: 15,
    flexDirection: 'row',
    alignItems: 'center'
  },
  scanBtn: {
    width: '70%',
    marginTop: 30
  }
});

export default WalletConnectPage;
