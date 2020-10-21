/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import React from 'react';
import { SafeAreaView, Button, StyleSheet, Text } from 'react-native';

import { WalletControler } from '../lib/controller';

import { colors } from '../styles';

const wallet = new WalletControler();

export const CreateWalletPage = () => {
  const [mnemonic, setMnemonic] = React.useState<string>('');

  const generateSeed = React.useCallback(async() => {
    const mnemonicPhrase = await wallet.generateMnemonic();

    setMnemonic(mnemonicPhrase);
  }, [mnemonic, setMnemonic]);

  React.useEffect(() => {
    generateSeed();
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <Button
        title="generate"
        onPress={generateSeed}
      />
      <Text style={styles.mnemonic}>
        {mnemonic}
      </Text>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.secondary
  },
  mnemonic: {
    color: colors.info,
    padding: 20
  }
});
