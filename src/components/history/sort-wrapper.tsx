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
import { HistoryStatus, TokensModal } from 'app/components/modals';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { Token } from 'types';

type Prop = {
  style?: ViewStyle;
  tokens: Token[];
  selectedToken: number;
  selectedStatus: number;
  onSelectStatus: (status: number) => void;
  onSelectToken: (index: number) => void;
};

export const SortingWrapper: React.FC<Prop> = ({
  style,
  tokens,
  selectedToken,
  selectedStatus,
  onSelectStatus,
  onSelectToken
}) => {
  const netwrokState = keystore.network.store.useValue();

  const [statusModal, setStatusModal] = React.useState(false);
  const [tokenModal, setTokenModal] = React.useState(false);
  const [dateModal, setdateModal] = React.useState(false);

  return (
    <React.Fragment>
      <View style={[styles.container, style]}>
        <DropDownItem
          color="#666666"
          onPress={() => setStatusModal(true)}
        >
          {i18n.t('sorting_item0')}
        </DropDownItem>
        <DropDownItem
          color="#666666"
          onPress={() => setTokenModal(true)}
        >
          {i18n.t('sorting_item1')}
        </DropDownItem>
        <DropDownItem
          color="#666666"
          onPress={() => setdateModal(true)}
        >
          {i18n.t('sorting_item2')}
        </DropDownItem>
      </View>
      <HistoryStatus
        title={i18n.t('sort_status')}
        visible={statusModal}
        selected={selectedStatus}
        onTriggered={() => setStatusModal(false)}
        onSelect={onSelectStatus}
      />
      <TokensModal
        title={i18n.t('token')}
        visible={tokenModal}
        tokens={tokens}
        network={netwrokState.selected}
        selected={selectedToken}
        onTriggered={() => setTokenModal(false)}
        onSelect={onSelectToken}
      />
    </React.Fragment>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    paddingHorizontal: 30
  }
});
