// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ZilPay Wallet';

  @override
  String get initialPagerestoreZilPay => 'Restore ZilPay 1.0!';

  @override
  String get initialPagegetStarted => 'Get Started';

  @override
  String get restoreRKStorageTitle => 'Migrate ZilPay 1.0 to 2.0';

  @override
  String get restoreRKStorageAccountsPrompt => 'Accounts to migrate to ZilPay 2.0. Enter password.';

  @override
  String get restoreRKStoragePasswordHint => 'Password';

  @override
  String get restoreRKStorageEnterPassword => 'Enter password';

  @override
  String get restoreRKStorageErrorPrefix => 'Error:';

  @override
  String get restoreRKStorageRestoreButton => 'Restore';

  @override
  String get restoreRKStorageSkipButton => 'Skip';

  @override
  String get accountItemBalanceLabel => 'Balance:';

  @override
  String get sendTokenPageTitle => '';

  @override
  String get sendTokenPageSubmitButton => 'Submit';

  @override
  String get aboutPageTitle => 'About';

  @override
  String get aboutPageAppName => 'ZilPay';

  @override
  String get aboutPageAppDescription => 'Your Secure Blockchain Wallet';

  @override
  String get aboutPageAppInfoTitle => 'Application Info';

  @override
  String get aboutPageVersionLabel => 'Version';

  @override
  String get aboutPageBuildDateLabel => 'Build Date';

  @override
  String get aboutPageBuildDateValue => 'March 10, 2025';

  @override
  String get aboutPagePlatformLabel => 'Platform';

  @override
  String get aboutPageDeveloperTitle => 'Developer';

  @override
  String get aboutPageAuthorLabel => 'Author';

  @override
  String get aboutPageAuthorValue => 'Rinat (hicaru)';

  @override
  String get aboutPageWebsiteLabel => 'Website';

  @override
  String get aboutPageWebsiteValue => 'https://zilpay.io';

  @override
  String get aboutPageLegalTitle => 'Legal';

  @override
  String get aboutPagePrivacyPolicy => 'Privacy Policy';

  @override
  String get aboutPageTermsOfService => 'Terms of Service';

  @override
  String get aboutPageLicenses => 'Licenses';

  @override
  String get aboutPageLegalese => '© 2025 ZilPay. All rights reserved.';

  @override
  String get languagePageTitle => 'Language';

  @override
  String get languagePageSystem => 'System';

  @override
  String get languagePageRussian => 'Russian';

  @override
  String get languagePageEnglish => 'English';

  @override
  String get languagePageTurkish => 'Turkish';

  @override
  String get languagePageChinese => 'Chinese';

  @override
  String get languagePageUzbek => 'Uzbek';

  @override
  String get languagePageIndonesian => 'Indonesian';

  @override
  String get languagePageUkrainian => 'Ukrainian';

  @override
  String get languagePageEnglishLocal => 'English';

  @override
  String get languagePageRussianLocal => 'Русский';

  @override
  String get languagePageTurkishLocal => 'Türkçe';

  @override
  String get languagePageChineseLocal => '简体中文';

  @override
  String get languagePageUzbekLocal => 'O\'zbekcha';

  @override
  String get languagePageIndonesianLocal => 'Bahasa Indonesia';

  @override
  String get languagePageUkrainianLocal => 'Українська';

  @override
  String get secretKeyGeneratorPageTitle => 'Secret Key';

  @override
  String get secretKeyGeneratorPagePrivateKey => 'Private Key';

  @override
  String get secretKeyGeneratorPagePublicKey => 'Public Key';

  @override
  String get secretKeyGeneratorPageBackupCheckbox => 'I have backup secret key';

  @override
  String get secretKeyGeneratorPageNextButton => 'Next';

  @override
  String get walletPageTitle => '';

  @override
  String get walletPageWalletNameHint => 'Wallet name';

  @override
  String get walletPagePreferencesTitle => 'Wallet preferences';

  @override
  String get walletPageManageConnections => 'Manage connections';

  @override
  String get walletPageBackup => 'Backup';

  @override
  String get walletPageDeleteWallet => 'Delete Wallet';

  @override
  String get walletPageBiometricReason => 'Enable biometric authentication';

  @override
  String get networkPageTitle => '';

  @override
  String get networkPageShowTestnet => 'Show Testnet';

  @override
  String get networkPageSearchHint => 'Search';

  @override
  String get networkPageAddedNetworks => 'Added Networks';

  @override
  String get networkPageAvailableNetworks => 'Available Networks';

  @override
  String get networkPageLoadError => 'Failed to load network chains: ';

  @override
  String get networkPageAddError => 'Failed to add network: ';

  @override
  String get receivePageTitle => 'Receive';

  @override
  String receivePageWarning(Object chainName, Object tokenSymbol) {
    return 'Only send $chainName($tokenSymbol) assets to this address. Other assets will be lost forever.';
  }

  @override
  String get receivePageAccountNameHint => 'Account name';

  @override
  String get receivePageAmountDialogTitle => 'Enter Amount';

  @override
  String get receivePageAmountDialogHint => '0.0';

  @override
  String get receivePageAmountDialogCancel => 'Cancel';

  @override
  String get receivePageAmountDialogConfirm => 'Confirm';

  @override
  String get securityPageTitle => 'Security';

  @override
  String get securityPageNetworkPrivacy => 'Network Privacy';

  @override
  String get securityPageEnsDomains => 'Show ENS domains in address bar';

  @override
  String get securityPageEnsDescription => 'Keep in mind that using this feature exposes your IP address to IPFS third-party services.';

  @override
  String get securityPageIpfsGateway => 'IPFS gateway';

  @override
  String get securityPageIpfsDescription => 'ZIlPay uses third-party services to show images of your NFTs stored on IPFS, display information related to ENS(ZNS) addresses entered in your browser\'s address bar, and fetch icons for different tokens. Your IP address may be exposed to these services when you\'re using them.';

  @override
  String get securityPageGasStation => 'Gas station';

  @override
  String get securityPageGasDescription => 'Use ZilPay server for optimize your gas usage';

  @override
  String get securityPageNodeRanking => 'Node ranking';

  @override
  String get securityPageNodeDescription => 'Make requests to ZilPay server for fetch best node';

  @override
  String get securityPageEncryptionLevel => 'Encryption Level';

  @override
  String get securityPageProtection => 'Protection';

  @override
  String get securityPageCpuLoad => 'CPU Load';

  @override
  String get securityPageAes256 => 'AES256';

  @override
  String get securityPageKuznechikGost => 'KUZNECHIK-GOST';

  @override
  String get securityPageNtruPrime => 'NTRUPrime';

  @override
  String get securityPageCyber => 'Cyber';

  @override
  String get securityPageUnknown => 'Unknown';

  @override
  String get webViewPageDntLabel => 'DNT';

  @override
  String get webViewPageIncognitoLabel => 'Incognito';

  @override
  String get webViewPageLoadError => 'Failed to load';

  @override
  String get webViewPageTryAgain => 'Try Again';

  @override
  String get addTokenPageTitle => 'Add Token';

  @override
  String get addTokenPageTokenInfo => 'Token Information';

  @override
  String get addTokenPageHint => 'Address, name, symbol';

  @override
  String get addTokenPageAddError => 'Failed to add token:';

  @override
  String get addTokenPageInvalidAddressError => 'Invalid token address or network error';

  @override
  String get secretPhraseGeneratorPageTitle => 'New Wallet';

  @override
  String get secretPhraseGeneratorPageBackupCheckbox => 'I have backup words';

  @override
  String get secretPhraseGeneratorPageNextButton => 'Next';

  @override
  String get homePageTestnetLabel => 'Testnet';

  @override
  String get revealSecretKeyTitle => 'Reveal Secret Key';

  @override
  String get revealSecretKeyPasswordHint => 'Password';

  @override
  String get revealSecretKeyInvalidPassword => 'invalid password, error:';

  @override
  String get revealSecretKeySubmitButton => 'Submit';

  @override
  String get revealSecretKeyDoneButton => 'Done';

  @override
  String get revealSecretKeyScamAlertTitle => 'SCAM ALERT';

  @override
  String get revealSecretKeyScamAlertMessage => 'Never share your secret key with anyone. Never input it on any website.';

  @override
  String get setupNetworkSettingsPageTestnetSwitch => 'Testnet';

  @override
  String get setupNetworkSettingsPageSearchHint => 'Search';

  @override
  String get setupNetworkSettingsPageLoadError => 'Failed to load network chains:';

  @override
  String get setupNetworkSettingsPageNoNetworks => 'No networks available';

  @override
  String setupNetworkSettingsPageNoResults(Object searchQuery) {
    return 'No networks found for \"$searchQuery\"';
  }

  @override
  String get setupNetworkSettingsPageNextButton => 'Next';

  @override
  String get setupNetworkSettingsPageTestnetLabel => 'Testnet';

  @override
  String get setupNetworkSettingsPageMainnetLabel => 'Mainnet';

  @override
  String get setupNetworkSettingsPageChainIdLabel => 'Chain ID:';

  @override
  String get setupNetworkSettingsPageTokenLabel => 'Token:';

  @override
  String get setupNetworkSettingsPageExplorerLabel => 'Explorer:';

  @override
  String get appearanceSettingsPageTitle => 'Appearance Settings';

  @override
  String get appearanceSettingsPageCompactNumbersTitle => 'Compact Numbers';

  @override
  String get appearanceSettingsPageCompactNumbersDescription => 'Enable to display abbreviated numbers (e.g., 20K instead of 20,000).';

  @override
  String get appearanceSettingsPageDeviceSettingsTitle => 'Device settings';

  @override
  String get appearanceSettingsPageDeviceSettingsSubtitle => 'System default';

  @override
  String get appearanceSettingsPageDeviceSettingsDescription => 'Default to your device\'s appearance. Your wallet theme will automatically adjust based on your system settings.';

  @override
  String get appearanceSettingsPageDarkModeTitle => 'Dark Mode';

  @override
  String get appearanceSettingsPageDarkModeSubtitle => 'Always dark';

  @override
  String get appearanceSettingsPageDarkModeDescription => 'Keep the dark theme enabled at all times, regardless of your device settings.';

  @override
  String get appearanceSettingsPageLightModeTitle => 'Light mode';

  @override
  String get appearanceSettingsPageLightModeSubtitle => 'Always light';

  @override
  String get appearanceSettingsPageLightModeDescription => 'Keep the light theme enabled at all times, regardless of your device settings.';

  @override
  String get loginPageBiometricReason => 'Please authenticate';

  @override
  String loginPageWalletTitle(Object index) {
    return 'Wallet $index';
  }

  @override
  String get loginPagePasswordHint => 'Password';

  @override
  String get loginPageUnlockButton => 'Unlock';

  @override
  String get loginPageWelcomeBack => 'Welcome back';

  @override
  String get secretKeyRestorePageTitle => 'Restore Secret Key';

  @override
  String get secretKeyRestorePageHint => 'Private Key';

  @override
  String get secretKeyRestorePageInvalidFormat => 'Invalid private key format';

  @override
  String get secretKeyRestorePageKeyTitle => 'Private Key';

  @override
  String get secretKeyRestorePageBackupLabel => 'I have backed up my secret key';

  @override
  String get secretKeyRestorePageNextButton => 'Next';

  @override
  String get addAccountPageTitle => 'Add New Account';

  @override
  String get addAccountPageSubtitle => 'Create BIP39 Account';

  @override
  String addAccountPageDefaultName(Object index) {
    return 'Account $index';
  }

  @override
  String get addAccountPageNameHint => 'Account name';

  @override
  String get addAccountPageBip39Index => 'BIP39 Index';

  @override
  String get addAccountPageUseBiometrics => 'Use Biometrics';

  @override
  String get addAccountPagePasswordHint => 'Password';

  @override
  String get addAccountPageZilliqaLegacy => 'Zilliqa Legacy';

  @override
  String get addAccountPageBiometricReason => 'Authenticate to create a new account';

  @override
  String addAccountPageBiometricError(Object error) {
    return 'Biometric authentication failed: $error';
  }

  @override
  String addAccountPageIndexExists(Object index) {
    return 'Account with index $index already exists';
  }

  @override
  String get addAccountPageBiometricFailed => 'Biometric authentication failed';

  @override
  String addAccountPageCreateFailed(Object error) {
    return 'Failed to create account: $error';
  }

  @override
  String get addressBookPageTitle => 'Address Book';

  @override
  String get addressBookPageEmptyMessage => 'Your contacts and their wallet address will\nappear here.';

  @override
  String addressBookPageNetwork(Object network) {
    return 'Network $network';
  }

  @override
  String get browserPageConnectedTab => 'Connected';

  @override
  String get browserPageExploreTab => 'Explore';

  @override
  String get browserPageNoExploreApps => 'No apps to explore yet';

  @override
  String browserPageSearchHint(Object engine) {
    return 'Search with $engine or enter address';
  }

  @override
  String get browserPageNoConnectedApps => 'No connected apps';

  @override
  String get historyPageTitle => 'Transaction History';

  @override
  String get historyPageNoTransactions => 'No transactions yet';

  @override
  String get historyPageSearchHint => 'Search transactions...';

  @override
  String get notificationsSettingsPageTitle => 'Notifications';

  @override
  String get notificationsSettingsPagePushTitle => 'Push notifications';

  @override
  String get notificationsSettingsPagePushDescription => 'Get notifications when tx sent and confirm, Notifications from connected apps.';

  @override
  String get notificationsSettingsPageWalletsTitle => 'Wallets';

  @override
  String get notificationsSettingsPageWalletsDescription => 'Notifications from wallets';

  @override
  String get notificationsSettingsPageWalletPrefix => 'Wallet';

  @override
  String get revealSecretPhraseTitle => 'Reveal Secret Phrase';

  @override
  String get revealSecretPhrasePasswordHint => 'Password';

  @override
  String get revealSecretPhraseInvalidPassword => 'invalid password, error:';

  @override
  String get revealSecretPhraseSubmitButton => 'Submit';

  @override
  String get revealSecretPhraseDoneButton => 'Done';

  @override
  String get revealSecretPhraseScamAlertTitle => 'SCAM ALERT';

  @override
  String get revealSecretPhraseScamAlertDescription => 'Never share your secret phrase with anyone. Never input it on any website.';
}
