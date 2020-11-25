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
  SafeAreaView,
  StyleSheet
} from 'react-native';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';
import { StackNavigationProp } from '@react-navigation/stack';
import { useStore } from 'effector-react';

import { CustomButton } from 'app/components/custom-button';
import {
  TransferAccount,
  TransferToken,
  TransferAmount,
  TransferRecipient
} from 'app/components/transfer';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { RootParamList } from 'app/navigator';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

const { width } = Dimensions.get('window');
export const TransferPage: React.FC<Prop> = ({ navigation }) => {
  const accountState = useStore(keystore.account.store);
  const tokensState = useStore(keystore.token.store);
  const networkState = useStore(keystore.network.store);

  const [selectedToken, setSelectedToken] = React.useState(0);
  const [selectedAccount, setSelectedAccount] = React.useState(accountState.selectedAddress);
  const [amount, setAmount] = React.useState('0');

  const token = React.useMemo(
    () => tokensState.identities[selectedToken],
    [selectedToken, tokensState]
  );

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAwareScrollView>
        <View style={styles.wrapper}>
          <TransferAccount
            accounts={accountState.identities}
            selected={selectedAccount}
            onSelect={setSelectedAccount}
          />
          <TransferToken
            tokens={tokensState.identities}
            selected={selectedToken}
            netwrok={networkState.selected}
            onSelect={setSelectedToken}
          />
        </View>
        <TransferRecipient
          style={styles.wrapper}
          onSelect={() => null}
        />
        <TransferAmount
          style={styles.wrapper}
          token={token}
          netwrok={networkState.selected}
          value={amount}
          onChange={setAmount}
        />
        <View style={{
          width: '100%',
          alignItems: 'center',
          marginTop: '10%'
        }}>
          <CustomButton
            style={{ width: width / 1.5 }}
            title={i18n.t('restore_btn')}
          />
        </View>
      </KeyboardAwareScrollView>
    </SafeAreaView>
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
