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
  ViewStyle
} from 'react-native';

import { DropDownItem } from 'app/components/drop-down-item';
import { AccountsModal } from 'app/components/modals';

import { keystore } from 'app/keystore';
import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  accountName: string;
  onCreate?: () => void;
  onRemove?: () => void;
};

export const AccountMenu: React.FC<Prop> = ({
  accountName,
  style,
  onCreate = () => null,
  onRemove = () => null
}) => {
  const accountState = keystore.account.store.useValue();

  const [isModal, setIsModal] = React.useState(false);

  const handleCreateAccount = React.useCallback(() => {
    setIsModal(false);
    onCreate();
  }, [setIsModal]);
  const handleChangeAccount = React.useCallback(async(index) => {
    await keystore.account.selectAccount(index);
    keystore.transaction.sync();

    setIsModal(false);
  }, [setIsModal]);
  const hanldeRemove = React.useCallback(() => {
    setIsModal(false);
    setTimeout(() => onRemove(), 500);
  }, [setIsModal, onRemove]);

  return (
    <View
      style={[styles.container, style]}
    >
      <DropDownItem
        color={theme.colors.white}
        onPress={() => setIsModal(true)}
      >
        {accountName}
      </DropDownItem>
      <AccountsModal
        accounts={accountState.identities}
        selected={accountState.selectedAddress}
        visible={isModal}
        title={i18n.t('accounts')}
        onTriggered={() => setIsModal(false)}
        onSelected={handleChangeAccount}
        onAdd={handleCreateAccount}
        onRemove={hanldeRemove}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 10
  },
  wrapper: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  title: {
    color: theme.colors.white,
    fontSize: 17,
    lineHeight: 22
  }
});
