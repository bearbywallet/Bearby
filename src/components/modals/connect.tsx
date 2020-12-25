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
  ScrollView,
  ViewStyle,
  Text,
  Image,
  Dimensions,
  View
} from 'react-native';
import Modal from 'react-native-modal';

import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { CustomButton } from 'app/components/custom-button';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { MessagePayload, Account } from 'types';

type Prop = {
  style?: ViewStyle;
  app?: MessagePayload;
  visible: boolean;
  onTriggered: () => void;
  onConfirm: () => void;
  onReject: () => void;
};
const { width } = Dimensions.get('window');
export const ConnectModal: React.FC<Prop> = ({
  style,
  app,
  visible,
  onConfirm,
  onReject,
  onTriggered
}) => {
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
          {i18n.t('connect_btn0')} {app && app.icon ? (
            <Image
              style={styles.icon}
              source={{ uri: app.icon }}
            />
          ) : null}
        </ModalTitle>
        <ScrollView>
          {app && app.icon && app.title ? (
            <View style={styles.appWrapper}>
              <Text style={styles.appTitle}>
                {app.title}({app.origin})
              </Text>
              <Text style={styles.appDes}>
                {app.title} {i18n.t('connect_title_question')}
              </Text>
            </View>
          ) : null}
          <Text style={styles.textInfo}>
            {i18n.t('connect_des')}
          </Text>
          <CustomButton
            title={i18n.t('connect_btn0')}
            style={styles.btn}
            onPress={onConfirm}
          />
        </ScrollView>
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  btn: {
    minWidth: width / 4,
    margin: 30
  },
  appWrapper: {
    alignItems: 'center',
    backgroundColor: theme.colors.gray,
    borderRadius: 8,
    padding: 10,
    marginVertical: 30
  },
  appTitle: {
    color: theme.colors.white,
    fontSize: 17,
    lineHeight: 22,
    marginBottom: 10
  },
  appDes: {
    textAlign: 'center',
    color: theme.colors.muted
  },
  textInfo: {
    textAlign: 'center',
    color: theme.colors.muted,
    marginVertical: 15
  },
  icon: {
    width: 30,
    height: 30
  }
});
