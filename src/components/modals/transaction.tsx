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
import { LabelValue } from 'app/components/label-value';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { TransactionType } from 'types';
import { trim, fromZil, toConversion } from 'app/filters';
import { viewTransaction } from 'app/utils';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  transaction?: TransactionType;
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

  const { colors, dark } = useTheme();

  const tokenState = keystore.token.store.useValue();
  const settingsState = keystore.settings.store.useValue();
  const currencyState = keystore.currency.store.useValue();

  const zilliqaToken = React.useMemo(
    () => tokenState[0],
    [tokenState]
  );
  const conversion = React.useMemo(() => {
    const amount = transaction.value;
    const rate = settingsState.rate[currencyState];

    return toConversion(amount, rate, zilliqaToken.decimals);
  }, [zilliqaToken, transaction, settingsState, currencyState]);
  const data = React.useMemo(() => {
    if (!transaction.data) {
      return null;
    }

    try {
      return JSON.parse(transaction.data);
    } catch {
      return null;
    }
  }, [transaction]);
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
      backdropColor={dark ? '#ffffff5' : '#00000060'}
      onBackdropPress={onTriggered}
    >
      <ModalWrapper style={style}>
        <ModalTitle onClose={onTriggered}>
          {i18n.t('history_tx_details')}
        </ModalTitle>
        <ScrollView>
          <LabelValue title={i18n.t('block_height')}>
            {transaction.blockHeight}
          </LabelValue>
          <LabelValue title={i18n.t('tx_hash')}>
            {transaction.hash}
          </LabelValue>
          <LabelValue title={i18n.t('transfer_account')}>
            {trim(transaction.from)}
          </LabelValue>
          <LabelValue title={i18n.t('recipient_account')}>
            {trim(transaction.to)}
          </LabelValue>
          <LabelValue title={i18n.t('transfer_amount')}>
            {fromZil(transaction.value, zilliqaToken.decimals)} {zilliqaToken.symbol}
          </LabelValue>
          <LabelValue title={i18n.t('nonce')}>
            {transaction.nonce}
          </LabelValue>
          {data ? (
            <LabelValue title={i18n.t('transition')}>
              {data._tag}
            </LabelValue>
          ) : null}
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
  txValeuLabel: {
    fontSize: 13,
    lineHeight: 17
  },
  linkWrapper: {
    paddingVertical: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-evenly'
  }
});
