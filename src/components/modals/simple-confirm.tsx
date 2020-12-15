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
  StyleSheet,
  Dimensions,
  ViewStyle
} from 'react-native';
import Modal from 'react-native-modal';

import { CustomButton } from 'app/components/custom-button';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';

import { theme } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  title?: string;
  description?: string;
  btns: string[];
  onTriggered: () => void;
  onConfirmed: () => void;
};

const { width } = Dimensions.get('window');
export const SimpleConfirm: React.FC<Prop> = ({
  style,
  visible,
  title,
  description,
  btns,
  onTriggered,
  onConfirmed
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
          {title}
        </ModalTitle>
        <View>
          <Text style={styles.description}>
            {description}
          </Text>
        </View>
        <View style={styles.btnWraper}>
          <CustomButton
            title={btns[0]}
            style={styles.btn}
            onPress={onTriggered}
          />
          <CustomButton
            title={btns[1]}
            color={theme.colors.danger}
            style={{ ...styles.btn, ...styles.btnConfirm }}
            onPress={onConfirmed}
          />
        </View>
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  description: {
    color: theme.colors.warning,
    marginTop: 4,
    fontSize: 17,
    lineHeight: 22,
    paddingVertical: 15,
    textAlign: 'center'
  },
  btn: {
    minWidth: width / 3
  },
  btnConfirm: {
    borderColor: theme.colors.danger,
    borderWidth: 1,
    backgroundColor: 'transparent',
    color: theme.colors.danger
  },
  btnWraper: {
    paddingVertical: 15,
    flexDirection: 'row',
    justifyContent: 'space-evenly'
  }
});
