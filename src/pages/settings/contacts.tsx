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
  StyleSheet
} from 'react-native';
import { NavigationScreenProp, NavigationState } from 'react-navigation';

import { colors } from 'app/styles';

type Prop = {
  navigation: NavigationScreenProp<NavigationState>;
};

export const ContactsPage: React.FC<Prop> = ({ navigation }) => {
  return (
    <View style={styles.container}>
      <Button
        title="test"
        onPress={() => null}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.secondary
  }
});

export default ContactsPage;
