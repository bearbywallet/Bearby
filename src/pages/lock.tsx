/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import { View, StyleSheet, Text, TouchableHighlight } from 'react-native';
import TouchID from 'react-native-touch-id';

import { colors } from '../styles';
import { touchIDConfig } from '../config';

export const LockPage = () => {

  const pressHandler = React.useCallback(async(event) => {
    try {
      const success = await TouchID
        .authenticate('to demo this react-native component', touchIDConfig);
      // console.log(success);
    } catch (err) {
      // console.warn(err);
    }
  }, []);

  return (
    <View style={styles.container}>
      <TouchableHighlight onPress={pressHandler}>
        <Text>
          Authenticate with Touch ID
        </Text>
      </TouchableHighlight>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 100,
    backgroundColor: colors.secondary
  }
});

export default LockPage;
