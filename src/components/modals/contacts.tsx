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
  ScrollView,
  TouchableOpacity,
  ViewStyle
} from 'react-native';
import { SvgXml } from 'react-native-svg';

import Modal from 'react-native-modal';
import { DeleteIconSVG } from 'app/components/svg';
import { ContactItem } from 'app/components/contact-item';

import { theme } from 'app/styles';
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
      <View style={[styles.modalContainer, style]}>
        <View style={styles.titleWrapper}>
          <Text style={styles.title}>
            {title}
          </Text>
          <TouchableOpacity onPress={onTriggered}>
            <SvgXml xml={DeleteIconSVG}/>
          </TouchableOpacity>
        </View>
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
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  title: {
    color: theme.colors.white,
    fontSize: 17,
    lineHeight: 22
  },
  modalContainer: {
    borderTopEndRadius: 16,
    borderTopStartRadius: 16,
    backgroundColor: '#18191D',
    justifyContent: 'space-between',
    paddingVertical: 15
  },
  titleWrapper: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 15
  }
});
