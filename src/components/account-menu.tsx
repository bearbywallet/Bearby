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

import { DropDownItem } from 'app/components/drop-down-item';
import { ArrowIconSVG } from 'app/components/svg';
import { AccountsModal } from 'app/components/modals';

import { keystore } from 'app/keystore';
import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  accountName: string;
  onCreate: () => void;
};

export const AccountMenu: React.FC<Prop> = ({ accountName, style, onCreate }) => {
  const accountState = useStore(keystore.account.store);

  const [isModal, setIsModal] = React.useState(false);

  const handleCreateAccount = React.useCallback(() => {
    setIsModal(false);
    onCreate();
  }, [setIsModal]);
  const handleChangeAccount = React.useCallback(async(index) => {
    await keystore.account.selectAccount(index);
    await keystore.transaction.sync();
  }, []);

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
