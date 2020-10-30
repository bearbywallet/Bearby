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

/**
 * Map of color names to HEX values
 */
export const colors = {
  primary: '#2CB9B0',
  secondary: '#0C0D34',
  gray: '#1D2024',
  success: '#00D99A',
  danger: '#FF0058',
  warning: '#FFC641',
  info: '#50B9DE',
  light: '#F6F6F6',
  black: '#000',
  muted: '#C4C4C4',
  white: '#fff'
};

/**
 * Map of reusable fonts
 */
export const fontStyles = {
  // [Fonts.Bold]: require('assets/fonts/SF-Pro-Display-Bold.otf'),
  // [Fonts.Light]: require('assets/fonts/SF-Pro-Display-Light.otf'),
  // [Fonts.Medium]: require('assets/fonts/SF-Pro-Display-Medium.otf'),
  // [Fonts.Regilar]: require('assets/fonts/SF-Pro-Display-Regular.otf')
};

export const theme = {
  ...DefaultTheme,
  colors: {
    ...colors,
    background: '#18191D',
    card: '#50B9DE',
    text: '#000',
    border: '#0c0d3480',
    notification: '#fff'
  }
};