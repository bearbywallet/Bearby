# ZilPay Mobile Wallet

ZilPay is a quantum-resistant, multi-currency decentralized wallet. Create and interact with decentralized applications across multiple blockchains with industry-leading security powered by advanced cryptographic primitives.

<p align="center">
  <a href="https://zilpay.io"><img src="https://github.com/zilpay/zilpay-mobile/blob/master/imgs/preview.png"></a>
</p>

## Features

- **Multi-Currency Support**: Manage multiple cryptocurrencies in one secure wallet
- **Quantum-Resistant Security**: Implemented with post-quantum cryptographic algorithms
- **Native Performance**: Core functionality written in Rust for optimal speed and security
- **Modern UI/UX**: Built with Flutter for a smooth, responsive experience across platforms
- **Decentralized App Browser**: Interact with dApps directly through the wallet interface
- **Open Source**: Fully transparent codebase

## Cryptographic Foundations

ZilPay employs a comprehensive set of cryptographic primitives to ensure maximum security:

- **NTRU Prime**: Post-quantum cryptography for future-proof security
- **Cyber**: Advanced cryptographic library for blockchain operations
- **AES**: Industry-standard symmetric encryption
- **Kuznechik**: GOST R 34.12-2015 encryption algorithm
- **Argon2**: Secure key derivation and password hashing

## Technology Stack

- **Frontend**: Flutter/Dart
- **Core Logic**: Rust
- **Blockchain Integration**: Native rust implementations

## For Developers

- [ZilPay full documentation](https://zilpay.github.io/zilpay-docs/)
- [Guide: Build your dApp with ZilPay](https://medium.com/coinmonks/test-and-develop-dapps-on-zilliqa-with-zilpay-52b165f118bf?source=friends_link&sk=2a60070ddac60677ec36b1234c60222a)
- [Zilliqa dApps examples](https://github.com/lich666dead/zilliqa-dApps)

## Getting Started

Clone the repository:
```bash
$ git clone https://github.com/zilpay/zilpay-mobile.git
$ cd zilpay-mobile
```

### Prerequisites
- Flutter SDK
- Rust toolchain
- Android SDK or Xcode (for iOS)

### Install Dependencies

```bash
$ flutter pub get
$ cargo build
```

### Run Development Build

```bash
# Run on iOS simulator
$ flutter run -d ios

# Run on Android emulator
$ flutter run -d android

# Run on connected device
$ flutter run -d device
```

### Build Release Version

```bash
# iOS
$ flutter build ios --release

# Android
$ flutter build appbundle
```

## Author

* **Rinat** - *Initial work* - [hicaru](https://github.com/hicaru)
