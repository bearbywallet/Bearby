# ZilPay mobile wallet.

ZilPay wallet the decentralized browser and wallet in one. Via ZilPay you and developers can create decentralized applications on ZIlliqa blockchain.

<p align="center">
  <a href="https://zilpay.io"><img src="https://github.com/zilpay/zilpay-mobile/blob/master/imgs/preview.png"></a>
</p>

For developers:
+ [ZilPay full documentation](https://zilpay.github.io/zilpay-docs/)
+ [ZilPay try build your dApp](https://medium.com/coinmonks/test-and-develop-dapps-on-zilliqa-with-zilpay-52b165f118bf?source=friends_link&sk=2a60070ddac60677ec36b1234c60222a)
+ [Zilliqa dApps example](https://github.com/lich666dead/zilliqa-dApps)

## Authors

* **Rinat Khasanshin** - *Initial work* - [hicaru](https://github.com/hicaru)

## Built With

* [react-native](https://reactnative.dev/)
* [babel](https://github.com/babel/babel)
* [TypeScript](https://www.typescriptlang.org/)

## Getting Started
Build deploy the local version, from source code.

Clone:
```bash
$ git clone https://github.com/zilpay/zilpay-mobile.git
$ cd zilpay-mobile
```

Install dependencies:
```bash
$ yarn
```

Run IOS:
```bash
$ yarn ios
```

Run real device:
```bash
$ yarn ios --device
$ yarn android --device
```

building release.
```bash
$ yarn ios --variant=release
$ yarn android --variant=release
```

build bungle
```bash
node node_modules/react-native/local-cli/cli.js bundle --entry-file='./index.js' --bundle-output='./ios/main.jsbundle' --dev=false --platform='ios' --assets-dest='./ios'
```

Android build singed package
```bash
 $ ./gradlew bundleRelease
```

Thanks for yours donations.
------

- ZIL: zil1wl38cwww2u3g8wzgutxlxtxwwc0rf7jf27zace
- ETH: 0x246C5881E3F109B2aF170F5C773EF969d3da581B
- BTC: 12MRR8LyLVLHVqXcjz46c9o3KBS76fAY9r
- ZEC: t1dZMw8FVWnGKC9cyXKaiKWmmAFmQoeNc5Y
- LTC: LM3JwjTbboMkHdFEYnn4ycJB61r3fqvXPr
- DASH: Xv2tpCMHPAztd4B5UMnaqwkqnSfiUs1P8B
