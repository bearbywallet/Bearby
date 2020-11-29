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
  TextInput,
  ViewStyle
} from 'react-native';
import Modal from 'react-native-modal';

import { CustomButton } from 'app/components/custom-button';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { QrCodeInput } from 'app/components/qr-code-input';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { keystore } from 'app/keystore';
import {
  isBech32,
  fromBech32Address,
  toZRC1
} from 'app/utils';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  title: string;
  onTriggered: () => void;
};

export const AddTokenModal: React.FC<Prop> = ({
  style,
  visible,
  title,
  onTriggered
}) => {
  const [address, setAddress] = React.useState<string>('');
  const [errorMessage, setErrorMessage] = React.useState<string>(' ');

  // const hanldeGetContract = React.useCallback((address) => {
  // }, []);
  const handleAddressPass = React.useCallback(async(addr) => {
    setAddress(addr);

    if (!isBech32(addr)) {
      return null;
    }

    const base16 = fromBech32Address(addr);
    const init = await keystore.zilliqa.getSmartContractInit(base16);
    const zrc = toZRC1(init);

    // console.log(JSON.stringify(zrc, null, 4));
  }, [setAddress, address]);

  return (
    <Modal
      isVisible={visible}
      style={{
        justifyContent: 'flex-end',
        margin: 0,
        marginBottom: 1
      }}
      onBackdropPress={onTriggered}
    >
      <ModalWrapper style={{ ...style, ...styles.container }}>
        <ModalTitle onClose={onTriggered}>
          {title}
        </ModalTitle>
        <QrCodeInput
          style={styles.input}
          value={address}
          placeholder={i18n.t('contract_address')}
          onChange={handleAddressPass}
        />
        {/* <CustomButton
          title={i18n.t('add_token')}
          onPress={hanldeGetContract}
        /> */}
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
  },
  inputLable: {
    color: '#8A8A8F'
  },
  error: {
    color: theme.colors.danger,
    marginTop: 4,
    lineHeight: 22
  },
  input: {
    marginVertical: 30
  }
});
