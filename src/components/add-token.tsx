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

import { AddTokenModal } from 'app/components/modals';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';
import { Account } from 'types';

export type Prop = {
  style?: ViewStyle;
  account: Account;
};

export const AddToken: React.FC<Prop> = ({ style, account }) => {
  const [modalVisible, setModalVisible] = React.useState(false);

  return (
    <React.Fragment>
      <TouchableOpacity
        style={[styles.container, style]}
        onPress={() => setModalVisible(true)}
      >
        <View style={[styles.line, styles.line0]}/>
        <View style={styles.line}/>
      </TouchableOpacity>
      <AddTokenModal
        account={account}
        title={i18n.t('add_token')}
        visible={modalVisible}
        onTriggered={() => setModalVisible(false)}
      />
    </React.Fragment>
  );
};

const styles = StyleSheet.create({
  container: {
    borderRadius: 8,
    minHeight: 90,
    width: '47%',
    backgroundColor: theme.colors.gray,
    padding: 10,
    borderWidth: 0.9,
    borderColor: theme.colors.gray,

    justifyContent: 'center',
    alignItems: 'center'
  },
  line: {
    width: 30,
    height: 3,
    backgroundColor: theme.colors.primary,
    borderRadius: 5
  },
  line0: {
    transform: [{ rotate: '90deg' }, { translateX: 3 }]
  }
});
