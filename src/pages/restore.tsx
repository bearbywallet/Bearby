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
  Button,
  SafeAreaView,
  Keyboard,
  Dimensions,
  TextInput
} from 'react-native';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';
import { StackNavigationProp } from '@react-navigation/stack';

import { theme } from 'app/styles';
import { UnauthorizedStackParamList } from 'app/navigator/unauthorized';
import i18n from 'app/lib/i18n';
import { Mnemonic } from 'app/lib/controller/mnemonic';

type Prop = {
  navigation: StackNavigationProp<UnauthorizedStackParamList>;
};

const { height } = Dimensions.get('window');
export const RestorePage: React.FC<Prop> = ({ navigation }) => {
  const [disabled, setDisabled] = React.useState(true);
  const [phrase, setphrase] = React.useState<string>('');

  const hanldeChange = React.useCallback(async(value) => {
    const mnemonic = new Mnemonic();
    const isValid = await mnemonic.validateMnemonic(value);

    setDisabled(!isValid);
    setphrase(value);

    if (isValid) {
      Keyboard.dismiss();
    }
  }, [setDisabled, setphrase]);
  const hanldecreateWallet = React.useCallback(() => {
    navigation.navigate('SetupPassword', {
      phrase
    });
  }, [phrase, navigation]);

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAwareScrollView>
        <View style={styles.pageContainer}>
          <Text style={styles.title}>
            {i18n.t('restore_title')}
          </Text>
          <TextInput
            multiline={true}
            numberOfLines={10}
            style={styles.text}
            placeholder={i18n.t('restore_placeholder')}
            placeholderTextColor="#2B2E33"
            onChangeText={hanldeChange}
          />
        </View>
        <Button
          title={i18n.t('restore_btn')}
          color={theme.colors.primary}
          disabled={disabled}
          onPress={hanldecreateWallet}
        />
      </KeyboardAwareScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.black
  },
  pageContainer: {
    marginTop: 54,
    justifyContent: 'flex-start',
    paddingHorizontal: 16,
    marginBottom: '5%'
  },
  title: {
    textAlign: 'center',
    fontWeight: 'bold',
    color: theme.colors.white,
    fontSize: 34,
    lineHeight: 41
  },
  text: {
    marginTop: 60,
    height: height / 5,
    borderColor: '#2B2E33',
    borderWidth: 1,
    borderRadius: 8,
    color: theme.colors.white,
    padding: 20,
    fontSize: 23
  }
});

export default RestorePage;
