/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import { useTheme } from '@react-navigation/native';
import {
  View,
  StyleSheet,
  Animated,
  Easing,
  Dimensions,
  ViewStyle
} from 'react-native';

const { width } = Dimensions.get('window');
export const BrowserCategoryLoading: React.FC<ViewStyle> = (props) => {
  const { colors } = useTheme();
  const [animatedOpacity] = React.useState(new Animated.Value(1));
  const [fadingContainer] = React.useState({
      ...styles.fadingContainer,
      opacity: animatedOpacity
  });

  const endFade = () => {
    Animated.timing(animatedOpacity, {
        toValue: 1,
        duration: 600,
        easing: Easing.cubic,
        useNativeDriver: true
    }).start(() => {
      startFade();
    });
  };

  const startFade = () => {
    Animated.timing(animatedOpacity, {
        toValue: 0.4,
        duration: 600,
        easing: Easing.cubic,
        useNativeDriver: true
    }).start(() => {
      endFade();
    });
  };

  React.useEffect(() => {
    startFade();

    return () => {
      animatedOpacity.stopAnimation();
    };
  }, []);

  return (
    <Animated.View style={fadingContainer}>
      <View
        {...props}
        style={[styles.container, {
          backgroundColor: colors['card1']
        }]}
      >
        <View style={[styles.fadeIcon, {
          backgroundColor: colors.card
        }]}/>
        <View style={styles.fadeLineWrapper}>
          <View style={[styles.fadeLine, {
            backgroundColor: colors.card,
            height: 20,
            width: width / 2
          }]}/>
          <View style={[styles.fadeLine, {
            backgroundColor: colors.card,
            height: 16,
            width: width / 3
          }]}/>
        </View>
      </View>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    borderRadius: 8,
    width: '100%',
    height: 60,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-evenly'
  },
  fadingContainer: {
    alignItems: "center",
    justifyContent: "center",
  },
  fadeLineWrapper: {
    justifyContent: 'space-between',
    height: 40
  },
  fadeLine: {
    borderRadius: 3
  },
  fadeIcon: {
    height: 40,
    width: 40,
    borderRadius: 100
  }
});
