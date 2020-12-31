/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { fonts } from 'app/styles';
import { StyleSheet, Dimensions } from 'react-native';

const { width } = Dimensions.get('window');
export default StyleSheet.create({
  item: {
    paddingHorizontal: 15,
    paddingTop: 15,
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  infoWrapper: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: width - 100
  },
  inputWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    borderBottomWidth: 1
  },
  percentWrapper: {
    justifyContent: 'space-around',
    flexDirection: 'row',
    paddingVertical: 5,
    marginTop: 10
  },
  percent: {
    fontSize: 16,
    fontFamily: fonts.Demi
  },
  itemInfo: {
    alignItems: 'flex-start',
    width: width - 90
  },
  receivinglabel: {
    fontSize: 16,
    fontFamily: fonts.Regular,
    width: width - 100
  },
  receiving: {
    padding: 15,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  addressAmount: {
    fontSize: 13,
    fontFamily: fonts.Regular
  },
  label: {
    fontFamily: fonts.Demi,
    fontSize: 16,
    marginBottom: 7
  },
  arrowIcon: {
    transform: [{ rotate: '-90deg'}],
    alignSelf: 'center'
  },
  nameAmountText: {
    fontSize: 17,
    lineHeight: 22
  }
});
