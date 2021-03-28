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
  Keyboard,
  Dimensions,
  TextInput
} from 'react-native';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';
import { useTheme } from '@react-navigation/native';
import SafeAreaView from 'react-native-safe-area-view';
import { StackNavigationProp } from '@react-navigation/stack';

import { Button } from 'app/components/button';

import { UnauthorizedStackParamList } from 'app/navigator/unauthorized';
import i18n from 'app/lib/i18n';
import { Mnemonic } from 'app/lib/controller/mnemonic';
import { fonts } from 'app/styles';
import { keystore } from 'app/keystore';

type Prop = {
  navigation: StackNavigationProp<UnauthorizedStackParamList>;
};
const placeholder = 'shock silent awful guard long thing early test thought defy treat pink';
const { height } = Dimensions.get('window');
export const RestorePage: React.FC<Prop> = ({ navigation }) => {
  const { colors } = useTheme();
  const [phrase, setphrase] = React.useState<string>('');
  const [errorMessage, setErrorMessage] = React.useState<string>('');

  const hanldeChange = React.useCallback(async(value: string) => {
    setErrorMessage('');
    value = String(value).toLowerCase();
    const mnemonic = new Mnemonic();
    const isValid = await mnemonic.validateMnemonic(value);

    setphrase(value);

    if (isValid) {
      Keyboard.dismiss();
    }
  }, []);
  const hanldecreateWallet = React.useCallback(async() => {
    if (phrase.split(' ').length < 12) {
      setErrorMessage(i18n.t('mnemonic_error0'));

      return null;
    }

    const mnemonic = new Mnemonic();
    const isValid = await mnemonic.validateMnemonic(phrase);

    if (!isValid) {
      setErrorMessage(i18n.t('mnemonic_error1'));

      return null;
    }

    navigation.navigate('SetupPassword', {
      phrase
    });
  }, [phrase, navigation]);

  React.useEffect(() => {
    keystore.guard.screenForbid();

    return () => keystore.guard.screenAllow();
  }, [navigation]);

  return (
    <SafeAreaView style={[styles.container, {
      backgroundColor: colors.background
    }]}>
      <KeyboardAwareScrollView>
        <View style={styles.pageContainer}>
          <Text style={[styles.title, {
            color: colors.text
          }]}>
            {i18n.t('restore_title')}
          </Text>
          <View style={styles.imputContainer}>
            <Text style={[styles.helps, {
              color: colors.border
            }]}>
              {i18n.t('mnemonic_des')}
            </Text>
            <TextInput
              multiline={true}
              numberOfLines={10}
              autoCorrect={false}
              style={[styles.text, {
                borderColor: errorMessage ? colors['danger'] : colors.border,
                color: colors.text
              }]}
              placeholder={placeholder}
              placeholderTextColor={colors.border}
              onChangeText={hanldeChange}
            />
            <Text style={[styles.helps, {
              color: colors['danger']
            }]}>
              {errorMessage}
            </Text>
          </View>
        </View>
        <Button
          title={i18n.t('restore_btn')}
          color={colors.primary}
          onPress={hanldecreateWallet}
        />
      </KeyboardAwareScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1
  },
  pageContainer: {
    marginTop: 54,
    justifyContent: 'flex-start',
    paddingHorizontal: 16,
    marginBottom: '5%'
  },
  title: {
    textAlign: 'center',
    fontFamily: fonts.Bold,
    fontSize: 34,
    lineHeight: 41
  },
  imputContainer: {
    marginTop: 30
  },
  helps: {
    marginLeft: 8,
    marginVertical: 5,
    fontSize: 15,
    fontFamily: fonts.Regular
  },
  text: {
    height: height / 5,
    fontFamily: fonts.Regular,
    borderWidth: 1,
    borderRadius: 8,
    padding: 20,
    fontSize: 23
  }
});

export default RestorePage;
