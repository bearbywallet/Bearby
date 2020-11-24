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
  TextInput,
  Button,
  Dimensions,
  SafeAreaView,
  ScrollView,
  StyleSheet
} from 'react-native';
import { SvgXml } from 'react-native-svg';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';
import { StackNavigationProp } from '@react-navigation/stack';
import { useStore } from 'effector-react';

import {
  ProfileSVG,
  ArrowIconSVG
} from 'app/components/svg';

import { theme } from 'app/styles';
import i18n from 'app/lib/i18n';
import { keystore } from 'app/keystore';
import { RootParamList } from 'app/navigator';

type Prop = {
  navigation: StackNavigationProp<RootParamList>;
};

const { height, width } = Dimensions.get('window');
export const TransferPage: React.FC<Prop> = ({ navigation }) => {

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.wrapper}>
        <View style={styles.item}>
          <SvgXml xml={ProfileSVG} />
          <View style={styles.itemInfo}>
            <Text style={styles.label}>
              Transfer account
            </Text>
            <View style={styles.infoWrapper}>
              <Text style={styles.nameAmountText}>
                Main
              </Text>
              <Text style={styles.nameAmountText}>
                25,040 ZIL
              </Text>
            </View>
            <View style={[styles.infoWrapper, { marginBottom: 15 }]}>
              <Text style={styles.addressAmount}>
                zil1d...vgsnly
              </Text>
              <Text style={styles.addressAmount}>
              $ 105,250
              </Text>
            </View>
          </View>
          <SvgXml
            xml={ArrowIconSVG}
            fill="#666666"
            style={styles.arrowIcon}
          />
        </View>
        <View style={styles.item}></View>
      </View>
      <View></View>
      <View></View>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
  },
  wrapper: {
    backgroundColor: theme.colors.gray
  },
  item: {
    paddingHorizontal: 15,
    paddingVertical: 20,
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  itemInfo: {
    alignItems: 'flex-start',
    width: width - 90,
    borderBottomWidth: 1,
    borderColor: theme.colors.black
  },
  arrowIcon: {
    transform: [{ rotate: '-90deg'}],
    alignSelf: 'center'
  },
  label: {
    fontSize: 16,
    lineHeight: 21,
    color: '#8A8A8F',
    marginBottom: 7
  },
  infoWrapper: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: width - 100,
  },
  nameAmountText: {
    fontSize: 17,
    lineHeight: 22,
    color: theme.colors.white
  },
  addressAmount: {
    fontSize: 13,
    lineHeight: 17,
    color: '#8A8A8F'
  }
});
