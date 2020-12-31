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
import { useTheme } from '@react-navigation/native';

import { CustomButton } from 'app/components/custom-button';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { fonts } from 'app/styles';

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
  const { colors, dark } = useTheme();

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
          {title}
        </ModalTitle>
        <View>
          <Text style={[styles.description, {
            color: colors.text
          }]}>
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
            color={colors['danger']}
            style={{
              ...styles.btn,
              ...styles.btnConfirm,
              borderColor: colors['danger'],
            }}
            onPress={onConfirmed}
          />
        </View>
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  description: {
    marginTop: 4,
    fontSize: 17,
    fontFamily: fonts.Regular,
    paddingVertical: 15,
    textAlign: 'center'
  },
  btn: {
    minWidth: width / 3
  },
  btnConfirm: {
    borderWidth: 1,
    backgroundColor: 'transparent'
  },
  btnWraper: {
    paddingVertical: 15,
    flexDirection: 'row',
    justifyContent: 'space-evenly'
  }
});
