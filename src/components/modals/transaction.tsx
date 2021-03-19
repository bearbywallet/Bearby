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
  ViewStyle,
  Text
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
import { StoredTx } from 'types';
import { fromZil } from 'app/filters';
import { viewTransaction } from 'app/utils';

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

  const tokenState = keystore.token.store.useValue();

  const zilliqaToken = React.useMemo(
    () => tokenState[0],
    [tokenState]
  );
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
          <View style={[styles.item, {
            borderColor: colors.primary
          }]}>
            <Text style={{
              color: colors.text
            }}>
              Nonce
            </Text>
            <Text style={{
              color: colors.text
            }}>
              #{transaction.nonce}
            </Text>
          </View>
          <View style={[styles.item, {
            borderColor: colors.primary
          }]}>
            <Text style={{
              color: colors.text
            }}>
              Amount
            </Text>
            <Text style={{
              color: colors.text
            }}>
              -{fromZil(transaction.amount, transaction.token.decimals)} {transaction.token.symbol}
            </Text>
          </View>
          <View style={[styles.item, {
            borderColor: colors.primary
          }]}>
            <Text style={{
              color: colors.text
            }}>
              Status
            </Text>
            <Text style={{
              color: colors.text
            }}>
              {transaction.info}
            </Text>
          </View>
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
  },
  item: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    borderBottomWidth: 1,
    padding: 3
  }
});
