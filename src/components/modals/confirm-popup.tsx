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
  StyleSheet,
  ScrollView,
  Text,
  ViewStyle,
  View
} from 'react-native';
import { useTheme } from '@react-navigation/native';

import ProfileSVG from 'app/assets/icons/profile.svg';
import ReceiveIconSVG from 'app/assets/icons/receive.svg';
import AmountIconSVG from 'app/assets/icons/amount.svg';

import commonStyles from 'app/components/transfer/styles';
import { AdvacedGas } from 'app/components/advaced-gas';
import Modal from 'react-native-modal';
import { CustomButton } from 'app/components/custom-button';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { Passwordinput } from 'app/components/password-input';
import { ErrorMessage } from 'app/components/error-message';
import { LabelValue } from 'app/components/label-value';

import { Account, GasState, Token } from 'types';
import i18n from 'app/lib/i18n';
import { fromZil, toConversion, trim, toLocaleString, nFormatter } from 'app/filters';
import { keystore } from 'app/keystore';
import { Transaction } from 'app/lib/controller/transaction';
import { DEFAULT_GAS } from 'app/config';
import { fonts } from 'app/styles';

type Prop = {
  style?: ViewStyle;
  account: Account;
  transaction: Transaction;
  token: Token;
  visible: boolean;
  title: string;
  error?: string;
  needPassword?: boolean;
  onTriggered: () => void;
  onConfirm: (transaction: Transaction, cb: () => void, password?: string) => void;
};

export const ConfirmPopup: React.FC<Prop> = ({
  title,
  style,
  account,
  transaction,
  token,
  visible,
  children,
  needPassword,
  error,
  onTriggered,
  onConfirm
}) => {
  const { colors } = useTheme();
  const tokensState = keystore.token.store.useValue();
  const settingsState = keystore.settings.store.useValue();
  const currencyState = keystore.currency.store.useValue();
  const gasState = keystore.gas.store.useValue();

  const [passowrd, setPassowrd] = React.useState<string>('');

  const [isLoading, setIsLoading] = React.useState(false);
  const [DS, setDS] = React.useState(transaction.priority);
  const [gas, setGas] = React.useState<GasState>({
    gasPrice: gasState.gasPrice,
    gasLimit: transaction.gasLimit.toString()
  });

  const conversion = React.useMemo(() => {
    const rate = settingsState.rate[currencyState];
    const value = toConversion(transaction.tokenAmount, rate, token.decimals);

    // TODO: add token converter.

    return nFormatter(value);
  }, [transaction, settingsState, token, tokensState, currencyState]);

  const handleSend = React.useCallback(async() => {
    setIsLoading(true);
    transaction.setGas(gas);
    onConfirm(transaction, () => setIsLoading(false), passowrd);
  }, [
    gas,
    transaction,
    needPassword,
    passowrd
  ]);

  React.useEffect(() => {
    transaction.setPriority(DS);
  }, [DS, setDS]);

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
          <View style={styles.topWrapper}>
            {children}
            <Text style={[styles.toptext, {
              color: colors.text
            }]}>
              {title}
            </Text>
          </View>
        </ModalTitle>
        <ErrorMessage>
          {error}
        </ErrorMessage>
        <ScrollView style={{ marginBottom: 15 }}>
          <LabelValue title={i18n.t('method')}>
            {transaction.tag}
          </LabelValue>
          <View style={commonStyles.item}>
            <ProfileSVG />
            <View style={[commonStyles.itemInfo, styles.item]}>
              <Text style={[commonStyles.label, {
                color: colors.text
              }]}>
                {i18n.t('transfer_account')}
              </Text>
              <View style={commonStyles.infoWrapper}>
                <Text style={[commonStyles.nameAmountText, {
                  color: colors.border
                }]}>
                  {account.name}
                </Text>
                <Text style={[commonStyles.addressAmount, {
                  color: colors.border
                }]}>
                  {trim(account[settingsState.addressFormat])}
                </Text>
              </View>
            </View>
          </View>
          <View style={commonStyles.item}>
            <AmountIconSVG />
            <View style={[commonStyles.itemInfo, styles.item]}>
              <Text style={[commonStyles.label, {
                color: colors.text
              }]}>
                {i18n.t('transfer_amount')}
              </Text>
              <View style={commonStyles.infoWrapper}>
                <Text style={[commonStyles.nameAmountText, {
                  color: colors.border
                }]}>
                  {toLocaleString(fromZil(transaction.tokenAmount, token.decimals))}
                </Text>
                <Text style={[commonStyles.addressAmount, {
                  color: colors.border
                }]}>
                  {conversion} {currencyState}
                </Text>
              </View>
            </View>
          </View>
          <View style={commonStyles.item}>
            <ReceiveIconSVG />
            <View style={[commonStyles.itemInfo, styles.item]}>
              <Text style={[commonStyles.label, {
                color: colors.text
              }]}>
                {i18n.t('recipient_account')}
              </Text>
              <View style={commonStyles.infoWrapper}>
                <Text style={[commonStyles.nameAmountText, {
                  color: colors.border
                }]}>
                  {trim(transaction.recipient)}
                </Text>
              </View>
            </View>
          </View>
          {needPassword ? (
            <Passwordinput
              style={{
                marginVertical: 15,
                paddingHorizontal: 15
              }}
              placeholder={i18n.t('pass_setup_input1')}
              onChange={setPassowrd}
            />
          ) : null}
          <AdvacedGas
            gas={gas}
            ds={DS}
            isDS={!transaction.data}
            nonce={transaction.nonce}
            defaultGas={DEFAULT_GAS}
            onDSChanged={setDS}
            onChange={setGas}
            onChangeNonce={(nonce) => transaction.setNonce(nonce)}
          />
          <CustomButton
            title={i18n.t('send')}
            style={styles.sendBtn}
            disabled={needPassword && !passowrd}
            isLoading={isLoading}
            onPress={handleSend}
          />
        </ScrollView>
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  item: {
    // paddingBottom: 10
  },
  sendBtn: {
    marginVertical: 15
  },
  topWrapper: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  toptext: {
    paddingLeft: 5,
    fontSize: 20,
    fontFamily: fonts.Demi
  }
});
