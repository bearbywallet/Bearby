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
  Keyboard,
  ViewStyle
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import Modal from 'react-native-modal';

import { CustomButton } from 'app/components/custom-button';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { QrCodeInput } from 'app/components/qr-code-input';
import { TokenInfo } from 'app/components/token-info';

import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import {
  isBech32,
  fromBech32Address
} from 'app/utils';
import { Account, Token } from 'types';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  title: string;
  account: Account;
  onTriggered: () => void;
  onAddToken: (token: Token, cb: () => void) => void;
};

export const AddTokenModal: React.FC<Prop> = ({
  style,
  visible,
  account,
  title,
  onTriggered,
  onAddToken
}) => {
  const { colors } = useTheme();
  const settingsState = keystore.settings.store.useValue();
  const currencyState = keystore.currency.store.useValue();
  const netwrokState = keystore.network.store.useValue();

  const [loading, setLoading] = React.useState(false);

  const [address, setAddress] = React.useState<string>('');
  const [token, setToken] = React.useState<Token>();
  const [errorMessage, setErrorMessage] = React.useState<string>();

  const handleClose = React.useCallback(() => {
    setErrorMessage(undefined);
    setAddress('');
    setToken(undefined);
    onTriggered();
  }, [setErrorMessage, setAddress, onTriggered, setToken]);
  const handleAddToken = React.useCallback(() => {
    if (!token) {
      return null;
    }

    setLoading(true);
    onAddToken(token, () => {
      setLoading(false);
      setErrorMessage(undefined);
      setAddress('');
      setToken(undefined);
      onTriggered();
    });
  }, [token, setErrorMessage, setLoading, onTriggered]);
  const handleAddressPass = React.useCallback(async(addr) => {
    setErrorMessage(undefined);
    setAddress(addr);

    if (!isBech32(addr)) {
      return null;
    }

    const base16 = fromBech32Address(addr);

    Keyboard.dismiss();
    try {
      const tokenInfo = await keystore.token.getToken(base16, account);

      setToken(tokenInfo);
    } catch (err) {
      setErrorMessage((err as Error).message);
    }
  }, [setAddress, address, account, setToken]);

  return (
    <Modal
      isVisible={visible}
      style={{
        justifyContent: 'flex-end',
        margin: 0,
        marginBottom: 1
      }}
      backdropColor={colors['modal']}
      onBackdropPress={handleClose}
    >
      <ModalWrapper style={style}>
        <ModalTitle onClose={handleClose}>
          {title}
        </ModalTitle>
        <View style={styles.container}>
          <QrCodeInput
            zns
            value={address}
            error={errorMessage}
            placeholder={i18n.t('contract_address')}
            onChange={handleAddressPass}
          />
          {token ? (
            <React.Fragment>
              <TokenInfo
                style={{ marginVertical: 30 }}
                decimals={token.decimals}
                name={token.name}
                address={token.address[netwrokState.selected]}
                symbol={token.symbol}
                balance={token.balance}
                totalSupply={token.totalSupply}
                rate={settingsState.rate[token.symbol]}
                currency={currencyState}
              />
              <CustomButton
                title={i18n.t('add_token')}
                isLoading={loading}
                onPress={handleAddToken}
              />
            </React.Fragment>
          ) : null}
        </View>
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingVertical: 30
  }
});
