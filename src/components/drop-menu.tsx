/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import { useTheme } from '@react-navigation/native';
import { fonts } from 'app/styles';
import React from 'react';
import {
  TouchableOpacity,
  Text,
  StyleSheet,
  ActivityIndicator,
  Dimensions,
  ScrollView,
  View,
  ViewStyle
} from 'react-native';
import { SvgXml } from 'react-native-svg';

import { ArrowIconSVG, OKIconSVG } from 'app/components/svg';
import Modal from 'react-native-modal';
import { ModalWrapper } from 'app/components/modal-wrapper';
import { ModalTitle } from 'app/components/modal-title';
import { CustomButton } from 'app/components/custom-button';
import { Unselected } from 'app/components/unselected';

import i18n from 'app/lib/i18n';

interface El {
  name: string;
  value?: string;
}

type Prop = {
  title: string;
  selected: El;
  isLoading?: boolean;
  list: El[];
  style?: ViewStyle;
  onUpdate: () => void;
  onSelect: (index: El) => void;
};

const { width } = Dimensions.get('window');
export const DropMenu: React.FC<Prop> = ({
  selected,
  title,
  list,
  isLoading,
  style,
  onUpdate,
  onSelect
}) => {
  const { colors } = useTheme();
  const [visible, setVisible] = React.useState(false);

  const hanldeUpdate = React.useCallback(() => {
    onUpdate();
    setVisible(false);
  }, []);
  const hanldeSelect = React.useCallback((el) => {
    onSelect(el);
    setVisible(false);
  }, []);

  return (
    <React.Fragment>
      <TouchableOpacity
        style={[styles.button, style, {
          borderColor: colors.primary,
          opacity: isLoading ? 0.5 : 1
        }]}
        disabled={isLoading}
        onPress={() => setVisible(true)}
      >
        {isLoading ? (
          <ActivityIndicator
            animating={isLoading}
            color={colors.primary}
          />
        ) : (
          <Text style={[styles.buttonText, {
            color: colors.primary
          }]}>
            {list.length === 0 ? '' : selected.name}
          </Text>
        )}
        <SvgXml
          xml={ArrowIconSVG}
          fill={colors.primary}
        />
      </TouchableOpacity>
      <Modal
        isVisible={visible}
        backdropColor={colors['modal']}
        onBackdropPress={() => setVisible(false)}
      >
        <ModalWrapper style={styles.modalWrapper}>
          <ModalTitle onClose={() => setVisible(false)}>
            {title}
          </ModalTitle>
          <ScrollView style={styles.container}>
            {list.map((item, index) => (
              <TouchableOpacity
                key={index}
                style={[styles.item, {
                  borderBottomColor: colors.border,
                  borderBottomWidth: index === list.length - 1 ? 0 : 1
                }]}
                onPress={() => hanldeSelect(item)}
              >
                {selected.name === item.name ? (
                  <SvgXml xml={OKIconSVG(colors.primary)} />
                ) : (
                  <Unselected />
                )}
                <View style={styles.el}>
                  <Text style={[styles.itemText, {
                    color: colors.text
                  }]}>
                    {item.name}
                  </Text>
                  <Text style={[styles.itemText, {
                    color: colors.text
                  }]}>
                    {item.value || ''}
                  </Text>
                </View>
              </TouchableOpacity>
            ))}
          </ScrollView>
          <CustomButton
            title={i18n.t('update')}
            onPress={hanldeUpdate}
          />
        </ModalWrapper>
      </Modal>
    </React.Fragment>
  );
};

const styles = StyleSheet.create({
  container: {
    marginVertical: 10
  },
  fadingContainer: {
    paddingVertical: 5,
    paddingHorizontal: 25
  },
  el: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: width - 110
  },
  itemText: {
    fontSize: 17,
    fontFamily: fonts.Regular,
    marginLeft: 16
  },
  button: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginHorizontal: 30,
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderWidth: 1,
    borderRadius: 12
  },
  item: {
    paddingVertical: 13,
    flexDirection: 'row',
    alignItems: 'center'
  },
  buttonText: {
    fontSize: 14,
    fontFamily: fonts.Demi
  },
  modalWrapper: {
    borderRadius: 16,
    maxHeight: '80%'
  }
});
