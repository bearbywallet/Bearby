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
  Button,
  SafeAreaView,
  StyleSheet
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';

import { colors } from 'app/styles';
import { RootParamList } from 'app/navigator';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

export const ContactsPage: React.FC<Prop> = ({ navigation }) => {
  return (
    <SafeAreaView style={styles.container}>
      <Button
        title="test"
        onPress={() => null}
      />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.secondary
  }
});

export default ContactsPage;
