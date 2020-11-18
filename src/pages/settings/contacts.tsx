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

import { ContactItem } from 'app/components/contact-item';

import i18n from 'app/lib/i18n';
import { theme } from 'app/styles';
import { RootParamList } from 'app/navigator';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

const items = [
  {
    name: 'test0',
    bech32: 'zil1wl38cwww2u3g8wzgutxlxtxwwc0rf7jf27zace'
  },
  {
    name: 'test1',
    bech32: 'zil1wl38cwww2u3g8wzgutxlxtxwwc0rf7jf27zace'
  },
  {
    name: 'test2',
    bech32: 'zil1wl38cwww2u3g8wzgutxlxtxwwc0rf7jf27zace'
  },
  {
    name: 'test3',
    bech32: 'zil1wl38cwww2u3g8wzgutxlxtxwwc0rf7jf27zace'
  },
  {
    name: 'test4',
    bech32: 'zil1wl38cwww2u3g8wzgutxlxtxwwc0rf7jf27zace'
  }
];

export const ContactsPage: React.FC<Prop> = ({ navigation }) => {
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
        {items.map((item, index) => (
          <ContactItem
            key={index}
            name={item.name}
            last={index === items.length - 1}
            bech32={item.bech32}
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
