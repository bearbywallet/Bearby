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
  Button,
  ScrollView,
  StyleSheet,
  FlatList,
  LayoutAnimation
} from 'react-native';
import SafeAreaView from 'react-native-safe-area-view';
import { StackNavigationProp } from '@react-navigation/stack';
import { useTheme } from '@react-navigation/native';

import { ContactItem } from 'app/components/contact-item';
import { AddContactModal } from 'app/components/modals';
import { SwipeRow } from 'app/components/swipe-row';

import i18n from 'app/lib/i18n';
import { RootParamList } from 'app/navigator';
import { Contact } from 'types';
import { keystore } from 'app/keystore';
import { BrowserAppItem } from 'app/components/browser';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

const checkChar = (elements: Contact[], index: number) => {
  if (index === 0) {
    return false;
  } else if (index - 1 < 0) {
    return false;
  }

  const [previous] = elements[index].name;
  const [next] = elements[index - 1].name;

  return previous.toLowerCase() === next.toLowerCase();
};

export const ContactsPage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();
  const contactsState = keystore.contacts.store.useValue();

  const [contactModal, setContactModal] = React.useState(false);

  const alphabetSorted = React.useMemo(() => {
    return contactsState.sort((a, b) => {
      if (a.name < b.name) {
        return -1;
      }
      if (a.name > b.name) {
        return 1;
      }

      return 0;
    });
  }, [contactsState]);

  const handleSelectContect = React.useCallback((address) => {
    navigation.navigate('Common', {
      screen: 'Transfer',
      params: {
        recipient: address
      }
    });
  }, []);
  const hanldeRemove = React.useCallback(async(contact: Contact) => {
    await keystore.contacts.rm(contact);
    LayoutAnimation.configureNext(LayoutAnimation.Presets.spring);
  }, []);

  return (
    <SafeAreaView style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <View style={styles.titleWrapper}>
        <Text style={[styles.title, {
          color: colors.text
        }]}>
          {i18n.t('contacts_title')}
        </Text>
        <Button
          title={i18n.t('contacts_btn')}
          color={colors.primary}
          onPress={() => setContactModal(true)}
        />
      </View>
      <FlatList
        data={alphabetSorted}
        renderItem={({ item, index}) => (
          <SwipeRow
            index={index}
            swipeThreshold={-150}
            onSwipe={() => hanldeRemove(item)}
          >
            <ContactItem
              key={index}
              name={item.name}
              isChar={!checkChar(alphabetSorted, index)}
              last={index === alphabetSorted.length - 1}
              bech32={item.address}
              onSelect={() => handleSelectContect(item.address)}
            />
          </SwipeRow>
        )}
        keyExtractor={(item) => item.address}
      />
      <AddContactModal
        title={i18n.t('contacts_btn')}
        visible={contactModal}
        onTriggered={() => setContactModal(false)}
        onAdd={(contact) => keystore.contacts.add(contact)}
      />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  titleWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: '10%',
    paddingHorizontal: 15
  },
  title: {
    fontSize: 34,
    lineHeight: 41,
    fontWeight: 'bold'
  }
});

export default ContactsPage;
