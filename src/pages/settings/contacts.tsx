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
  SafeAreaView,
  StyleSheet
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { useStore } from 'effector-react';

import { ContactItem } from 'app/components/contact-item';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { RootParamList } from 'app/navigator';
import { Contact } from 'types';
import { keystore } from 'app/keystore';

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

export const ContactsPage: React.FC<Prop> = () => {
  const contactsState = useStore(keystore.contacts.store);

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

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.titleWrapper}>
        <Text style={styles.title}>
          {i18n.t('contacts_title')}
        </Text>
        <Button
          title={i18n.t('contacts_btn')}
          color={theme.colors.primary}
          onPress={() => null}
        />
      </View>
      <ScrollView style={styles.list}>
        {alphabetSorted.map((item, index) => (
          <ContactItem
            key={index}
            name={item.name}
            isChar={!checkChar(alphabetSorted, index)}
            last={index === alphabetSorted.length - 1}
            bech32={item.address}
            onRemove={() => keystore.contacts.rm(item)}
          />
        ))}
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: theme.colors.black,
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
    color: theme.colors.white,
    fontSize: 34,
    lineHeight: 41,
    fontWeight: 'bold'
  },
  list: {
    backgroundColor: theme.colors.black,
    marginTop: 16
  }
});

export default ContactsPage;
