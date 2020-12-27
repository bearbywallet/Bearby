/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */

/**
 * Base styles and variables
 */
import { DefaultTheme } from '@react-navigation/native';

export const colors = {
  success: '#00D99A',
  danger: '#FF0058',
  warning: '#FFC641',
  black: '#000',
  white: '#fff',
  info: '#50B9DE'
};

export const dark = {
  ...DefaultTheme,
  dark: true,
  colors: {
    ...colors,
    primary: '#29CCC4',
    background: '#09090C',
    card: '#18191D',
    text: '#FFFFFF',
    border: '#8A8A8F',
    notification: '#666666'
  }
};
export const light = {
  ...DefaultTheme,
  dark: false,
  colors: {
    ...colors,
    primary: '#21A0B1',
    background: '#E1E7FF',
    card: '#F9F9F9',
    text: '#32335A',
    border: '#8A8A8F',
    notification: '#8E8EAE'
  }
};
