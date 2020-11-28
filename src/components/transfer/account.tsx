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
import { SvgXml } from 'react-native-svg';

import {
  ProfileSVG,
  ArrowIconSVG
} from 'app/components/svg';
import { AccountsModal } from 'app/components/modals';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { trim } from 'app/filters';
import { Account } from 'types';

import styles from './styles';

type Prop = {
  accounts: Account[];
  selected: number;
  onSelect: (index: number) => void;
};

export const TransferAccount: React.FC<Prop> = ({ accounts, selected, onSelect }) => {
  const settingsState = keystore.settings.store.useValue();

  const [isAccountModal, setIsAccountModal] = React.useState(false);

  const account = React.useMemo(
    () => accounts[selected],
    [accounts, selected]
  );

  return (
    <React.Fragment>
      <TouchableOpacity
        style={styles.item}
        onPress={() => setIsAccountModal(true)}
      >
        <SvgXml xml={ProfileSVG} />
        <View style={styles.itemInfo}>
          <Text style={styles.label}>
            {i18n.t('transfer_account')}
          </Text>
          <View style={styles.infoWrapper}>
            <Text style={styles.nameAmountText}>
              {account.name}
            </Text>
          </View>
          <View style={[styles.infoWrapper, { marginBottom: 15 }]}>
            <Text style={styles.addressAmount}>
              {trim(account[settingsState.addressFormat])}
            </Text>
          </View>
        </View>
        <SvgXml
          xml={ArrowIconSVG}
          fill="#666666"
          style={styles.arrowIcon}
        />
      </TouchableOpacity>
      <AccountsModal
        title={i18n.t('transfer_modal_title1')}
        visible={isAccountModal}
        selected={selected}
        onTriggered={() => setIsAccountModal(false)}
        accounts={accounts}
        onSelected={onSelect}
      />
    </React.Fragment>
  );
};
