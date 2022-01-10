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
  Dimensions,
  View
} from 'react-native';
import Modal from 'react-native-modal';
import { useTheme } from '@react-navigation/native';
import FastImage from 'react-native-fast-image';

import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { CustomButton } from 'app/components/custom-button';

import i18n from 'app/lib/i18n';
import { MessagePayload } from 'types';
import { fonts } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  app?: MessagePayload;
  visible: boolean;
  onTriggered: () => void;
  onConfirm: () => void;
};
const { width } = Dimensions.get('window');
export const ConnectModal: React.FC<Prop> = ({
  style,
  app,
  visible,
  onConfirm,
  onTriggered
}) => {
  const { colors, dark } = useTheme();

  return (
    <Modal
      isVisible={visible}
      style={{
        justifyContent: 'flex-end',
        margin: 0,
        marginBottom: 1
      }}
      backdropColor={colors['modal']}
      onBackdropPress={onTriggered}
    >
      <ModalWrapper style={style}>
        <ModalTitle onClose={onTriggered}>
          {i18n.t('connect_btn0')} {app && app.icon ? (
            <FastImage
              style={styles.icon}
              source={{ uri: app.icon }}
            />
          ) : null}
        </ModalTitle>
        <ScrollView>
          {app && app.icon && app.title ? (
            <View style={[styles.appWrapper, {
              backgroundColor: colors.card
            }]}>
              <Text style={[styles.appTitle, {
                color: colors.text
              }]}>
                {app.title}({app.domain})
              </Text>
              <Text style={[styles.appDes, {
                color: colors.notification
              }]}>
                {app.title} {i18n.t('connect_title_question')}
              </Text>
            </View>
          ) : null}
          <Text style={[styles.textInfo, {
            color: colors.text
          }]}>
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
    borderRadius: 8,
    padding: 10,
    marginVertical: 30
  },
  appTitle: {
    fontSize: 17,
    fontFamily: fonts.Demi,
    marginBottom: 10
  },
  appDes: {
    textAlign: 'center',
    fontSize: 13,
    fontFamily: fonts.Regular,
  },
  textInfo: {
    textAlign: 'center',
    marginVertical: 15,
    fontSize: 17,
    fontFamily: fonts.Regular
  },
  icon: {
    width: 30,
    height: 30
  }
});
