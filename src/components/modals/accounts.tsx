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
  View
} from 'react-native';
import { useTheme } from '@react-navigation/native';

import Modal from 'react-native-modal';
import { AccountItem } from 'app/components/account-item';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { CustomButton } from 'app/components/custom-button';

import { keystore } from 'app/keystore';
import i18n from 'app/lib/i18n';
import { Account } from 'types';

type Prop = {
  style?: ViewStyle;
  selected?: number;
  visible: boolean;
  title: string;
  accounts: Account[];
  onTriggered: () => void;
  onSelected: (index: number) => void;
  onAdd?: () => void;
  onRemove?: () => void;
};

export const AccountsModal: React.FC<Prop> = ({
  title,
  style,
  accounts,
  visible,
  selected,
  onTriggered,
  onAdd,
  onSelected,
  onRemove
}) => {
  const { colors, dark } = useTheme();
  const settingsState = keystore.settings.store.useValue();

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
          {title}
        </ModalTitle>
        <ScrollView style={{ marginVertical: 20 }}>
          {accounts.map((account, index) => (
            <AccountItem
              key={index}
              last={index === accounts.length - 1}
              account={account}
              format={settingsState.addressFormat}
              selected={selected === index}
              onPress={() => onSelected(index)}
            />
          ))}
        </ScrollView>
        <View style={[styles.actionsWrapper, {
          height: selected && selected !== 0 ? 100 : undefined,
        }]}>
          {onAdd ? (
            <CustomButton
              title={i18n.t('account_menu_add')}
              onPress={onAdd}
            />
          ) : null}
          {onRemove && selected !== 0 ? (
            <CustomButton
              title={i18n.t('account_menu_rm')}
              style={{
                backgroundColor: colors['danger']
              }}
              onPress={onRemove}
            />
          ) : null}
        </View>
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  actionsWrapper: {
    justifyContent: 'space-between',
    marginBottom: 15
  }
});
