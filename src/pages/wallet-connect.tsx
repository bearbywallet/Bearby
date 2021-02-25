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
  Dimensions,
  Alert
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import SafeAreaView from 'react-native-safe-area-view';
import { StackNavigationProp } from '@react-navigation/stack';

import { QRScaner } from 'app/components/modals/qr-scaner';
import { CustomButton } from 'app/components/custom-button';

import { UnauthorizedStackParamList } from 'app/navigator/unauthorized';
import i18n from 'app/lib/i18n';
import { fonts } from 'app/styles';
import { PubNubWrapper } from 'app/lib/controller/connect';

type Prop = {
  navigation: StackNavigationProp<UnauthorizedStackParamList>;
};

const STEPS = [
  i18n.t('connect_step0'),
  i18n.t('connect_step1'),
  i18n.t('connect_step2'),
  i18n.t('connect_step3')
];

const { height } = Dimensions.get('window');
export const WalletConnectPage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();
  const [qrcodeModal, setQrcodeModal] = React.useState(false);

  const handleScan = React.useCallback(async(value) => {
    if (value && value.search('zilpay-sync:') !== -1) {
      const field = PubNubWrapper.FIELD;
      const [channelName, cipherKey] = value.replace(`${field}:`, '').split('|@|');
      const pubnubWrapper = new PubNubWrapper(channelName, cipherKey);

      pubnubWrapper.startSync();

      // await pubnubWrapper.establishConnection(cipherKey, channelName);
    } else {
      Alert.alert(
        i18n.t('connect_invalid_qr_code_title'),
        i18n.t('connect_invalid_qr_code_des')
      );
    }
  }, []);


  return (
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
        onPress={() => setQrcodeModal(true)}
      />
      <QRScaner
        visible={qrcodeModal}
        onTriggered={() => setQrcodeModal(false)}
        onScan={handleScan}
      />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center'
  },
  title: {
    fontFamily: fonts.Bold,
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
