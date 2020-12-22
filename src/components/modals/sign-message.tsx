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

import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { Switcher } from 'app/components/switcher';
import { CustomButton } from 'app/components/custom-button';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
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
  onTriggered: () => void;
  onSign: (sig: Signature) => void;
  onReject: () => void;
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
  onTriggered,
  onSign,
  onReject
}) => {
  const [isHash, setIsHash] = React.useState(false);
  const [hash, setHash] = React.useState('');

  React.useEffect(() => {
    if (payload) {
      sha256(payload).then(setHash);
    }
  }, [payload]);

  const handleSign = React.useCallback(async() => {
    if (!payload || !hash) {
      return null;
    }

    const bytes = Buffer.from(hash, 'hex');
    const keyPair = await keystore.getkeyPairs(account);
    const schnorrControl = new SchnorrControl(keyPair.privateKey);
    const signature = schnorrControl.getSignature(bytes);

    onSign({
      signature,
      message: payload,
      publicKey: keyPair.publicKey
    });
  }, [onSign, hash, account, payload]);

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
          <Text style={styles.desc}>
            {i18n.t('sign_des')}
          </Text>
          <Switcher
            style={styles.switcher}
            enabled={isHash}
            onChange={setIsHash}
          >
            <Text style={styles.wwitcherText}>
              {isHash ? 'Hash' : 'Payload'}
            </Text>
          </Switcher>
          <View style={styles.sigWrapper}>
            <Text style={styles.sig}>
              {isHash ? hash : payload}
            </Text>
          </View>
          <View style={styles.btnWrapper}>
            <CustomButton
              style={styles.cancelBtn}
              title={i18n.t('cancel')}
              onPress={onReject}
            />
            <CustomButton
              style={styles.signBtn}
              title={i18n.t('sign')}
              color={theme.colors.warning}
              onPress={handleSign}
            />
          </View>
        </View>
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  wwitcherText: {
    color: theme.colors.muted
  },
  wrapper: {
    alignItems: 'center',
    marginVertical: 30
  },
  desc: {
    color: theme.colors.muted,
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
    backgroundColor: theme.colors.black,
    width: '100%',
    borderRadius: 8
  },
  sig: {
    color: theme.colors.white,
    fontSize: 13,
    lineHeight: 17,
    padding: 10,
    margin: 15
  },
  btnWrapper: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    width: '100%',
    paddingVertical: 15
  },
  signBtn: {
    minWidth: width / 4,
    backgroundColor: 'transparent',
    borderColor: theme.colors.warning,
    borderWidth: 1
  },
  cancelBtn: {
    minWidth: width / 4
  }
});
