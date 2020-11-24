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
  ScrollView,
  TouchableOpacity,
  Button,
  ViewStyle
} from 'react-native';
import { useStore } from 'effector-react';
import { SvgXml } from 'react-native-svg';

import Modal from 'react-native-modal';
import { AccountItem } from 'app/components/account-item';
import { DeleteIconSVG } from 'app/components/svg';

import { keystore } from 'app/keystore';
import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
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
};

export const AccountsModal: React.FC<Prop> = ({
  title,
  style,
  accounts,
  visible,
  selected,
  onTriggered,
  onAdd,
  onSelected
}) => {
  const settings = useStore(keystore.settings.store);

  const handleSelected = React.useCallback((index) => {
    onSelected(index);
    onTriggered();
  }, [onTriggered, onSelected]);

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
      <View style={[styles.modalContainer, style]}>
        <View style={styles.titleWrapper}>
          <Text style={styles.title}>
            {title}
          </Text>
          <TouchableOpacity onPress={onTriggered}>
            <SvgXml xml={DeleteIconSVG}/>
          </TouchableOpacity>
        </View>
        <ScrollView style={{ marginVertical: 20 }}>
          {accounts.map((account, index) => (
            <AccountItem
              key={index}
              account={account}
              format={settings.addressFormat}
              selected={selected === index}
              onPress={() => handleSelected(index)}
            />
          ))}
        </ScrollView>
        {onAdd ? (
          <Button
            title={i18n.t('account_menu_add')}
            color={theme.colors.primary}
            onPress={onAdd}
          />
        ) : null}
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  title: {
    color: theme.colors.white,
    fontSize: 17,
    lineHeight: 22
  },
  modalContainer: {
    paddingHorizontal: 15,
    borderTopEndRadius: 16,
    borderTopStartRadius: 16,
    backgroundColor: '#18191D',
    justifyContent: 'space-between',
    paddingVertical: 15
  },
  titleWrapper: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: 15
  }
});
