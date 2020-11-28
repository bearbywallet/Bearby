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
  TouchableOpacity,
  ScrollView,
  ViewStyle
} from 'react-native';
import Modal from 'react-native-modal';

import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { keystore } from 'app/keystore';
import { Transaction } from 'types';
import { trim } from 'app/filters';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  transaction: Transaction;
  onTriggered: () => void;
};

export const TransactionModal: React.FC<Prop> = ({
  style,
  transaction,
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
        <ModalTitle onClose={onTriggered}>
          {i18n.t('history_tx_details')}
        </ModalTitle>
        <ScrollView>
          <TouchableOpacity style={styles.txItem}>
            <Text style={styles.txLable}>
              {i18n.t('transfer_account')}
            </Text>
            {transaction ? (
              <Text style={styles.txValue}>
                {trim(transaction.from)}
              </Text>
            ) : null}
          </TouchableOpacity>
        </ScrollView>
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  txItem: {
    padding: 10,
    margin: 5
  },
  txLable: {
    color: '#8A8A8F',
    fontSize: 16,
    lineHeight: 21
  },
  txValue: {
    color: theme.colors.white,
    fontSize: 17,
    lineHeight: 22
  }
});
