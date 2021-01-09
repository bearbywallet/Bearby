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
  StyleSheet,
  TouchableOpacity,
  ViewStyle
} from 'react-native';
import { useTheme } from '@react-navigation/native';

import { AddTokenModal } from 'app/components/modals';

import i18n from 'app/lib/i18n';
import { Account, Token } from 'types';

export type Prop = {
  style?: ViewStyle;
  account: Account;
  onAddToken: (token: Token, cb: () => void) => void;
};

export const AddToken: React.FC<Prop> = ({ style, account, onAddToken }) => {
  const { colors } = useTheme();
  const [modalVisible, setModalVisible] = React.useState(false);

  return (
    <React.Fragment>
      <TouchableOpacity
        style={[styles.container, style, {
          backgroundColor: colors['card1']
        }]}
        onPress={() => setModalVisible(true)}
      >
        <View style={[styles.line, styles.line0, {
          backgroundColor: colors.primary
        }]}/>
        <View style={[styles.line, {
          backgroundColor: colors.primary
        }]}/>
      </TouchableOpacity>
      <AddTokenModal
        account={account}
        title={i18n.t('add_token')}
        visible={modalVisible}
        onTriggered={() => setModalVisible(false)}
        onAddToken={onAddToken}
      />
    </React.Fragment>
  );
};

const styles = StyleSheet.create({
  container: {
    borderRadius: 8,
    minHeight: 90,
    width: '47%',
    padding: 10,
    justifyContent: 'center',
    alignItems: 'center'
  },
  line: {
    width: 30,
    height: 3,
    borderRadius: 5
  },
  line0: {
    transform: [{ rotate: '90deg' }, { translateX: 3 }]
  }
});
