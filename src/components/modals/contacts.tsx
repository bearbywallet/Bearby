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
  ViewStyle
} from 'react-native';

import Modal from 'react-native-modal';
import { ContactItem } from 'app/components/contact-item';
import { ModalTitle } from 'app/components/modal-title';
import { ModalWrapper } from 'app/components/modal-wrapper';

import { Contact } from 'types';

type Prop = {
  style?: ViewStyle;
  visible: boolean;
  title: string;
  contacts: Contact[];
  onTriggered: () => void;
  onSelected: (index: number) => void;
};

export const ContactsModal: React.FC<Prop> = ({
  title,
  style,
  contacts,
  visible,
  onTriggered,
  onSelected
}) => {
  const handleSelected = React.useCallback((index) => {
    onSelected(index);
    onTriggered();
  }, [onTriggered, onSelected]);

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
      <ModalWrapper style={style}>
        <ModalTitle
          style={{ padding: 15 }}
          onClose={onTriggered}
        >
          {title}
        </ModalTitle>
        <ScrollView style={{ marginVertical: 20 }}>
          {contacts.map((contact, index) => (
            <ContactItem
              key={index}
              name={contact.name}
              bech32={contact.address}
              last={index === contacts.length - 1}
              onSelect={() => handleSelected(index)}
            />
          ))}
        </ScrollView>
      </ModalWrapper>
    </Modal>
  );
};

const styles = StyleSheet.create({
});
