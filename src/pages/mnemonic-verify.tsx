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
  Dimensions,
  ScrollView
} from 'react-native';
import { RouteProp, useTheme } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';

import { Chip } from 'app/components/chip';
import { Button } from 'app/components/button';

import { shuffle } from 'app/utils/shuffle';
import { UnauthorizedStackParamList } from 'app/navigator/unauthorized';
import i18n from 'app/lib/i18n';
import { fonts } from 'app/styles';
import { keystore } from 'app/keystore';

type Prop = {
  navigation: StackNavigationProp<UnauthorizedStackParamList>;
  route: RouteProp<UnauthorizedStackParamList, 'MnemonicVerif'>;
};

const { width } = Dimensions.get('window');
export const MnemonicVerifypage: React.FC<Prop> = ({ navigation, route }) => {
  const { colors } = useTheme();
  const [phrase] = React.useState(route.params.phrase);
  const [selectedWords, setSelectedWords] = React.useState<string[]>([]);
  const [shuffledWords, setShuffledWords] = React.useState(
    shuffle(phrase.split(' '))
  );

  const buttonDisabled = React.useMemo(() => {
    const words = selectedWords.join(' ');
    const trueWords = phrase;

    return words === trueWords;
  }, [selectedWords, phrase]);

  const handleRemove = React.useCallback((word, index) => {
    setSelectedWords(selectedWords.filter((_, i) => index !== i));
    setShuffledWords([...shuffledWords, word]);
  }, [shuffledWords, selectedWords]);
  const handleSelect = React.useCallback((word, index) => {
    setShuffledWords(shuffledWords.filter((_, i) => index !== i));
    setSelectedWords([...selectedWords, word]);
  }, [selectedWords, selectedWords]);
  const hanldeContinue = React.useCallback(() => {
    navigation.navigate('SetupPassword', {
      phrase
    });
  }, [navigation, phrase]);

  React.useEffect(() => {
    keystore.guard.screenForbid();

    return () => keystore.guard.screenAllow();
  }, [navigation]);

  return (
    <View>
      <ScrollView>
        <Text style={[styles.title, {
          color: colors.text
        }]}>
          {i18n.t('verify_title')}
        </Text>
        <View style={styles.verified}>
          {selectedWords.map((word, index) => (
            <Chip
              key={`${index}s`}
              style={styles.defaultChip}
              count={index + 1}
              onPress={() => handleRemove(word, index)}
            >
              {word}
            </Chip>
          ))}
        </View>
        <View style={[styles.seporate, {
          backgroundColor: colors.card
        }]}/>
        <View style={styles.randoms}>
          {shuffledWords.map((word, index) => (
            <Chip
              key={`${index}r`}
              style={styles.defaultChip}
              onPress={() => handleSelect(word, index)}
            >
              {word}
            </Chip>
          ))}
        </View>
        <View>
          <Text style={[styles.subTitle, {
            color: colors.border
          }]}>
            {i18n.t('verify_sub_title')}
          </Text>
          <Button
            title={i18n.t('verify_btn')}
            color={colors.primary}
            disabled={!buttonDisabled}
            onPress={hanldeContinue}
          />
        </View>
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  title: {
    textAlign: 'center',
    lineHeight: 41,
    fontSize: 31,
    fontFamily: fonts.Bold
  },
  subTitle: {
    textAlign: 'center',
    lineHeight: 21,
    fontSize: 16,
    fontFamily: fonts.Regular,
    marginVertical: 50
  },
  verified: {
    flexDirection: 'row',
    paddingHorizontal: width / 10,
    flexWrap: 'wrap',
    justifyContent: 'space-between'
  },
  randoms: {
    flexDirection: 'row',
    paddingHorizontal: '3%',
    flexWrap: 'wrap',
    alignItems: 'center',
    justifyContent: 'center'
  },
  defaultChip: {
    margin: 8
  },
  seporate: {
    width: '100%',
    height: 2
  }
});

export default MnemonicVerifypage;
