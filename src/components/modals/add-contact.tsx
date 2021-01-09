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
import { useTheme } from '@react-navigation/native';

import { CustomButton } from 'app/components/custom-button';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { QrCodeInput } from 'app/components/qr-code-input';

import i18n from 'app/lib/i18n';
import { Contact } from 'types';
import { isBech32 } from 'app/utils';
import { fonts } from 'app/styles';

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
  const { colors } = useTheme();
  const [address, setAddress] = React.useState<string>('');
  const [name, setName] = React.useState<string>('');

  const handleAddressPass = React.useCallback(async(addr) => {
    setAddress(addr);

    if (!isBech32(addr)) {
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

  React.useEffect(() => {
    setAddress('');
    setName('');
  }, [visible, setAddress]);

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
          {title}
        </ModalTitle>
        <QrCodeInput
          zns
          value={address}
          placeholder={i18n.t('address_zns')}
          onChange={handleAddressPass}
          onZNS={setName}
        />
        <TextInput
          style={[styles.textInput, {
            color: colors.text,
            borderBottomColor: colors.border
          }]}
          autoCorrect={false}
          value={name}
          placeholder={i18n.t('contacts_name')}
          placeholderTextColor={colors.border}
          onChangeText={setName}
        />
        <CustomButton
          disabled={Boolean(!name || !address)}
          title={i18n.t('add_contact')}
          onPress={handleCreateContact}
        />
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
  textInput: {
    fontSize: 17,
    fontFamily: fonts.Demi,
    borderBottomWidth: 1,
    padding: 10,
    marginVertical: 20
  }
});
