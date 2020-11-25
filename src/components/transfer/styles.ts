/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { StyleSheet, Dimensions } from 'react-native';
import { theme } from 'app/styles';

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
    borderBottomColor: theme.colors.black,
    borderBottomWidth: 1
  },
  percentWrapper: {
    justifyContent: 'space-around',
    flexDirection: 'row',
    paddingVertical: 5,
    marginTop: 10
  },
  percent: {
    color: theme.colors.primary,
    fontSize: 16,
    lineHeight: 21
  },
  itemInfo: {
    alignItems: 'flex-start',
    width: width - 90,
    borderBottomWidth: 1,
    borderColor: theme.colors.black
  },
  receivinglabel: {
    fontSize: 16,
    lineHeight: 21,
    width: width - 100,
    color: '#8A8A8F'
  },
  receiving: {
    padding: 15,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  addressAmount: {
    fontSize: 13,
    lineHeight: 17,
    color: '#8A8A8F'
  },
  label: {
    fontSize: 16,
    lineHeight: 21,
    color: '#8A8A8F',
    marginBottom: 7
  },
  arrowIcon: {
    transform: [{ rotate: '-90deg'}],
    alignSelf: 'center'
  },
  textInput: {
    fontSize: 17,
    lineHeight: 22,
    padding: 10,
    color: theme.colors.white,
    width: width - 100
  },
  nameAmountText: {
    fontSize: 17,
    lineHeight: 22,
    color: theme.colors.white
  }
});
