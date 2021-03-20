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
  ScrollView,
  ViewStyle
} from 'react-native';
import Modal from 'react-native-modal';
import Share from 'react-native-share';
import { useTheme } from '@react-navigation/native';
import Clipboard from '@react-native-community/clipboard';

import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { ViewButton } from 'app/components/view-button';
import {
  ProfileSVG,
  ViewBlockIconSVG,
  ShareIconSVG
} from 'app/components/svg';
import { KeyValue } from 'app/components/key-value';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { StoredTx } from 'types';
import { fromZil, trim } from 'app/filters';
import { toBech32Address, toChecksumAddress, viewTransaction } from 'app/utils';
import { ADDRESS_FORMATS } from 'app/config';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  transaction?: StoredTx;
  onTriggered: () => void;
  onViewBlock: (url: string) => void;
};

export const TransactionModal: React.FC<Prop> = ({
  style,
  transaction,
  visible,
  onTriggered,
  onViewBlock
}) => {
  if (!transaction) {
    return null;
  }

  const { colors } = useTheme();
  const settingsState = keystore.settings.store.useValue();

  const toAddr = React.useMemo(() => {
    let address = transaction.toAddr;
    const [bech32, base16] = ADDRESS_FORMATS;

    if (settingsState.addressFormat === bech32) {
      address = toBech32Address(address);
    } else if (settingsState.addressFormat === base16) {
      address = toChecksumAddress(address);
    }

    return trim(address);
  }, [settingsState, transaction]);

  const handleShare = React.useCallback(() => {
    const url = viewTransaction(transaction.hash, keystore.network.selected);
    const shareOptions = {
      url,
      title: `Transaction`
    };
    Share.open(shareOptions)
      .then(() => null)
      .catch(() => null);
  }, [transaction]);
  const hanldeCopy = React.useCallback(() => {
    Clipboard.setString(transaction.hash);
  }, [transaction]);
  const handleViewTx = React.useCallback(() => {
    const url = viewTransaction(transaction.hash, keystore.network.selected);

    onViewBlock(url);
  }, [onViewBlock]);

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
          {i18n.t('history_tx_details')}
        </ModalTitle>
        <ScrollView>
          <KeyValue title={i18n.t('method')}>
            {transaction.teg}
          </KeyValue>
          <KeyValue title={i18n.t('sorting_item0')}>
            {transaction.info}
          </KeyValue>
          <KeyValue title={i18n.t('transfer_amount')}>
            -{fromZil(transaction.amount, transaction.token.decimals)} {transaction.token.symbol}
          </KeyValue>
          <KeyValue title={i18n.t('nonce')}>
            #{transaction.nonce}
          </KeyValue>
          <KeyValue title={i18n.t('timestamp')}>
            {new Date(transaction.timestamp).toDateString()}
          </KeyValue>
          <KeyValue title={i18n.t('to_address')}>
            {toAddr}
          </KeyValue>
        </ScrollView>
        <View style={styles.linkWrapper}>
          <ViewButton
            icon={ShareIconSVG}
            onPress={handleShare}
          >
            {i18n.t('share')}
          </ViewButton>
          <ViewButton
            icon={ProfileSVG}
            onPress={hanldeCopy}
          >
            {i18n.t('copy_hash')}
          </ViewButton>
          <ViewButton
            icon={ViewBlockIconSVG}
            onPress={handleViewTx}
          >
            {i18n.t('view_block')}
          </ViewButton>
        </View>
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  linkWrapper: {
    paddingVertical: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-evenly'
  }
});
