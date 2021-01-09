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
  StyleSheet,
  Dimensions,
  Text
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { useTheme } from '@react-navigation/native';

import { Button } from 'app/components/button';
import { Chip } from 'app/components/chip';

import i18n from 'app/lib/i18n';
import { UnauthorizedStackParamList } from 'app/navigator/unauthorized';
import { Mnemonic } from 'app/lib/controller/mnemonic';
import { fonts } from 'app/styles';
import { keystore } from 'app/keystore';

type Prop = {
  navigation: StackNavigationProp<UnauthorizedStackParamList>;
};

const { width } = Dimensions.get('window');
const mnemonic = new Mnemonic();
export const MnemonicGenPage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();
  const [phrase, setPhrase] = React.useState('');

  const hanldeUpdate = React.useCallback(async () => {
    const seedPhrase = await mnemonic.generateMnemonic();

    setPhrase(seedPhrase);
  }, [setPhrase]);

  React.useEffect(() => {
    mnemonic
      .generateMnemonic()
      .then((seedPhrase) => setPhrase(seedPhrase));
  }, [setPhrase]);

  React.useEffect(() => {
    keystore.guard.screenForbid();

    return () => keystore.guard.screenAllow();
  }, [navigation]);

  return (
    <View style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <Text style={[styles.title, {
        color: colors.text
      }]}>
        {i18n.t('mnemonic_title')}
      </Text>
      <Text style={[styles.subTitle, {
        color: colors.border
      }]}>
        {i18n.t('mnemonic_sub_title')}
      </Text>
      <View style={styles.phraseContainer}>
        {phrase.split(' ').map((word, index) => (
          <Chip
            key={index}
            style={styles.defaultChip}
            count={index + 1}
            disabled
          >
            {word}
          </Chip>
        ))}
      </View>
      <View style={styles.btnsContainer}>
        <Button
          title={i18n.t('mnemonic_btn0')}
          color={colors.primary}
          onPress={hanldeUpdate}
        />
        <Button
          title={i18n.t('mnemonic_btn1')}
          color={colors.primary}
          onPress={() => navigation.navigate('MnemonicVerif', {
            phrase
          })}
        />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center'
  },
  title: {
    textAlign: 'center',
    lineHeight: 41,
    fontSize: 31,
    fontFamily: fonts.Bold,
    marginTop: 30
  },
  subTitle: {
    textAlign: 'center',
    fontFamily: fonts.Regular,
    lineHeight: 21,
    fontSize: 16
  },
  phraseContainer: {
    flex: 1,
    flexDirection: 'row',
    paddingHorizontal: '3%',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    maxWidth: width / 1.2
  },
  defaultChip: {
    margin: 8
  },
  btnsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: '60%',
    marginBottom: 50
  }
});

export default MnemonicGenPage;
