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
  Dimensions
} from 'react-native';
import { RouteProp, useTheme } from '@react-navigation/native';
import { StackNavigationProp } from '@react-navigation/stack';

import { Chip } from 'app/components/chip';
import { Button } from 'app/components/button';

import { shuffle } from 'app/utils';
import { UnauthorizedStackParamList } from 'app/navigator/unauthorized';
import i18n from 'app/lib/i18n';

type Prop = {
  navigation: StackNavigationProp<UnauthorizedStackParamList>;
  route: RouteProp<UnauthorizedStackParamList, 'MnemonicVerif'>;
};

const { height } = Dimensions.get('window');
export const MnemonicVerifypage: React.FC<Prop> = ({ navigation, route }) => {
  const { colors } = useTheme();
  const [phrase] = React.useState(String(route.params.phrase));
  const [selectedWords, setSelectedWords] = React.useState<Set<string>>(new Set());
  const [shuffledWords, setShuffledWords] = React.useState(
    new Set(shuffle(phrase.split(' ')))
  );

  const buttonDisabled = React.useMemo(() => {
    const words = Array.from(selectedWords).join(' ');
    const trueWords = phrase;

    return words === trueWords;
  }, [selectedWords, phrase]);

  const handleRemove = React.useCallback((word) => {
    selectedWords.delete(word);
    shuffledWords.add(word);

    setSelectedWords(new Set(selectedWords));
    setShuffledWords(new Set(shuffledWords));
  }, [setShuffledWords, setSelectedWords]);
  const handleSelect = React.useCallback((word) => {
    selectedWords.add(word);
    shuffledWords.delete(word);

    setShuffledWords(new Set(shuffledWords));
    setSelectedWords(new Set(selectedWords));
  }, [setShuffledWords, setSelectedWords]);
  const hanldeContinue = React.useCallback(() => {
    navigation.navigate('SetupPassword', {
      phrase
    });
  }, [navigation, phrase]);

  return (
    <View style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <Text style={[styles.title, {
        color: colors.text
      }]}>
        {i18n.t('verify_title')}
      </Text>
      <View style={styles.verified}>
        {Array.from(selectedWords).map((word, index) => (
          <Chip
            key={index}
            style={styles.defaultChip}
            count={index + 1}
            onPress={() => handleRemove(word)}
          >
            {word}
          </Chip>
        ))}
      </View>
      <View style={styles.randoms}>
        {Array.from(shuffledWords).map((word, index) => (
          <Chip
            key={index}
            style={styles.defaultChip}
            onPress={() => handleSelect(word)}
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
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    height: '100%'
  },
  title: {
    textAlign: 'center',
    lineHeight: 41,
    fontSize: 31,
    fontWeight: 'bold',
    marginTop: height / 30
  },
  subTitle: {
    textAlign: 'center',
    lineHeight: 21,
    fontSize: 16,
    marginVertical: 50
  },
  verified: {
    flexDirection: 'row',
    paddingHorizontal: '3%',
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
  }
});

export default MnemonicVerifypage;
