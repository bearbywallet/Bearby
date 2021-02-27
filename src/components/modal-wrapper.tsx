/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { useTheme } from '@react-navigation/native';
import React from 'react';
import {
  StyleSheet,
  Dimensions,
  ViewStyle,
  Keyboard,
  View
} from 'react-native';

import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';

type Prop = {
  style?: ViewStyle;
};

enum Events {
  KeyboardDidShow = 'keyboardDidShow',
  KeyboardDidHide = 'keyboardDidHide'
}

const { height } = Dimensions.get('window');
export const ModalWrapper: React.FC<Prop> = ({ children, style }) => {
  const { colors } = useTheme();
  const [minHeight, setMinHeight] = React.useState(height / 5);

  React.useEffect(() => {
    Keyboard.addListener(Events.KeyboardDidShow, () => {
      setMinHeight(height / 1.5);
    });
    Keyboard.addListener(Events.KeyboardDidHide, () => {
      setMinHeight(height / 5);
    });

    return () => {
      Keyboard.removeAllListeners(Events.KeyboardDidShow);
      Keyboard.removeAllListeners(Events.KeyboardDidHide);
    };
  });

  return (
    <View
      style={[styles.container, style, {
        backgroundColor: colors.background,
        minHeight: minHeight
      }]}
    >
      {children}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 15,
    borderTopEndRadius: 16,
    borderTopStartRadius: 16,
    paddingVertical: 15,
    maxHeight: height - 50
  }
});
