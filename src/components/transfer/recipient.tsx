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
  Text,
  TouchableOpacity,
  StyleSheet,
  View,
  ViewStyle
} from 'react-native';
import { useTheme } from '@react-navigation/native';

import ReceiveIconSVG from 'app/assets/icons/receive.svg';
import ProfileSVG from 'app/assets/icons/profile.svg';
import BookIconSVG from 'app/assets/icons/book.svg';

import {
  AccountsModal,
  ContactsModal
} from 'app/components/modals';
import { QrCodeInput } from 'app/components/qr-code-input';

import i18n from 'app/lib/i18n';
import coomonStyles from './styles';
import { isBech32 } from 'app/utils/address';
import { Account, Contact } from 'types';
import { fonts } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  accounts: Account[];
  contacts: Contact[];
  recipient: string;
  onSelect: (address: string) => void;
  onError?: (error: boolean) => void;
};

export const TransferRecipient: React.FC<Prop> = ({
  style,
  recipient,
  accounts,
  contacts,
  onSelect,
  onError = () => null
}) => {
  const { colors } = useTheme();
  const [error, setError] = React.useState(false);
  const [accountModal, setAccountModal] = React.useState(false);
  const [contactModal, setContactModal] = React.useState(false);

  const handleSelect = React.useCallback((address) => {
    if (!address || !isBech32(address)) {
      setError(true);
    }

    onSelect(address);
    setAccountModal(false);
    onError(error);
  }, [onSelect, setError, error]);

  return (
    <React.Fragment>
      <View style={style}>
        <View style={coomonStyles.receiving}>
          <ReceiveIconSVG />
          <QrCodeInput
            zns
            placeholder={i18n.t('transfer_view0')}
            value={recipient}
            onChange={onSelect}
          />
        </View>
        <View style={styles.itemsWrapper}>
          <TouchableOpacity
            style={[styles.item, {
              backgroundColor: colors.background
            }]}
            onPress={() => setAccountModal(true)}
          >
            <ProfileSVG />
            <Text style={[styles.textItem, {
              color: colors.text
            }]}>
              {i18n.t('my_accounts')}
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.item, {
              backgroundColor: colors.background
            }]}
            disabled={contacts.length === 0}
            onPress={() => setContactModal(true)}
          >
            <BookIconSVG />
            <Text style={[styles.textItem, {
              color: colors.text
            }]}>
              {i18n.t('my_contacts')}
            </Text>
          </TouchableOpacity>
        </View>
      </View>
      <AccountsModal
        title={i18n.t('transfer_modal_title1')}
        visible={accountModal}
        onTriggered={() => setAccountModal(false)}
        accounts={accounts}
        onSelected={(index) => handleSelect(accounts[index].bech32)}
      />
      <ContactsModal
        title={i18n.t('transfer_modal_title2')}
        visible={contactModal}
        contacts={contacts}
        onTriggered={() => setContactModal(false)}
        onSelected={(index) => onSelect(contacts[index].address)}
      />
    </React.Fragment>
  );
};

const styles = StyleSheet.create({
  itemsWrapper: {
    flexDirection: 'row',
    justifyContent: 'space-evenly'
  },
  item: {
    padding: 10,
    width: 70,
    height: 70,
    alignItems: 'center',
    justifyContent: 'space-between',
    borderRadius: 8,
    marginBottom: 5
  },
  textItem: {
    textAlign: 'center',
    fontFamily: fonts.Regular,
    fontSize: 10
  }
});
