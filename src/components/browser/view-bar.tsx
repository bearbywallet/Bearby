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
  StyleSheet,
  TouchableOpacity,
  View,
  Dimensions,
  Text
} from 'react-native';
import URL from 'url-parse';
import { useTheme } from '@react-navigation/native';

import { SvgXml } from 'react-native-svg';
import { ArrowIconSVG, LockSVG, HomeIconSVG } from 'app/components/svg';
import RepeatSVG from 'app/assets/repeat.svg';

type Prop = {
  url: URL;
  canGoForward: boolean;
  onBack: () => void;
  onHome: () => void;
  onRefresh: () => void;
  onGoForward: () => void;
};

const { width } = Dimensions.get('window');
export const BrowserViewBar: React.FC<Prop> = ({
  url,
  canGoForward,
  onBack,
  onRefresh,
  onHome,
  onGoForward
}) => {
  const { colors } = useTheme();

  return (
    <View style={[styles.nav, {
      backgroundColor: colors.background
    }]}>
      <View style={styles.navBtns}>
        <TouchableOpacity onPress={onBack}>
          <SvgXml
            xml={ArrowIconSVG}
            height="30"
            width="30"
            fill={colors.primary}
            style={{
              transform: [{ rotate: '90deg' }]
            }}
          />
        </TouchableOpacity>
        <TouchableOpacity onPress={onHome}>
          <SvgXml
            xml={HomeIconSVG}
            height="30"
            width="30"
            fill={colors.primary}
          />
        </TouchableOpacity>
        <TouchableOpacity
          disabled={!canGoForward}
          onPress={onGoForward}
        >
          <SvgXml
            xml={ArrowIconSVG}
            height="30"
            width="30"
            fill={canGoForward ? colors.primary : colors.notification}
            style={{
              transform: [{ rotate: '-90deg' }]
            }}
          />
        </TouchableOpacity>
      </View>
      <View style={styles.hostWrapper}>
        <SvgXml
          xml={LockSVG}
          height="15"
          width="15"
          fill={url.protocol.includes('https') ? colors.text : colors['danger']}
        />
        <Text style={[styles.host, {
          color: colors.text
        }]}>
          {url.hostname}
        </Text>
      </View>
      <TouchableOpacity onPress={onRefresh}>
        <RepeatSVG
          fill={colors.primary}
          width={30}
          height={30}
        />
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  nav: {
    height: 50,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around'
  },
  navBtns: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: 100
  },
  hostWrapper: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  host: {
    fontWeight: 'bold',
    fontSize: 17,
    lineHeight: 22,
    minWidth: width / 3
  }
});
