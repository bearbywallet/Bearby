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
  TouchableOpacity
} from 'react-native';
import { useTheme } from '@react-navigation/native';

import ProfileSVG from 'app/assets/icons/profile.svg';
import ArrowIconSVG from 'app/assets/icons/arrow.svg';

import { AccountsModal } from 'app/components/modals';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { trim } from 'app/filters';
import { Account } from 'types';

import styles from './styles';

type Prop = {
  accounts: Account[];
  selected: number;
  onSelect?: (index: number) => void;
};

export const TransferAccount: React.FC<Prop> = ({
  accounts,
  selected,
  onSelect
}) => {
  const { colors } = useTheme();
  const settingsState = keystore.settings.store.useValue();

  const [isAccountModal, setIsAccountModal] = React.useState(false);

  const account = React.useMemo(
    () => accounts[selected],
    [accounts, selected]
  );

  const hanldeSelectAccount = React.useCallback((index) => {
    setIsAccountModal(false);
    if (onSelect) {
      onSelect(index);
    }
  }, [setIsAccountModal, onSelect]);

  return (
    <React.Fragment>
      <TouchableOpacity
        style={styles.item}
        onPress={() => setIsAccountModal(true)}
      >
        <ProfileSVG
          height={20}
          width={20}
        />
        <View style={[styles.itemInfo, {
          borderColor: colors.border,
          borderBottomWidth: 1
        }]}>
          <Text style={[styles.label, {
            color: colors.border
          }]}>
            {i18n.t('transfer_account')}
          </Text>
          <View style={styles.infoWrapper}>
            <Text style={[styles.nameAmountText, {
              color: colors.text
            }]}>
              {account.name}
            </Text>
          </View>
          <View style={[styles.infoWrapper, { marginBottom: 15 }]}>
            <Text style={[styles.addressAmount, {
              color: colors.border
            }]}>
              {trim(account[settingsState.addressFormat])}
            </Text>
          </View>
        </View>
        <ArrowIconSVG
          fill={colors.notification}
          style={styles.arrowIcon}
        />
      </TouchableOpacity>
      {onSelect ? (
        <AccountsModal
          title={i18n.t('transfer_modal_title1')}
          visible={isAccountModal}
          selected={selected}
          onTriggered={() => setIsAccountModal(false)}
          accounts={accounts}
          onSelected={hanldeSelectAccount}
        />
      ) : null}
    </React.Fragment>
  );
};
