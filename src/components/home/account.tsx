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
  Dimensions
} from 'react-native';
import { SvgXml } from 'react-native-svg';
import { useStore } from 'effector-react';

import { DropDownMenu } from 'app/components/drop-down-menu';
import { LogoSVG } from 'app/components/svg';

import { WalletContext } from 'app/keystore';
import { theme } from 'app/styles';
import I18n from 'app/lib/i18n';

const { width } = Dimensions.get('window');
export const HomeAccount: React.FC = () => {
  const keystore = React.useContext(WalletContext);
  const accountState = useStore(keystore.account.store);

  return (
    <View style={styles.container}>
      <SvgXml
        xml={LogoSVG}
        width={width}
        viewBox="50 0 320 220"
      />
      <View style={[StyleSheet.absoluteFill, styles.content]}>
        <DropDownMenu>
          Account 0
        </DropDownMenu>
        <View style={styles.amountWrapper}>
          <Text style={styles.amount}>
            25,040
            <Text style={styles.symbol}>
              ZIL
            </Text>
          </Text>
          <Text style={styles.convertedAmount}>
            $ 105,250
          </Text>
        </View>
        <View style={styles.buttons}>
          <Button
            color={theme.colors.primary}
            title={I18n.t('send')}
            onPress={() => null}
          />
          <View style={styles.seporate}/>
          <Button
            color={theme.colors.primary}
            title={I18n.t('receive')}
            onPress={() => null}
          />
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
    height: 300,
    alignItems: 'center',
    justifyContent: 'center'
  },
  content: {
    top: 0,
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingBottom: 15,
    paddingTop: 50
  },
  amountWrapper: {
    alignItems: 'center',
    // minHeight: 50
  },
  amount: {
    color: theme.colors.white,
    fontSize: 44,
    fontWeight: 'bold'
  },
  symbol: {
    fontSize: 17,
    fontWeight: 'normal',
    color: theme.colors.white
  },
  convertedAmount: {
    color: '#8A8A8F',
    fontSize: 13
  },
  buttons: {
    flexDirection: 'row',
    justifyContent: 'space-evenly',
    alignItems: 'center',
    width: 150,
    marginLeft: 20
  },
  seporate: {
    width: 1,
    height: 40,
    backgroundColor: '#666666'
  }
});
