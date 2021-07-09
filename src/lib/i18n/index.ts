/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */
import I18n from 'react-native-i18n';
import en from './en';
import ru from './ru';

I18n.fallbacks = true;

I18n.translations = {
  en,
  ru
};

export default I18n;
