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
import { StackNavigationProp } from '@react-navigation/stack';
import { w3cwebsocket as W3cwebsocket } from "websocket";

import { QRScaner } from 'app/components/modals/qr-scaner';
import { CustomButton } from 'app/components/custom-button';
import { Passwordinput } from 'app/components/password-input';
import { Switcher } from 'app/components/switcher';
import { UnauthorizedStackParamList } from 'app/navigator/unauthorized';

import i18n from 'app/lib/i18n';
import { ZilPayConnect } from 'app/config/wallet-connect';
import { fonts } from 'app/styles';
import { sha256 } from 'app/lib/crypto';
import { ZilPayConnectContent, EncryptedWallet } from 'types';
import { keystore } from 'app/keystore';
import { AccountTypes, TokenTypes, ZILLIQA_KEYS } from 'app/config';

type Prop = {
  navigation: StackNavigationProp<UnauthorizedStackParamList>;
};

const Aes = NativeModules.Aes;
const [mainnet] = ZILLIQA_KEYS;
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
  const [data, setData] = React.useState<ZilPayConnectContent>();
  const [isBiometric, setIsBiometric] = React.useState(Boolean(authState.supportedBiometryType));
  const [biometric, setBiometric] = React.useState<string>();

  const handleScan = React.useCallback(async(value: string) => {
    setIsLoading(true);

    const [uuid, iv] = value.split('/');

    if (uuid && iv) {
      try {
        const client = new W3cwebsocket(
          ZilPayConnect.Host,
          ZilPayConnect.Protocol
        );

        client.onerror = function() {
          client.close();
        };
        client.onmessage = function(e) {
          try {
            const parsed = JSON.parse(String(e.data));
            setData({
              ...parsed.data,
              iv
            });
          } catch (err) {
            // console.log('parse', err);
          } finally {
            client.close();
          }
        };

        client.onopen = function() {
          if (client.readyState === client.OPEN) {
            client.send(JSON.stringify({
              type: 'Connect',
              data: '',
              uuid
            }));
          }
        };
      } catch (err) {
        Alert.alert(
          i18n.t('connect_invalid_qr_code_title'),
          (err as Error).message
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
      const decrypted: EncryptedWallet = JSON.parse(content);

      await keystore.initWallet(password, decrypted.seed);
      await keystore.account.reset();
      await keystore.transaction.sync();
      await keystore.token.reset();
      await keystore.guard.auth.secureKeychain.reset();

      for (const token of data.zrc2) {
        try {
          await keystore.token.addToken({
            type: TokenTypes.ZRC2,
            decimals: token.decimals,
            address: {
              [mainnet]: token.base16
            },
            name: token.name,
            symbol: token.symbol,
            rate: token.rate
          });
        } catch {
          continue;
        }
      }

      for (const account of data.wallet.identities) {
        try {
          if (account.type === AccountTypes.Seed) {
            await keystore.addAccount(
              decrypted.seed,
              account.name,
              account.index
            );
          } else if (account.type === AccountTypes.privateKey) {
            const found = decrypted.keys.find(
              (el) => el.index === account.index
            );
            if (!found) {
              continue;
            }
            await keystore.addPrivateKeyAccount(
              found.privateKey,
              account.name,
              password
            );
          }
        } catch {
          continue;
        }
      }

      try {
        await keystore.account.balanceUpdate();
      } catch {
        //
      }

      if (isBiometric) {
        await keystore.guard.auth.initKeychain(password);
      }

      await keystore.account.selectAccount(data.wallet.selectedAddress);

      navigation.navigate('InitSuccessfully');
    } catch (err) {
      setPasswordError((err as Error).message);
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
        <View style={[styles.container, {
          alignItems: 'center'
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
        </View>
      ) : (
        <View style={styles.container}>
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
        </View>
      )}
    </React.Fragment>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 16
  },
  title: {
    fontFamily: fonts.Bold,
    textAlign: 'center',
    fontSize: 16,
    lineHeight: 40,
    marginTop: 16
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
