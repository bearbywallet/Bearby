# ZilPay mobile wallet.

### run:

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

## Roadmap check list:

### Cross platforms:
- [x] IOS.
- [ ] android.

### Authentication:
- [x] Password authentication.
- [x] Biometric authentication.
- [x] Encryptor session.

### Web3
- [x] WebView.
- [x] Create JS injector.
- [x] meesage beetween app and inject script.

### DWeb
- [x] unstoppabledomains controller.
	- [x] Contract parser.
	- [x] get Contract State.
- [x] patterns nad parsing URL.

### Tokens
- [x] Send tokens.
- [x] Image token parser.
- [x] Add token card.
- [x] add token form.
- [x] add token modal.
- [x] Token ZRC parser.
	- [ ] parser ZRC-1.
	- [x] parser ZRC-2.
	- [ ] parser ZRC-3.

### Controller Core librarys:
- [x] i18n.
- [x] storage.
- [x] crypto.
- [x] account.
- [x] auth.
- [x] contacts.
- [x] currency.
- [x] gas.
- [x] guard.
- [x] mnemonic.
- [x] network.
- [x] settings.
- [x] theme.
- [x] tokens.
- [x] wallet.
- [x] zilliqa.
- [x] nonce counter.

### Pages:
- [x] Settings.
	- [x] about.
	- [x] advanced.
	- [x] connections.
	- [x] contacts.
	- [x] export.
	- [x] general.
	- [x] security.
	- [x] network.
- [x] unauthorized
	- [x] LetStartPage.
	- [x] GetStartedPage.
	- [x] LockPage.
	- [x] RestorePage.
	- [x] PrivacyPage.
	- [x] MnemonicGenPage.
	- [x] MnemonicVerifyPage.
	- [x] SetupPasswordPage.
	- [x] InitSuccessfullyPage.
- [x] Tabs.
	- [x] HomePage.
	- [x] BrowserPage.
	- [x] SettingsPage.
	- [x] HistoryPage.
- [x] Common.
	- [x] CreateAccountPage.
	- [x] TransferPage.
	- [x] ConnectDApp.
	- [x] SignMessage.
	- [x] confirmTransaction.
	- [x] AuthLoading.

