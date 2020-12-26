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
  Text,
  Button
} from 'react-native';
import { StackNavigationProp } from '@react-navigation/stack';
import { useTheme } from '@react-navigation/native';

import i18n from 'app/lib/i18n';
import { splitByChunk } from 'app/utils';
import { UnauthorizedStackParamList } from 'app/navigator/unauthorized';
import { Mnemonic } from 'app/lib/controller/mnemonic';

type Prop = {
  navigation: StackNavigationProp<UnauthorizedStackParamList>;
};

const AMOUNT_OF_WORDS_IN_LINE = 3;
const mnemonic = new Mnemonic();
export const MnemonicGenPage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();
  const [phrase, setPhrase] = React.useState('');

  const words = React.useMemo(() => {
    const splited = phrase.split(' ');

    return splitByChunk<string>(splited, AMOUNT_OF_WORDS_IN_LINE);
  }, [phrase]);

  const hanldeUpdate = React.useCallback(async () => {
    const seedPhrase = await mnemonic.generateMnemonic();

    setPhrase(seedPhrase);
  }, [setPhrase]);

  React.useEffect(() => {
    mnemonic
      .generateMnemonic()
      .then((seedPhrase) => setPhrase(seedPhrase));
  }, [setPhrase]);

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
        {words.map((chunk, index) => (
          <View
            key={index}
            style={styles.lineContainer}
          >
            {chunk.map((word, wordIndex) => (
              <View
                key={wordIndex + AMOUNT_OF_WORDS_IN_LINE}
                style={styles.wordContainer}
              >
                <Text style={styles.wordNumber}>
                  {wordIndex + 1}
                </Text>
                <Text style={[styles.word, {
                  color: colors.text
                }]}>
                  {word}
                </Text>
              </View>
            ))}
          </View>
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
          onPress={() => navigation.navigate('MnemonicVerif', { phrase })}
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
    fontWeight: 'bold',
    marginTop: 30
  },
  subTitle: {
    textAlign: 'center',
    lineHeight: 21,
    fontSize: 16,
  },
  phraseContainer: {
    flex: 1,
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    maxWidth: 300,
    textAlign: 'center'
  },
  lineContainer: {
    flexDirection: 'row',
    width: '100%',
    justifyContent: 'space-between'
  },
  wordContainer: {
    flexDirection: 'row',
    marginTop: 60,
    minWidth: 120
  },
  wordNumber: {
    lineHeight: 21,
    fontSize: 16,
    color: '#8A8A8F'
  },
  word: {
    lineHeight: 21,
    fontSize: 16,
    marginLeft: 4
  },
  btnsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: '60%',
    marginBottom: 50
  }
});

export default MnemonicGenPage;
