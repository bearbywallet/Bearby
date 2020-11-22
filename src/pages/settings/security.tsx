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
  Text,
  Button,
  ScrollView,
  StyleSheet
} from 'react-native';
import { useStore } from 'effector-react';
import { SvgXml } from 'react-native-svg';

import { Selector } from 'app/components/selector';
import { Switcher } from 'app/components/switcher';
import Modal from 'react-native-modal';
import { DeleteIconSVG } from 'app/components/svg';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { theme } from 'app/styles';

const times = [
  {
    time: 1,
    name: `1 ${i18n.t('hour')}`
  },
  {
    time: 3,
    name: `3 ${i18n.t('hours')}`
  },
  {
    time: 5,
    name: `5 ${i18n.t('hours')}`
  },
];
export const SecurityPage: React.FC = () => {
  const authState = useStore(keystore.guard.auth.store);
  const [hour, sethour] = React.useState(0);
  const [modalVisible, setModalVisible] = React.useState(false);

  const hanldeChangeBiometric = React.useCallback((value) => {
    keystore.guard.auth.updateBiometric(value);
  }, [authState.biometricEnable]);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.titleWrapper}>
        <Text style={styles.title}>
          {i18n.t('security_title')}
        </Text>
      </View>
      <ScrollView>
        <Selector
          style={{ marginVertical: 16 }}
          title={i18n.t('security_lock')}
          items={times.map((item) => item.name)}
          selected={times[hour].name}
          onSelect={(_, index) => sethour(index)}
        />
        <Switcher
          style={styles.biometric}
          enabled={authState.biometricEnable}
          onChange={hanldeChangeBiometric}
        >
          <View>
            <Text style={styles.biometricText}>
              {i18n.t('use')} {authState.supportedBiometryType}
            </Text>
            <Text style={styles.biometricLabel}>
              {i18n.t('biometric_description')}
            </Text>
          </View>
        </Switcher>
        <Button
          title={i18n.t('security_btn0')}
          color={theme.colors.primary}
          onPress={() => null}
        />
        <Button
          title={i18n.t('security_btn1')}
          color={theme.colors.primary}
          onPress={() => setModalVisible(true)}
        />
        <Modal
          isVisible={modalVisible}
          onSwipeComplete={() => setModalVisible(false)}
          swipeDirection={['up', 'left', 'right', 'down']}
          style={{
            justifyContent: 'flex-end',
            margin: 0
          }}
        >
          <View>
            <View>
              <Text>
                Reveal private key
              </Text>
              <SvgXml
                xml={DeleteIconSVG}
                onTouchEnd={() => setModalVisible(false)}
              />
            </View>
          </View>
        </Modal>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
  },
  titleWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: '10%',
    paddingHorizontal: 15
  },
  title: {
    color: theme.colors.white,
    fontSize: 34,
    lineHeight: 41,
    fontWeight: 'bold'
  },
  biometric: {
    backgroundColor: theme.colors.gray,
    paddingVertical: 15,
    paddingHorizontal: 15
  },
  biometricText: {
    fontSize: 17,
    lineHeight: 22,
    color: theme.colors.white
  },
  biometricLabel: {
    fontSize: 16,
    lineHeight: 21,
    color: '#8A8A8F'
  }
});

export default SecurityPage;
