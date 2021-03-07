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
  ScrollView,
  TextInput,
  Text
} from 'react-native';
import URL from 'url-parse';
import { useTheme } from '@react-navigation/native';

import { SvgXml } from 'react-native-svg';
import { ArrowIconSVG, LockSVG, HomeIconSVG } from 'app/components/svg';
import RepeatSVG from 'app/assets/repeat.svg';

import { fonts } from 'app/styles';

type Prop = {
  url: URL;
  canGoForward: boolean;
  onBack: () => void;
  onHome: () => void;
  onRefresh: () => void;
  onGoForward: () => void;
  onSubmit: (text: string) => void;
};

const { width } = Dimensions.get('window');
export const BrowserViewBar: React.FC<Prop> = ({
  url,
  canGoForward,
  onBack,
  onRefresh,
  onHome,
  onGoForward,
  onSubmit
}) => {
  const { colors } = useTheme();
  const [typing, isTyping] = React.useState(false);
  const [menu, setMenu] = React.useState(false);

  const urlValue = React.useMemo(() => {
    if (typing) {
      return url.toString();
    }

    return url.hostname;
  }, [typing, url]);

  return (
    <React.Fragment>
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
        </View>
        <View style={[styles.hostWrapper, {
          backgroundColor: colors['bg1']
        }]}>
          <SvgXml
            xml={LockSVG}
            height="15"
            width="15"
            fill={url.protocol.includes('https') ? colors.text : colors['danger']}
          />
          <TextInput
            style={[styles.host, {
              color: colors.text
            }]}
            selectTextOnFocus
            autoCorrect={false}
            autoCapitalize={'none'}
            textContentType={'URL'}
            defaultValue={urlValue}
            onFocus={() => isTyping(true)}
            onBlur={() => isTyping(false)}
            onSubmitEditing={(e) => onSubmit(e.nativeEvent.text)}
          />
        </View>
        <TouchableOpacity
          style={styles.dotWrapper}
          onPress={() => setMenu(!menu)}
        >
          <View style={[styles.dot, {
            backgroundColor: colors.primary
          }]}/>
          <View style={[styles.dot, {
            backgroundColor: colors.primary
          }]}/>
          <View style={[styles.dot, {
            backgroundColor: colors.primary
          }]}/>
        </TouchableOpacity>
      </View>
      {menu ? (
        <ScrollView style={[styles.navMenu, {
          backgroundColor: colors['bg1'],
          shadowColor: colors.border
        }]}>
          <View style={styles.navActionWrapper}>
            <TouchableOpacity
              disabled={!canGoForward}
              onPress={onGoForward}
            >
              <SvgXml
                xml={ArrowIconSVG}
                height={30}
                width={30}
                fill={canGoForward ? colors.primary : colors.notification}
                style={{
                  transform: [{ rotate: '-90deg' }]
                }}
              />
            </TouchableOpacity>
            <TouchableOpacity onPress={onHome}>
              <SvgXml
                xml={HomeIconSVG}
                height={25}
                width={25}
                fill={colors.primary}
              />
            </TouchableOpacity>
            <TouchableOpacity onPress={onRefresh}>
              <RepeatSVG
                fill={colors.primary}
                width={30}
                height={30}
              />
            </TouchableOpacity>
            <TouchableOpacity onPress={onRefresh}>
              <RepeatSVG
                fill={colors.primary}
                width={30}
                height={30}
              />
            </TouchableOpacity>
          </View>
        </ScrollView>
      ) : null}
    </React.Fragment>
  );
};

const styles = StyleSheet.create({
  nav: {
    height: 55,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around'
  },
  navMenu: {
    position: 'absolute',
    height: 100,
    top: 40,
    right: 20,
    left: width / 3,
    alignContent: 'flex-end',
    zIndex: 99,
    borderRadius: 5,
    textShadowOffset: {
      width: 2,
      height: 2
    },
    elevation: 5,
    shadowOpacity: 0.5,
    shadowRadius: 2
  },
  navActionWrapper: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: 5
  },
  navBtns: {
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  hostWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-start',
    width: '80%',
    height: 40,
    paddingHorizontal: 16,
    borderRadius: 10
  },
  host: {
    fontFamily: fonts.Demi,
    fontSize: 17,
    textAlign: 'left',
    width: '100%'
  },
  dotWrapper: {
    justifyContent: 'space-around',
    alignItems: 'center',
    height: 30,
    width: 30
  },
  dot: {
    padding: 3,
    borderRadius: 100
  }
});
