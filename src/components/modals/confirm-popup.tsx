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
  ViewStyle
} from 'react-native';

import Modal from 'react-native-modal';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  title: string;
  onTriggered: () => void;
};

export const ConfirmPopup: React.FC<Prop> = ({
  title,
  style,
  visible,
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
        <ModalTitle
          style={{ padding: 15 }}
          onClose={onTriggered}
        >
          {title}
        </ModalTitle>
        <ScrollView style={{ marginVertical: 20 }}>
        </ScrollView>
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
});
