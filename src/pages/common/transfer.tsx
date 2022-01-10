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
  Dimensions,
  Alert
} from 'react-native';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';
import { StackNavigationProp } from '@react-navigation/stack';

import { CustomButton } from 'app/components/custom-button';
import {
  TransferAccount,
  TransferToken,
  TransferAmount,
  TransferRecipient
} from 'app/components/transfer';
import { ConfirmPopup } from 'app/components/modals';
import { LoadSVG } from 'app/components/load-svg';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { RootParamList } from 'app/navigator';
import { RouteProp, useTheme } from '@react-navigation/native';
import { CommonStackParamList } from 'app/navigator/common';
import { toQA } from 'app/filters';
import { Transaction } from 'app/lib/controller';
import { AccountTypes, DEFAULT_GAS } from 'app/config';
import { fromBech32Address } from 'app/utils';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
  route: RouteProp<CommonStackParamList, 'Transfer'>;
};

const { width } = Dimensions.get('window');
export const TransferPage: React.FC<Prop> = ({ route, navigation }) => {
  const { colors } = useTheme();
  const accountState = keystore.account.store.useValue();
  const contactsState = keystore.contacts.store.useValue();
  const tokensState = keystore.token.store.useValue();
  const networkState = keystore.network.store.useValue();
  const gasState = keystore.gas.store.useValue();
  const authState = keystore.guard.auth.store.useValue();

  const [isLoading, setIsLoading] = React.useState(false);
  const [confirmModal, setConfirmModal] = React.useState(false);
  const [confirmError, setConfirmError] = React.useState<string>();
  const [selectedToken, setSelectedToken] = React.useState(
    (route.params && route.params.selectedToken) || 0
  );
  const [selectedAccount, setSelectedAccount] = React.useState(accountState.selectedAddress);
  const [amount, setAmount] = React.useState('0');
  const [tx, setTx] = React.useState<Transaction>();
  const [recipient, setRecipient] = React.useState<string>(
    (route.params && route.params.recipient) || ''
  );

  const token = React.useMemo(
    () => tokensState[selectedToken],
    [selectedToken, tokensState]
  );
  const tokens = React.useMemo(() => {
    return tokensState.filter((t) => Boolean(t.address[networkState.selected]));
  }, [tokensState]);
  const account = React.useMemo(
    () => accountState.identities[selectedAccount],
    [accountState, selectedAccount]
  );

  const handleSiging = React.useCallback(async(transaction: Transaction, cb, password) => {
    setConfirmError(undefined);
    try {
      const chainID = await keystore.zilliqa.getNetworkId();

      transaction.setVersion(chainID);

      if (account.type === AccountTypes.Ledger) {
        await transaction.ledgerSign(account);
      } else {
        const keyPair = await keystore.getkeyPairs(account, password);
        await transaction.sign(keyPair.privateKey);
      }

      const res = await keystore.zilliqa.send(transaction);

      transaction.hash = res.TranID;

      await keystore.transaction.add(transaction, token);

      cb();
      setConfirmModal(false);

      setTimeout(() => {
        navigation.navigate('App', {
          screen: 'History'
        });
      }, 500);
    } catch (err) {
      cb();
      setConfirmError((err as Error).message);
    }
  }, [
    navigation,
    selectedAccount,
    account,
    token
  ]);
  const handleSelectToken = React.useCallback((tokenIndex) => {
    setSelectedToken(tokenIndex);
    setAmount('0');
  }, []);
  const handleSelectAccount = React.useCallback((accountIndex) => {
    setSelectedAccount(accountIndex);
    setAmount('0');
  }, []);
  const handleSend = React.useCallback(async() => {
    setIsLoading(true);
    setConfirmError(undefined);

    const [zil] = tokensState;
    const net = networkState.selected;
    let data = '';
    let qa = '0';
    let gas = gasState;
    let toAddr = null;

    try {
      if (zil.symbol === token.symbol) {
        toAddr = fromBech32Address(recipient);
        qa = toQA(amount, token.decimals);
      } else {
        // If user selected ZRC token.
        data = JSON.stringify({
          _tag: 'Transfer',
          params: [
            {
              vname: 'to',
              type: 'ByStr20',
              value: fromBech32Address(recipient).toLowerCase()
            },
            {
              vname: 'amount',
              type: 'Uint128',
              value: toQA(amount, token.decimals)
            }
          ]
        });
        gas = {
          gasPrice: String(DEFAULT_GAS.gasPrice),
          gasLimit: String(9000)
        };
        toAddr = token.address[net];
      }

      const nonce = await keystore.transaction.calcNextNonce(account);
      const newTX = new Transaction(
        qa,
        gas,
        account,
        toAddr,
        net,
        nonce,
        '',
        data
      );

      setTx(newTX);
      setConfirmModal(true);
    } catch (err) {
      setConfirmModal(false);
      Alert.alert(
        i18n.t('transfer_title'),
        (err as Error).message,
        [
          { text: "OK" }
        ]
      );
    }
    setIsLoading(false);
  }, [
    networkState,
    token,
    tokensState,
    account,
    amount,
    recipient,
    gasState
  ]);

  return (
    <React.Fragment>
      <View>
        <KeyboardAwareScrollView>
          <View style={{
            backgroundColor: colors.card
          }}>
            <TransferAccount
              accounts={accountState.identities}
              selected={selectedAccount}
              onSelect={handleSelectAccount}
            />
            <TransferToken
              account={accountState.identities[selectedAccount]}
              tokens={tokens}
              selected={selectedToken}
              netwrok={networkState.selected}
              onSelect={handleSelectToken}
            />
          </View>
          <TransferRecipient
            style={{
              backgroundColor: colors.card,
              marginTop: 15
            }}
            accounts={accountState.identities}
            recipient={recipient}
            contacts={contactsState}
            onSelect={setRecipient}
          />
          <TransferAmount
            style={{
              backgroundColor: colors.card
            }}
            account={accountState.identities[selectedAccount]}
            token={token}
            gas={gasState}
            netwrok={networkState.selected}
            value={amount}
            onChange={setAmount}
          />
          <View style={{
            width: '100%',
            alignItems: 'center',
            marginTop: 15
          }}>
            <CustomButton
              disabled={!recipient}
              style={{ width: width / 1.5 }}
              title={i18n.t('restore_btn')}
              isLoading={isLoading}
              onPress={handleSend}
            />
          </View>
        </KeyboardAwareScrollView>
      </View>
      {tx ? (
        <ConfirmPopup
          transaction={tx}
          error={confirmError || ''}
          token={token}
          account={account}
          title={i18n.t('confirm')}
          visible={confirmModal}
          needPassword={!authState.biometricEnable && account.type !== AccountTypes.Ledger}
          onTriggered={() => setConfirmModal(false)}
          onConfirm={handleSiging}
        >
          <LoadSVG
            addr={token.address[networkState.selected]}
            height="30"
            width="30"
          />
        </ConfirmPopup>
      ) : null}
    </React.Fragment>
  );
};
