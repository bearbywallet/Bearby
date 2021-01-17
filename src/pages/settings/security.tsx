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
  ScrollView,
  StyleSheet
} from 'react-native';
import SafeAreaView from 'react-native-safe-area-view';
import { StackNavigationProp } from '@react-navigation/stack';
import { useTheme } from '@react-navigation/native';

import { Switcher } from 'app/components/switcher';
import { PasswordModal } from 'app/components/modals';
import { Button } from 'app/components/button';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { RootParamList } from 'app/navigator';
import { SecureTypes } from 'app/config';
import { fonts } from 'app/styles';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

export const SecurityPage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();
  const authState = keystore.guard.auth.store.useValue();
  const accountState = keystore.account.store.useValue();

  const [hour, sethour] = React.useState(0);
  const [modaltitle, setModalTitle] = React.useState('');
  const [modalBtntitle, setModalBtntitle] = React.useState('');
  const [exportType, setExportType] = React.useState<SecureTypes | null>(null);
  const [modalVisible, setModalVisible] = React.useState(false);

  const selectedAccount = React.useMemo(
    () => accountState.identities[accountState.selectedAddress],
    [accountState]
  );

  /**
   * Change biometric swicher.
   */
  const hanldeChangeBiometric = React.useCallback(async(value) => {
    if (value) {
      await keystore.guard.auth.sync();

      setModalBtntitle(i18n.t('enable'));
      setModalTitle(`${i18n.t('enable')} ${authState.supportedBiometryType}`);
      setExportType(SecureTypes.biometric);
      setModalVisible(true);

      return null;
    }

    await keystore.guard.auth.secureKeychain.reset();
    await keystore.guard.auth.sync();
  }, [authState.biometricEnable]);
  /**
   * Export PrivateKey from current account.
   */
  const hanldeRevealPrivateKey = React.useCallback(async() => {
    if (authState.biometricEnable) {
      const currentAccount = keystore.account.getCurrentAccount();
      const account = await keystore.getkeyPairs(currentAccount);

      return navigation.navigate('SettingsPages', {
        screen: 'Export',
        params: {
          type: SecureTypes.privateKey,
          content: String(account.privateKey)
        }
      });
    }

    setModalTitle(i18n.t('security_btn0'));
    setModalBtntitle(i18n.t('security_btn_modal0'));
    setExportType(SecureTypes.privateKey);
    setModalVisible(true);
  }, [authState.biometricEnable]);
  /**
   * Export secret phrase.
   */
  const hanldeRevealSecretPhrase = React.useCallback(async() => {
    if (authState.biometricEnable) {
      const SecretPhrase = await keystore.guard.getMnemonic();

      return navigation.navigate('SettingsPages', {
        screen: 'Export',
        params: {
          type: SecureTypes.seed,
          content: SecretPhrase
        }
      });
    }

    setModalTitle(i18n.t('security_btn1'));
    setModalBtntitle(i18n.t('security_btn_modal0'));
    setExportType(SecureTypes.seed);
    setModalVisible(true);
  }, [authState.biometricEnable]);
  const hanldeConfirmPassword = React.useCallback(async(password) => {
    if (exportType === SecureTypes.biometric) {
      await keystore.guard.auth.initKeychain(password);
    } else if (exportType === SecureTypes.privateKey) {
      const currentAccount = keystore.account.getCurrentAccount();
      const account = await keystore.getkeyPairs(currentAccount, password);

      navigation.navigate('SettingsPages', {
        screen: 'Export',
        params: {
          type: SecureTypes.privateKey,
          content: String(account.privateKey)
        }
      });
    } else if (exportType === SecureTypes.seed) {
      const SecretPhrase = await keystore.guard.getMnemonic(password);

      navigation.navigate('SettingsPages', {
        screen: 'Export',
        params: {
          type: SecureTypes.seed,
          content: SecretPhrase
        }
      });
    }

    setExportType(null);
    setModalVisible(false);
  }, [exportType]);

  return (
    <SafeAreaView style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <View style={styles.titleWrapper}>
        <Text style={[styles.title, {
          color: colors.text
        }]}>
          {i18n.t('security_title')}
        </Text>
      </View>
      <ScrollView style={styles.wrapper}>
        {authState.supportedBiometryType ? (
          <Switcher
            style={{
              ...styles.biometric,
              backgroundColor: colors.card
            }}
            enabled={authState.biometricEnable}
            onChange={hanldeChangeBiometric}
          >
            <View style={styles.switcherWrapper}>
              <Text style={[styles.biometricText, {
                color: colors.text
              }]}>
                {i18n.t('use')} {authState.supportedBiometryType}
              </Text>
              <Text style={[styles.biometricLabel, {
                color: colors.border
              }]}>
                {i18n.t('biometric_description')}
              </Text>
            </View>
          </Switcher>
        ) : null}
        <View style={[styles.btnWrapper, {
          backgroundColor: colors.card
        }]}>
          <Button
            title={i18n.t('security_btn0')}
            color={colors.primary}
            onPress={hanldeRevealPrivateKey}
          />
          <Text style={[styles.btnDesText, {
            color: colors.border
          }]}>
            {i18n.t('security_des0', { account: selectedAccount.name })}
          </Text>
        </View>
        <View style={[styles.btnWrapper, {
          backgroundColor: colors.card
        }]}>
          <Button
            title={i18n.t('security_btn1')}
            color={colors.primary}
            onPress={hanldeRevealSecretPhrase}
          />
          <Text style={[styles.btnDesText, {
            color: colors.border
          }]}>
            {i18n.t('security_des1')}
          </Text>
        </View>
        <PasswordModal
          visible={modalVisible}
          title={modaltitle}
          btnTitle={modalBtntitle}
          onTriggered={() => setModalVisible(false)}
          onConfirmed={hanldeConfirmPassword}
        />
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  wrapper: {
    paddingVertical: 15
  },
  titleWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: '10%',
    paddingHorizontal: 15
  },
  title: {
    fontSize: 30,
    fontFamily: fonts.Bold
  },
  biometric: {
    paddingVertical: 15,
    paddingHorizontal: 15
  },
  biometricText: {
    fontSize: 17,
    fontFamily: fonts.Demi
  },
  biometricLabel: {
    fontSize: 16,
    fontFamily: fonts.Regular
  },
  switcherWrapper: {
    maxWidth: '70%'
  },
  btnWrapper: {
    marginTop: 32,
    alignItems: 'flex-start',
    padding: 15
  },
  btnDesText: {
    fontFamily: fonts.Regular,
    fontSize: 16
  }
});

export default SecurityPage;
