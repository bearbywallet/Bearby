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
  Alert
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import SafeAreaView from 'react-native-safe-area-view';
import { StackNavigationProp } from '@react-navigation/stack';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';

import { QRScaner } from 'app/components/modals/qr-scaner';
import { CustomButton } from 'app/components/custom-button';
import { Passwordinput } from 'app/components/password-input';

import { UnauthorizedStackParamList } from 'app/navigator/unauthorized';
import i18n from 'app/lib/i18n';
import { fonts } from 'app/styles';
import { PubNubWrapper } from 'app/lib/controller/connect';
import { Encryptor } from 'app/lib/crypto';
import { PubNubDataResult } from 'types';

type Prop = {
  navigation: StackNavigationProp<UnauthorizedStackParamList>;
};

const STEPS = [
  i18n.t('connect_step0'),
  i18n.t('connect_step1'),
  i18n.t('connect_step2'),
  i18n.t('connect_step3')
];

export const WalletConnectPage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();
  const [qrcodeModal, setQrcodeModal] = React.useState(false);
  const [isLoading, setIsLoading] = React.useState(false);
  const [password, setPassword] = React.useState<string>();
  const [data, setData] = React.useState<PubNubDataResult>();

  const handleScan = React.useCallback(async(value) => {
    setIsLoading(true);

    if (value && value.search('zilpay-sync:') !== -1) {
      const field = PubNubWrapper.FIELD;
      const [channelName, cipherKey] = value.replace(`${field}:`, '').split('|@|');
      const pubnubWrapper = new PubNubWrapper(channelName, cipherKey);

      try {
        const data = await pubnubWrapper.startSync();

        setData(data);
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
  const handleDecrypt = React.useCallback(() => {
    setIsLoading(true);
    const encryptor = new Encryptor('');

    console.log(JSON.stringify(data, null, 4));

    // encryptor.decrypt(password);

    setIsLoading(false);
  }, [password, data]);

  return (
    <React.Fragment>
      {!data ? (
        <SafeAreaView style={[styles.container, {
          backgroundColor: colors.background
        }]}>
          <Text style={styles.title}>
            {i18n.t('connect_title')}
          </Text>
          <View>
            {STEPS.map((step, index) => (
              <Text
                style={styles.stepText}
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
            <Text style={styles.title}>
              {i18n.t('connect_title_decrypt')}
            </Text>
            <Passwordinput
              placeholder={i18n.t('pass_setup_input1')}
              onChange={setPassword}
            />
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
  scanBtn: {
    width: '70%',
    marginTop: 30
  }
});

export default WalletConnectPage;
