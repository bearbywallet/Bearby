/*
 * Project: ZilPay-wallet
 * Author: Rinat(lich666dead)
 * -----
 * Modified By: the developer formerly known as Rinat(lich666dead) at <lich666black@gmail.com>
 * -----
 * Copyright (c) 2020 ZilPay
 */


export interface DApp {
  contract: string;
  title: string;
  description: string;
  url: string;
  images: string[];
  icon: string;
  category: string;
}

export interface Poster {
  block: string;
  url: string;
  banner: string;
}
