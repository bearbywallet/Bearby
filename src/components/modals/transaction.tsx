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
  TouchableOpacity,
  Linking,
  ScrollView,
  ViewStyle
} from 'react-native';
import Modal from 'react-native-modal';
import { useTheme } from '@react-navigation/native';

import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { TransactionType } from 'types';
import { trim, fromZil, toConversion } from 'app/filters';
import { viewAddress, viewBlockNumber, viewTransaction } from 'app/utils';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  transaction?: TransactionType;
  onTriggered: () => void;
};

export const TransactionModal: React.FC<Prop> = ({
  style,
  transaction,
  visible,
  onTriggered
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

  const hanldeViewFrom = React.useCallback(() => {
    const url = viewAddress(transaction.from, keystore.network.selected);

    Linking.openURL(url);
  }, [transaction]);

  const hanldeViewTo = React.useCallback(() => {
    const url = viewAddress(transaction.to, keystore.network.selected);

    Linking.openURL(url);
  }, [transaction]);

  const hanldeViewBlock = React.useCallback(() => {
    const url = viewBlockNumber(transaction.blockHeight, keystore.network.selected);

    Linking.openURL(url);
  }, [transaction]);

  const hanldeViewTx = React.useCallback(() => {
    const url = viewTransaction(transaction.hash, keystore.network.selected);

    Linking.openURL(url);
  }, [transaction]);

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
          <TouchableOpacity
            style={styles.txItem}
            onPress={hanldeViewBlock}
          >
            <Text style={[styles.txLable, {
              color: colors.border
            }]}>
              {i18n.t('block_height')}
            </Text>
            <Text style={[styles.txValue, {
              color: colors.text
            }]}>
              {transaction.blockHeight}
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.txItem}
            onPress={hanldeViewTx}
          >
            <Text style={[styles.txLable, {
              color: colors.border
            }]}>
              {i18n.t('tx_hash')}
            </Text>
            <Text style={[styles.txValue, {
              color: colors.text
            }]}>
              {transaction.hash}
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.txItem}
            onPress={hanldeViewFrom}
          >
            <Text style={[styles.txLable, {
              color: colors.border
            }]}>
              {i18n.t('transfer_account')}
            </Text>
            <Text style={[styles.txValue, {
              color: colors.text
            }]}>
              {trim(transaction.from)}
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.txItem}
            onPress={hanldeViewTo}
          >
            <Text style={[styles.txLable, {
              color: colors.border
            }]}>
              {i18n.t('recipient_account')}
            </Text>
            <Text style={[styles.txValue, {
              color: colors.text
            }]}>
              {trim(transaction.to)}
            </Text>
          </TouchableOpacity>
          <View style={styles.txItem}>
            <Text style={[styles.txLable, {
              color: colors.border
            }]}>
              {i18n.t('transfer_amount')}
            </Text>
            <Text style={[styles.txValue, {
              color: colors.text
            }]}>
              {fromZil(transaction.value, zilliqaToken.decimals)} {zilliqaToken.symbol}
            </Text>
            <Text style={[styles.txValeuLabel, {
              color: colors.notification
            }]}>
              {conversion} {currencyState}
            </Text>
          </View>
          <View style={styles.txItem}>
            <Text style={[styles.txLable, {
              color: colors.border
            }]}>
              {i18n.t('nonce')}
            </Text>
            <Text style={[styles.txValue, {
              color: colors.text
            }]}>
              {transaction.nonce}
            </Text>
          </View>
        </ScrollView>
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  txItem: {
    padding: 10,
    margin: 5
  },
  txLable: {
    fontSize: 16,
    lineHeight: 21
  },
  txValue: {
    fontSize: 17,
    lineHeight: 22
  },
  txValeuLabel: {
    fontSize: 13,
    lineHeight: 17
  }
});
