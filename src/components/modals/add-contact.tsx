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
import { Contact } from 'types';
import { isBech32 } from 'app/utils';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  title: string;
  onTriggered: () => void;
  onAdd: (contact: Contact) => void;
};

export const AddContactModal: React.FC<Prop> = ({
  style,
  visible,
  title,
  onTriggered,
  onAdd
}) => {
  const [address, setAddress] = React.useState<string>('');
  const [name, setName] = React.useState<string>('');
  const [errorMessage, setErrorMessage] = React.useState<string | undefined>();

  const handleAddressPass = React.useCallback(async(addr) => {
    setAddress(addr);
    setErrorMessage(undefined);

    if (!isBech32(addr)) {
      setErrorMessage(i18n.t('incorect_address_format'));

      return null;
    }
  }, [setAddress, address]);

  const handleCreateContact = React.useCallback(() => {
    onAdd({
      name,
      address
    });
    onTriggered();
    setName('');
    setAddress('');
  }, [address, name, onAdd, onTriggered, setAddress, setName]);

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
          value={address}
          error={errorMessage}
          placeholder={i18n.t('address_zns')}
          onChange={handleAddressPass}
        />
        <TextInput
          style={styles.textInput}
          value={name}
          placeholder={i18n.t('contacts_name')}
          placeholderTextColor={'#8A8A8F'}
          onChangeText={setName}
        />
        <CustomButton
          disabled={Boolean(errorMessage || !name || !address)}
          title={i18n.t('add_contact')}
          onPress={handleCreateContact}
        />
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
  },
  error: {
    color: theme.colors.danger,
    marginTop: 4,
    lineHeight: 22
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    color: theme.colors.white,
    borderBottomColor: '#8A8A8F',
    borderBottomWidth: 1,
    padding: 10,
    marginVertical: 20
  }
});
