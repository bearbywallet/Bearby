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
  StyleSheet
} from 'react-native';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';
import SafeAreaView from 'react-native-safe-area-view';
import { StackNavigationProp } from '@react-navigation/stack';

import { CustomButton } from 'app/components/custom-button';
import {
  TransferAccount,
  TransferToken,
  TransferAmount,
  TransferRecipient
} from 'app/components/transfer';
import { ConfirmPopup } from 'app/components/modals';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { RootParamList } from 'app/navigator';
import { RouteProp } from '@react-navigation/native';
import { CommonStackParamList } from 'app/navigator/common';
import { toQA } from 'app/filters';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
  route: RouteProp<CommonStackParamList, 'Transfer'>;
};

const { width } = Dimensions.get('window');
export const TransferPage: React.FC<Prop> = ({ navigation, route }) => {
  const accountState = keystore.account.store.useValue();
  const contactsState = keystore.contacts.store.useValue();
  const tokensState = keystore.token.store.useValue();
  const networkState = keystore.network.store.useValue();
  const gasState = keystore.gas.store.useValue();

  const [amountErr, setAmountErr] = React.useState(true);
  const [recipientErr, setRecipientErr] = React.useState(true);

  const [confirmModal, setConfirmModal] = React.useState(false);
  const [selectedToken, setSelectedToken] = React.useState(0);
  const [selectedAccount, setSelectedAccount] = React.useState(accountState.selectedAddress);
  const [amount, setAmount] = React.useState('0');
  const [recipient, setRecipient] = React.useState<string>(
    (route.params && route.params.recipient) || ''
  );

  const token = React.useMemo(
    () => tokensState.identities[selectedToken],
    [selectedToken, tokensState]
  );

  return (
    <React.Fragment>
      <SafeAreaView style={styles.container}>
        <KeyboardAwareScrollView>
          <View style={styles.wrapper}>
            <TransferAccount
              accounts={accountState.identities}
              selected={selectedAccount}
              onSelect={setSelectedAccount}
            />
            <TransferToken
              account={accountState.identities[selectedAccount]}
              tokens={tokensState.identities}
              selected={selectedToken}
              netwrok={networkState.selected}
              onSelect={setSelectedToken}
            />
          </View>
          <TransferRecipient
            style={{ ...styles.wrapper, marginTop: 30 }}
            accounts={accountState.identities}
            recipient={recipient}
            contacts={contactsState}
            onSelect={setRecipient}
            onError={setRecipientErr}
          />
          <TransferAmount
            style={styles.wrapper}
            account={accountState.identities[selectedAccount]}
            token={token}
            gas={gasState}
            netwrok={networkState.selected}
            value={amount}
            onChange={setAmount}
            onError={setAmountErr}
          />
          <View style={{
            width: '100%',
            alignItems: 'center',
            marginTop: '10%'
          }}>
            <CustomButton
              disabled={amountErr || recipientErr}
              style={{ width: width / 1.5 }}
              title={i18n.t('restore_btn')}
              onPress={() => setConfirmModal(true)}
            />
          </View>
        </KeyboardAwareScrollView>
      </SafeAreaView>
      <ConfirmPopup
        token={token}
        recipient={recipient}
        amount={toQA(amount, token.decimals)}
        account={accountState.identities[selectedAccount]}
        title={i18n.t('confirm')}
        netwrok={networkState.selected}
        visible={confirmModal}
        onTriggered={() => setConfirmModal(false)}
      />
    </React.Fragment>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
  },
  wrapper: {
    backgroundColor: theme.colors.gray
  }
});
