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
import { ArrowIconSVG, DeleteIconSVG } from 'app/components/svg';

import { keystore } from 'app/keystore';
import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  onCreate: () => void;
};

export const AccountMenu: React.FC<Prop> = ({ style, onCreate }) => {
  const accountState = useStore(keystore.account.store);

  const [isModal, setIsModal] = React.useState(false);

  const handleSelect = React.useCallback(async(index: number) => {
    await keystore.account.selectAccount(index);

    setIsModal(false);
  }, [setIsModal]);

  const handleCreateAccount = React.useCallback(() => {
    setIsModal(false);
    onCreate();
  }, [setIsModal]);

  return (
    <View
      style={[styles.container, style]}
    >
      <TouchableOpacity
        style={styles.wrapper}
        onPress={() => setIsModal(true)}
      >
        <Text style={styles.title}>
          {accountState.identities[accountState.selectedAddress].name}
        </Text>
        <SvgXml
          style={{ marginLeft: 5 }}
          xml={ArrowIconSVG}
        />
      </TouchableOpacity>
      <Modal
        isVisible={isModal}
        style={{
          justifyContent: 'flex-end',
          margin: 0,
          marginBottom: 1
        }}
        onBackdropPress={() => setIsModal(false)}
      >
        <View style={styles.modalContainer}>
          <View style={styles.titleWrapper}>
            <Text style={styles.title}>
              {i18n.t('accounts')}
            </Text>
            <TouchableOpacity onPress={() => setIsModal(false)}>
              <SvgXml xml={DeleteIconSVG}/>
            </TouchableOpacity>
          </View>
          <ScrollView style={{ marginVertical: 20 }}>
            {accountState.identities.map((account, index) => (
              <AccountItem
                key={index}
                account={account}
                selected={accountState.selectedAddress === index}
                onPress={() => handleSelect(index)}
              />
            ))}
          </ScrollView>
          <Button
            title={i18n.t('account_menu_add')}
            color={theme.colors.primary}
            onPress={handleCreateAccount}
          />
        </View>
      </Modal>
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
