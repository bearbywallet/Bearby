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
  ViewStyle,
  View,
  Image,
  Dimensions,
  Text
} from 'react-native';
import Modal from 'react-native-modal';
import { useTheme } from '@react-navigation/native';

import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { Switcher } from 'app/components/switcher';
import { CustomButton } from 'app/components/custom-button';
import { Passwordinput } from 'app/components/password-input';
import { ErrorMessage } from 'app/components/error-message';

import i18n from 'app/lib/i18n';
import { Signature, Account } from 'types';
import { sha256 } from 'app/lib/crypto/sha256';
import { keystore } from 'app/keystore';
import { SchnorrControl } from 'app/lib/controller';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  title: string;
  icon?: string;
  payload?: string;
  appTitle?: string;
  account: Account;
  needPassword?: boolean;
  onTriggered: () => void;
  onSign: (sig: Signature) => void;
};

const { width } = Dimensions.get('window');
export const SignMessageModal: React.FC<Prop> = ({
  style,
  visible,
  title,
  icon,
  payload,
  appTitle,
  account,
  needPassword,
  onTriggered,
  onSign
}) => {
  const { colors, dark } = useTheme();
  const [isHash, setIsHash] = React.useState(false);
  const [hash, setHash] = React.useState('');
  const [passowrd, setPassowrd] = React.useState<string>('');
  const [error, setError] = React.useState<string>();

  const handleSign = React.useCallback(async() => {
    setError(undefined);
    if (!payload || !hash) {
      return null;
    }

    try {
      const bytes = Buffer.from(hash, 'hex');
      const keyPair = await keystore.getkeyPairs(account, passowrd);
      const schnorrControl = new SchnorrControl(keyPair.privateKey);
      const signature = schnorrControl.getSignature(bytes);

      onSign({
        signature,
        message: payload,
        publicKey: keyPair.publicKey
      });
    } catch (err) {
      setError(err.message);
    }
  }, [hash, account, payload, passowrd]);

  React.useEffect(() => {
    if (payload) {
      sha256(payload).then(setHash);
    }
  }, [payload]);

  if (!icon || !payload || !appTitle) {
    return null;
  }

  return (
    <Modal
      isVisible={visible}
      style={{
        justifyContent: 'flex-end',
        margin: 0,
        marginBottom: 1
      }}
      backdropColor={dark ? '#ffffff5' : '#00000060'}
      onBackdropPress={onTriggered}
    >
      <ModalWrapper style={style}>
        <ModalTitle onClose={onTriggered}>
          {appTitle} {title}
        </ModalTitle>
        <View style={styles.wrapper}>
          <Image
            style={styles.icon}
            source={{ uri: icon }}
          />
          <ErrorMessage>
            {error}
          </ErrorMessage>
          <Text style={[styles.desc, {
            color: colors.border
          }]}>
            {i18n.t('sign_des')}
          </Text>
          <Switcher
            style={styles.switcher}
            enabled={isHash}
            onChange={setIsHash}
          >
            <Text style={[styles.wwitcherText, {
              color: colors.notification
            }]}>
              {isHash ? 'Hash' : 'Payload'}
            </Text>
          </Switcher>
          <View style={[styles.sigWrapper, {
            backgroundColor: colors.background
          }]}>
            <Text style={[styles.sig, {
              color: colors.text
            }]}>
              {isHash ? hash : payload}
            </Text>
          </View>
          {needPassword ? (
            <Passwordinput
              style={{
                marginVertical: 15
              }}
              placeholder={i18n.t('pass_setup_input1')}
              onChange={setPassowrd}
            />
          ) : null}
          <CustomButton
            style={styles.signBtn}
            title={i18n.t('sign')}
            disabled={needPassword && !passowrd}
            onPress={handleSign}
          />
        </View>
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  wwitcherText: {
    fontSize: 13,
    lineHeight: 17
  },
  wrapper: {
    alignItems: 'center',
    marginVertical: 30
  },
  desc: {
    fontSize: 17,
    lineHeight: 22
  },
  switcher: {
    alignSelf: 'flex-end',
    marginVertical: 15
  },
  icon: {
    height: 30,
    width: 30,
    marginVertical: 15
  },
  sigWrapper: {
    alignItems: 'flex-start',
    width: '100%',
    borderRadius: 8
  },
  sig: {
    fontSize: 13,
    lineHeight: 17,
    padding: 10,
    margin: 15,
    minHeight: 100
  },
  signBtn: {
    minWidth: width / 2
  },
  cancelBtn: {
    minWidth: width / 4
  }
});
