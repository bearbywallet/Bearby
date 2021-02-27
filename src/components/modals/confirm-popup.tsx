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
import { SvgXml } from 'react-native-svg';
import { useTheme } from '@react-navigation/native';

import {
  ProfileSVG,
  ReceiveIconSVG,
  AmountIconSVG
} from 'app/components/svg';
import commonStyles from 'app/components/transfer/styles';
import { AdvacedGas } from 'app/components/advaced-gas';
import Modal from 'react-native-modal';
import { CustomButton } from 'app/components/custom-button';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { Passwordinput } from 'app/components/password-input';
import { ErrorMessage } from 'app/components/error-message';

import { Account, GasState, Token } from 'types';
import i18n from 'app/lib/i18n';
import { fromZil, toConversion, trim, toLocaleString } from 'app/filters';
import { keystore } from 'app/keystore';
import { deppUnlink } from 'app/utils';
import { Transaction } from 'app/lib/controller/transaction';
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
  const settingsState = keystore.settings.store.useValue();
  const currencyState = keystore.currency.store.useValue();

  const [passowrd, setPassowrd] = React.useState<string>('');

  const [isLoading, setIsLoading] = React.useState(false);
  const [DS, setDS] = React.useState(transaction.priority);
  const [gas, setGas] = React.useState<GasState>({
    gasLimit: String(transaction.gasLimit),
    gasPrice: transaction.gasPrice
  });

  const conversion = React.useMemo(() => {
    const rate = settingsState.rate[token.symbol];
    const value = toConversion(transaction.amount, rate, token.decimals);

    return toLocaleString(value);
  }, [transaction, settingsState, token]);

  const handleSend = React.useCallback(async() => {
    setIsLoading(true);
    onConfirm(transaction, () => setIsLoading(false), passowrd);
  }, [
    transaction,
    needPassword,
    passowrd,
    setIsLoading,
    onConfirm
  ]);

  React.useEffect(() => {
    transaction.setPriority(DS);
  }, [DS, setDS]);

  React.useEffect(() => {
    setIsLoading(true);

    const accountState = keystore.account.store.get();
    const foundIndex = accountState.identities.findIndex(
      (acc) => acc.base16 === account.base16
    );

    if (foundIndex !== -1) {
      keystore
        .account
        .updateNonce(foundIndex)
        .then((nonce) => {
          if (nonce) {
            transaction.setNonce(nonce);
          }

          setIsLoading(false)
        })
        .catch(() => setIsLoading(false));
    }
  }, [account]);

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
          <View style={commonStyles.item}>
            <SvgXml xml={ProfileSVG} />
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
                <Text style={commonStyles.addressAmount}>
                  {trim(account[settingsState.addressFormat])}
                </Text>
              </View>
            </View>
          </View>
          <View style={commonStyles.item}>
            <SvgXml xml={AmountIconSVG} />
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
                  {toLocaleString(fromZil(transaction.amount, token.decimals))}
                </Text>
                <Text style={commonStyles.addressAmount}>
                  {conversion} {currencyState}
                </Text>
              </View>
            </View>
          </View>
          <View style={commonStyles.item}>
            <SvgXml xml={ReceiveIconSVG} />
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
                marginVertical: 15
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
            defaultGas={deppUnlink(transaction.fee)}
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
    paddingBottom: 10
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
