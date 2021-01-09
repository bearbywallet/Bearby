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

export enum fonts {
  Regular = 'AvenirNextLTPro-Regular',
  Demi = 'AvenirNextLTPro-Demi',
  Bold = 'AvenirNextLTPro-Bold'
}

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
    primary: '#00B9B6',
    background: '#09090C',
    card: '#18191D',
    card1: '#2B2E33',
    text: '#FFFFFF',
    border: '#8A8A8F',
    notification: '#666666',
    modal: '#000'
  }
};
export const light = {
  ...DefaultTheme,
  dark: false,
  colors: {
    ...colors,
    primary: '#009AAE',
    background: '#E7EBFE',
    card: '#FFFFFF',
    card1: '#E7EBFE',
    text: '#32335A',
    border: '#B9B9D7',
    notification: '#8E8EAE',
    modal: '#000'
  }
};

export const theme = {
  Dark: dark,
  Light: light
};
