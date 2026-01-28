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
  String get networkPageSearchHint => 'Search';

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
  String get securityPageTokensFetcherTitle => 'Tokens fetcher';

  @override
  String get securityPageTokensFetcherDescription => 'tokens fetcher setting on SecurityPage. If enabled, tokens will be automatically fetched from the server and can be added.';

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
  String get secretPhraseGeneratorPageTitle => 'New Wallet';

  @override
  String get secretPhraseGeneratorPageBackupCheckbox => 'I have backup words';

  @override
  String get secretPhraseGeneratorPageNextButton => 'Next';

  @override
  String get homePageErrorTitle => 'No signal';

  @override
  String get homePageReceiveButton => 'Receive';

  @override
  String get homePageSendButton => 'Send';

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
  String get revealSecretKeySecurityTimer => 'Security Timer';

  @override
  String get revealSecretKeyRevealAfter => 'Your secret key will be revealed after:';

  @override
  String get setupNetworkSettingsPageSearchHint => 'Search';

  @override
  String get setupNetworkSettingsPageNoNetworks => 'No networks available';

  @override
  String setupNetworkSettingsPageNoResults(Object searchQuery) {
    return 'No networks found for \"$searchQuery\"';
  }

  @override
  String get setupNetworkSettingsPageNextButton => 'Next';

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
  String get addressBookPageDeleteConfirmationTitle => 'Delete Contact';

  @override
  String addressBookPageDeleteConfirmationMessage(String contactName) {
    return 'Are you sure you want to delete $contactName from your address book?';
  }

  @override
  String addressBookPageDeleteTooltip(String contactName) {
    return 'Delete $contactName';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

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
  String get revealSecretPhraseRevealAfter => 'Your seed phrase will be revealed after:';

  @override
  String get revealSecretPhraseSubmitButton => 'Submit';

  @override
  String get revealSecretPhraseDoneButton => 'Done';

  @override
  String get revealSecretPhraseScamAlertTitle => 'SCAM ALERT';

  @override
  String get revealSecretPhraseScamAlertDescription => 'Never share your secret phrase with anyone. Never input it on any website.';

  @override
  String get cipherSettingsPageTitle => 'Encryption Setup';

  @override
  String get cipherSettingsPageAdvancedButton => 'Advanced';

  @override
  String get cipherSettingsPageStandardTitle => 'Standard Encryption';

  @override
  String get cipherSettingsPageStandardSubtitle => 'AES-256 + KUZNECHIK-GOST';

  @override
  String get cipherSettingsPageStandardDescription => 'Basic encryption with AES-256 and GOST standard KUZNECHIK.';

  @override
  String get cipherSettingsPageHybridTitle => 'Hybrid Encryption';

  @override
  String get cipherSettingsPageHybridSubtitle => 'CYBER + KUZNECHIK-GOST';

  @override
  String get cipherSettingsPageHybridDescription => 'Hybrid encryption combining CYBER and KUZNECHIK-GOST algorithms.';

  @override
  String get cipherSettingsPageQuantumTitle => 'Quantum-Resistant';

  @override
  String get cipherSettingsPageQuantumSubtitle => 'CYBER + KUZNECHIK + NTRUP1277';

  @override
  String get cipherSettingsPageQuantumDescription => 'Advanced quantum-resistant encryption with NTRUP1277.';

  @override
  String get cipherSettingsPageQuantumWarning => 'Quantum-resistant encryption may impact performance';

  @override
  String get cipherSettingsPageConfirmButton => 'Confirm';

  @override
  String get secretPhraseVerifyPageTitle => 'Verify Secret';

  @override
  String get secretPhraseVerifyPageSubtitle => 'Verify Bip39 Secret';

  @override
  String get secretPhraseVerifyPageNextButton => 'Next';

  @override
  String get restoreSecretPhrasePageTitle => 'Restore Wallet';

  @override
  String get restoreSecretPhrasePageRestoreButton => 'Restore';

  @override
  String get checksumValidationFailed => 'Checksum validation failed';

  @override
  String get proceedDespiteInvalidChecksum => 'Continue despite checksum error?';

  @override
  String get settingsPageTitle => 'Settings';

  @override
  String get settingsPageZilliqaLegacy => 'Zilliqa Legacy';

  @override
  String get settingsPageCurrency => 'Currency';

  @override
  String get settingsPageAppearance => 'Appearance';

  @override
  String get settingsPageNotifications => 'Notifications';

  @override
  String get settingsPageAddressBook => 'Address book';

  @override
  String get settingsPageSecurityPrivacy => 'Security & privacy';

  @override
  String get settingsPageNetworks => 'Networks';

  @override
  String get settingsPageLanguage => 'Language';

  @override
  String get settingsPageBrowser => 'Browser';

  @override
  String get settingsPageTelegram => 'Telegram';

  @override
  String get settingsPageTwitter => 'Twitter';

  @override
  String get settingsPageGitHub => 'GitHub';

  @override
  String get settingsPageAbout => 'About';

  @override
  String get passwordSetupPageTitle => 'Password Setup';

  @override
  String get passwordSetupPageSubtitle => 'Create Password';

  @override
  String get passwordSetupPageWalletNameHint => 'Wallet Name';

  @override
  String get passwordSetupPagePasswordHint => 'Password';

  @override
  String get passwordSetupPageConfirmPasswordHint => 'Confirm Password';

  @override
  String get passwordSetupPageEmptyWalletNameError => 'Wallet name cannot be empty';

  @override
  String get passwordSetupPageLongWalletNameError => 'Wallet name is too long';

  @override
  String get passwordSetupPageShortPasswordError => 'Password must be at least 8 characters';

  @override
  String get passwordSetupPageMismatchPasswordError => 'Passwords do not match';

  @override
  String get passwordSetupPageLegacyLabel => 'Legacy';

  @override
  String get passwordSetupPageCreateButton => 'Create Password';

  @override
  String get passwordSetupPageAuthReason => 'Please authenticate to enable quick access';

  @override
  String get passwordSetupPageSeedType => 'Seed';

  @override
  String get passwordSetupPageKeyType => 'Key';

  @override
  String get passwordSetupPageUniversalNetwork => 'Universal';

  @override
  String get browserSettingsTitle => 'Browser Settings';

  @override
  String get browserSettingsBrowserOptions => 'Browser Options';

  @override
  String get browserSettingsSearchEngine => 'Search Engine';

  @override
  String get browserSettingsSearchEngineDescription => 'Configure your default search engine';

  @override
  String get browserSettingsSearchEngineTitle => 'Search Engine';

  @override
  String get browserSettingsContentBlocking => 'Content Blocking';

  @override
  String get browserSettingsContentBlockingDescription => 'Configure content blocking settings';

  @override
  String get browserSettingsContentBlockingTitle => 'Content Blocking';

  @override
  String get browserSettingsPrivacySecurity => 'Privacy & Security';

  @override
  String get browserSettingsCookies => 'Cookies';

  @override
  String get browserSettingsCookiesDescription => 'Allow websites to save and read cookies';

  @override
  String get browserSettingsDoNotTrack => 'Do Not Track';

  @override
  String get browserSettingsDoNotTrackDescription => 'Request websites not to track your browsing';

  @override
  String get browserSettingsIncognitoMode => 'Incognito Mode';

  @override
  String get browserSettingsIncognitoModeDescription => 'Browse without saving history or cookies';

  @override
  String get browserSettingsPerformance => 'Performance';

  @override
  String get browserSettingsCache => 'Cache';

  @override
  String get browserSettingsClearData => 'Clear Data';

  @override
  String get browserSettingsClear => 'Clear';

  @override
  String get browserSettingsClearCookies => 'Clear Cookies';

  @override
  String get browserSettingsClearCookiesDescription => 'Delete all cookies stored by websites';

  @override
  String get browserSettingsClearCache => 'Clear Cache';

  @override
  String get browserSettingsClearCacheDescription => 'Delete temporary files and images stored during browsing';

  @override
  String get browserSettingsClearLocalStorage => 'Clear Local Storage';

  @override
  String get browserSettingsClearLocalStorageDescription => 'Delete website data stored locally on your device';

  @override
  String get browserSettingsCacheDescription => 'Store website data for faster loading';

  @override
  String get genWalletOptionsTitle => 'Generate Wallet';

  @override
  String get genWalletOptionsBIP39Title => 'BIP39';

  @override
  String get genWalletOptionsBIP39Subtitle => 'Generate Mnemonic phrase';

  @override
  String get genWalletOptionsPrivateKeyTitle => 'Private Key';

  @override
  String get genWalletOptionsPrivateKeySubtitle => 'Generate just one private key';

  @override
  String get addWalletOptionsTitle => 'Add Wallet';

  @override
  String get addWalletOptionsNewWalletTitle => 'New Wallet';

  @override
  String get addWalletOptionsNewWalletSubtitle => 'Create new wallet';

  @override
  String get addWalletOptionsExistingWalletTitle => 'Existing Wallet';

  @override
  String get addWalletOptionsExistingWalletSubtitle => 'Import wallet with a 24 secret recovery words';

  @override
  String get addWalletOptionsPairWithLedgerTitle => 'Pair with Ledger';

  @override
  String get addWalletOptionsPairWithLedgerSubtitle => 'Hardware module, Bluetooth';

  @override
  String get addWalletOptionsOtherOptions => 'Other options';

  @override
  String get addWalletOptionsWatchAccountTitle => 'Watch Account';

  @override
  String get addWalletOptionsWatchAccountSubtitle => 'For monitor wallet activity without recovery phrase';

  @override
  String get currencyConversionTitle => 'Primary Currency';

  @override
  String get currencyConversionSearchHint => 'Search currencies...';

  @override
  String get currencyConversionEngineTitle => 'Currency Engine';

  @override
  String get currencyConversionEngineDescription => 'Engine for fetching currency rates';

  @override
  String get currencyConversionEngineSelectorTitle => 'Select Currency Engine';

  @override
  String get currencyConversionEngineNone => 'None';

  @override
  String get currencyConversionEngineNoneSubtitle => 'No engine selected';

  @override
  String get currencyConversionEngineCoingecko => 'Coingecko';

  @override
  String get currencyConversionEngineCoingeckoSubtitle => 'Fetch rates from Coingecko';

  @override
  String get currencyConversionEngineCryptoCompare => 'CryptoCompare';

  @override
  String get currencyConversionEngineCryptoCompareSubtitle => 'Fetch rates from CryptoCompare';

  @override
  String get restoreWalletOptionsTitle => 'Restore Wallet';

  @override
  String get restoreWalletOptionsBIP39Title => 'BIP39';

  @override
  String get restoreWalletOptionsBIP39Subtitle => 'Restore with Mnemonic phrase';

  @override
  String get restoreWalletOptionsPrivateKeyTitle => 'Private Key';

  @override
  String get restoreWalletOptionsPrivateKeySubtitle => 'Restore with private key';

  @override
  String get restoreWalletOptionsKeyStoreTitle => 'Keystore File';

  @override
  String get restoreWalletOptionsKeyStoreSubtitle => 'Restore wallet using password-encrypted backup file';

  @override
  String get restoreWalletOptionsQRCodeTitle => 'QRcode';

  @override
  String get restoreWalletOptionsQRCodeSubtitle => 'Restore wallet by QRcode scanning';

  @override
  String get argonSettingsModalContentLowMemoryTitle => 'Low Memory';

  @override
  String get argonSettingsModalContentLowMemorySubtitle => '64KB RAM, 3 iterations';

  @override
  String get argonSettingsModalContentLowMemoryDescription => 'Minimal memory usage, suitable for low-end devices.';

  @override
  String get argonSettingsModalContentOwaspTitle => 'OWASP Default';

  @override
  String get argonSettingsModalContentOwaspSubtitle => '6.5MB RAM, 2 iterations';

  @override
  String get argonSettingsModalContentOwaspDescription => 'Recommended by OWASP for general use.';

  @override
  String get argonSettingsModalContentSecureTitle => 'Secure';

  @override
  String get argonSettingsModalContentSecureSubtitle => '256MB RAM, 4 iterations';

  @override
  String get argonSettingsModalContentSecureDescription => 'High security with increased memory and iterations.';

  @override
  String get argonSettingsModalContentSecretHint => 'Enter secret (optional)';

  @override
  String get argonSettingsModalContentConfirmButton => 'Confirm';

  @override
  String get confirmTransactionContentPasswordHint => 'Password';

  @override
  String get confirmTransactionContentUnableToConfirm => 'Unable to confirm';

  @override
  String get confirmTransactionContentConfirm => 'Confirm';

  @override
  String get confirmTransactionContentNoActiveAccount => 'No active account';

  @override
  String get confirmTransactionContentFailedLoadTransfer => 'Failed to load transfer details';

  @override
  String get confirmTransactionEditGasButtonText => 'Edit gas';

  @override
  String get authReason => 'Please authenticate';

  @override
  String get addChainModalContentWarning => 'Beware of network scams and security risks.';

  @override
  String get addChainModalContentApprove => 'Approve';

  @override
  String get addChainModalContentDetails => 'Details';

  @override
  String get addChainModalContentNetworkName => 'Network Name:';

  @override
  String get addChainModalContentCurrencySymbol => 'Currency Symbol:';

  @override
  String get addChainModalContentChainId => 'Chain ID:';

  @override
  String get addChainModalContentBlockExplorer => 'Block Explorer:';

  @override
  String get addAddressModalTitle => 'Add Contact';

  @override
  String get addAddressModalDescription => 'Enter the contact name and wallet address to add to your address book.';

  @override
  String get addAddressModalNameHint => 'Name';

  @override
  String get addAddressModalAddressHint => 'Wallet Address';

  @override
  String get addAddressModalNameEmptyError => 'Name cannot be empty';

  @override
  String get addAddressModalAddressEmptyError => 'Address cannot be empty';

  @override
  String get addAddressModalButton => 'Add Contact';

  @override
  String get tokenSelectModalContentSearchHint => 'Search';

  @override
  String get signMessageModalContentAuthReason => 'Please authenticate to sign the message';

  @override
  String signMessageModalContentFailedToSign(Object error) {
    return 'Failed to sign: $error';
  }

  @override
  String get signMessageModalContentTitle => 'Sign Message';

  @override
  String get signMessageModalContentDescription => 'Review and sign the following message with your wallet.';

  @override
  String get signMessageModalContentDomain => 'Domain:';

  @override
  String get signMessageModalContentChainId => 'Chain ID:';

  @override
  String get signMessageModalContentContract => 'Contract:';

  @override
  String get signMessageModalContentType => 'Type:';

  @override
  String get signMessageModalContentNoData => 'No data';

  @override
  String get signMessageModalContentPasswordHint => 'Password';

  @override
  String get signMessageModalContentProcessing => 'Processing...';

  @override
  String get signMessageModalContentSign => 'Sign Message';

  @override
  String get deleteWalletModalTitle => 'Delete Wallet';

  @override
  String get deleteWalletModalWarning => 'Warning: This action cannot be undone. Your wallet can only be recovered using your secret phrase. If you don\'t have access to it, you will permanently lose all funds associated with this account.';

  @override
  String get deleteWalletModalSecretPhraseWarning => 'Please make sure you have access to your secret phrase before proceeding.';

  @override
  String get deleteWalletModalPasswordHint => 'Enter Password';

  @override
  String get deleteWalletModalSubmit => 'Destroy';

  @override
  String get addressSelectModalContentTitle => 'Select Address';

  @override
  String get addressSelectModalContentSearchHint => 'Search / Address / ENS';

  @override
  String get addressSelectModalContentUnknown => 'Unknown';

  @override
  String get addressSelectModalContentMyAccounts => 'My Accounts';

  @override
  String get addressSelectModalContentAddressBook => 'Address Book';

  @override
  String get addressSelectModalContentHistory => 'History';

  @override
  String get addressSelectModalContentSender => 'Sender';

  @override
  String get changePasswordModalTitle => 'Change Password';

  @override
  String get changePasswordModalDescription => 'Enter your current password and choose a new password to update your wallet security.';

  @override
  String get changePasswordModalCurrentPasswordHint => 'Current Password';

  @override
  String get changePasswordModalNewPasswordHint => 'New Password';

  @override
  String get changePasswordModalConfirmPasswordHint => 'Confirm New Password';

  @override
  String get changePasswordModalCurrentPasswordEmptyError => 'Current password cannot be empty';

  @override
  String get changePasswordModalPasswordLengthError => 'Password must be at least 6 characters';

  @override
  String get changePasswordModalPasswordsMismatchError => 'Passwords do not match';

  @override
  String get changePasswordModalButton => 'Change Password';

  @override
  String get confirmPasswordModalTitle => 'Confirm Password';

  @override
  String get confirmPasswordModalDescription => 'Enter your password to continue.';

  @override
  String get confirmPasswordModalHint => 'Password';

  @override
  String get confirmPasswordModalEmptyError => 'Password cannot be empty';

  @override
  String get confirmPasswordModalGenericError => 'Error:';

  @override
  String get confirmPasswordModalButton => 'Confirm';

  @override
  String get qrScannerModalContentTitle => 'Scan';

  @override
  String get qrScannerModalContentCameraInitError => 'Camera initialization error:';

  @override
  String get chainInfoModalContentTokenTitle => 'Network Token';

  @override
  String get chainInfoModalContentNetworkInfoTitle => 'Network Information';

  @override
  String get chainInfoModalContentChainLabel => 'Chain';

  @override
  String get chainInfoModalContentShortNameLabel => 'Short Name';

  @override
  String get chainInfoModalContentChainIdLabel => 'Chain ID';

  @override
  String get chainInfoModalContentSlip44Label => 'Slip44';

  @override
  String get chainInfoModalContentChainIdsLabel => 'Chain IDs';

  @override
  String get chainInfoModalContentTestnetLabel => 'Testnet';

  @override
  String get chainInfoModalContentYes => 'Yes';

  @override
  String get chainInfoModalContentNo => 'No';

  @override
  String get chainInfoModalContentDiffBlockTimeLabel => 'Diff Block Time';

  @override
  String get chainInfoModalContentFallbackEnabledLabel => 'Fallback Enabled';

  @override
  String get chainInfoModalContentDecimalsLabel => 'Decimals';

  @override
  String get chainInfoModalContentRpcNodesTitle => 'RPC Nodes';

  @override
  String get chainInfoModalContentExplorersTitle => 'Explorers';

  @override
  String get chainInfoModalContentDeleteProviderTitle => 'Delete Network';

  @override
  String get chainInfoModalContentSwipeToDelete => 'Delete network';

  @override
  String get switchChainNetworkContentTitle => 'Select Network';

  @override
  String get switchChainNetworkContentButton => 'Switch Network';

  @override
  String get switchChainNetworkContentTestnetLabel => 'Testnet';

  @override
  String get switchChainNetworkContentIdLabel => 'ID:';

  @override
  String get watchAssetModalContentTitle => 'Add suggested token';

  @override
  String get watchAssetModalContentDescription => 'Review and add the following token suggested by the app.';

  @override
  String get watchAssetModalContentTokenLabel => 'Token';

  @override
  String get watchAssetModalContentBalanceLabel => 'Balance';

  @override
  String get watchAssetModalContentLoadingButton => 'Balance...';

  @override
  String get watchAssetModalContentAddButton => 'Add';

  @override
  String get connectedDappsModalSearchHint => 'Search DApps';

  @override
  String get connectedDappsModalNoDapps => 'No connected DApps';

  @override
  String dappListItemConnected(Object time) {
    return 'Connected $time';
  }

  @override
  String get dappListItemJustNow => 'just now';

  @override
  String get secretRecoveryModalRevealPhraseTitle => 'Reveal Secret Recovery Phrase';

  @override
  String get secretRecoveryModalRevealPhraseDescription => 'If you ever change browsers or move computers, you will need this Secret Recovery Phrase to access your accounts. Save them somewhere safe and secret.';

  @override
  String get secretRecoveryModalRevealPhraseButton => 'Reveal';

  @override
  String get secretRecoveryModalShowKeysTitle => 'Show Private Keys';

  @override
  String get secretRecoveryModalShowKeysDescription => 'Warning: Never disclose this key. Anyone with your private keys can steal any assets held in your account.';

  @override
  String get secretRecoveryModalShowKeysButton => 'Export';

  @override
  String get secretRecoveryModalKeystoreBackupTitle => 'Keystore Backup';

  @override
  String get secretRecoveryModalKeystoreBackupDescription => 'Save your private keys in a password-protected encrypted keystore file. This provides an additional layer of security for your wallet.';

  @override
  String get secretRecoveryModalKeystoreBackupButton => 'Create Keystore Backup';

  @override
  String get backupConfirmationContentTitle => 'Backup Confirmation';

  @override
  String get backupConfirmationWarning => 'WARNING: If you lose or forget your seed phrase in the exact order, you will lose your funds permanently. Never share your seed phrase with anyone or they may steal your funds. BIP39 recovery is strict - any mistake in the words during recovery will result in loss of funds.';

  @override
  String get backupConfirmationContentWrittenDown => 'I have written down all';

  @override
  String get backupConfirmationContentSafelyStored => 'I have safely stored the backup';

  @override
  String get backupConfirmationContentWontLose => 'I am sure I won\'t lose the backup';

  @override
  String get backupConfirmationContentNotShare => 'I understand not to share these words with anyone';

  @override
  String get counterMaxValueError => 'Maximum value reached';

  @override
  String get counterMinValueError => 'Minimum value reached';

  @override
  String get biometricSwitchTouchId => 'Enable Touch ID';

  @override
  String get biometricSwitchFaceId => 'Enable Face ID';

  @override
  String get biometricSwitchOpticId => 'Enable Optic ID';

  @override
  String get biometricSwitchFingerprint => 'Enable Fingerprint';

  @override
  String get biometricSwitchBiometric => 'Enable Biometric Login';

  @override
  String get biometricSwitchPinCode => 'Enable Device PIN';

  @override
  String get gasFeeOptionLow => 'Low';

  @override
  String get gasFeeOptionMarket => 'Market';

  @override
  String get gasFeeOptionAggressive => 'Aggressive';

  @override
  String get gasDetailsEstimatedGas => 'Estimated Gas:';

  @override
  String get gasDetailsGasPrice => 'Gas Price:';

  @override
  String get gasDetailsBaseFee => 'Base Fee:';

  @override
  String get gasDetailsPriorityFee => 'Priority Fee:';

  @override
  String get gasDetailsMaxFee => 'Max Fee:';

  @override
  String get tokenTransferAmountUnknown => 'Unknown';

  @override
  String get transactionDetailsModal_transaction => 'Transaction';

  @override
  String get transactionDetailsModal_hash => 'Hash';

  @override
  String get transactionDetailsModal_sig => 'Sig';

  @override
  String get transactionDetailsModal_timestamp => 'Timestamp';

  @override
  String get transactionDetailsModal_blockNumber => 'Block Number';

  @override
  String get transactionDetailsModal_nonce => 'Nonce';

  @override
  String get transactionDetailsModal_addresses => 'Addresses';

  @override
  String get transactionDetailsModal_sender => 'Sender';

  @override
  String get transactionDetailsModal_recipient => 'Recipient';

  @override
  String get transactionDetailsModal_contractAddress => 'Contract Address';

  @override
  String get transactionDetailsModal_network => 'Network';

  @override
  String get transactionDetailsModal_chainType => 'Chain Type';

  @override
  String get transactionDetailsModal_networkName => 'Network';

  @override
  String get transactionDetailsModal_gasFees => 'Gas & Fees';

  @override
  String get transactionDetailsModal_fee => 'Fee';

  @override
  String get transactionDetailsModal_gasUsed => 'Gas Used';

  @override
  String get transactionDetailsModal_gasLimit => 'Gas Limit';

  @override
  String get transactionDetailsModal_gasPrice => 'Gas Price';

  @override
  String get transactionDetailsModal_effectiveGasPrice => 'Effective Gas Price';

  @override
  String get transactionDetailsModal_blobGasUsed => 'Blob Gas Used';

  @override
  String get transactionDetailsModal_blobGasPrice => 'Blob Gas Price';

  @override
  String get transactionDetailsModal_error => 'Error';

  @override
  String get transactionDetailsModal_errorMessage => 'Error Message';

  @override
  String get amountSection_transfer => 'Transfer';

  @override
  String get amountSection_pending => 'Pending';

  @override
  String get amountSection_confirmed => 'Confirmed';

  @override
  String get amountSection_rejected => 'Rejected';

  @override
  String get appConnectModalContent_swipeToConnect => 'Swipe to Connect';

  @override
  String get appConnectModalContent_noAccounts => 'No accounts available';

  @override
  String get browserActionMenuShare => 'Share';

  @override
  String get browserActionMenuCopyLink => 'Copy Link';

  @override
  String get browserActionMenuRefresh => 'Refresh';

  @override
  String get browserActionMenuUrlBarTop => 'URL Bar at Top';

  @override
  String get keystoreBackupTitle => 'Keystore Backup';

  @override
  String get keystoreBackupWarningTitle => 'Secure Your Keystore File';

  @override
  String get keystoreBackupWarningMessage => 'The keystore file contains your encrypted private keys. Keep this file in a secure location and never share it with anyone. You will need the password you create to decrypt this file.';

  @override
  String get keystoreBackupConfirmPasswordHint => 'Confirm Password';

  @override
  String get keystoreBackupCreateButton => 'Create Backup';

  @override
  String get keystoreBackupError => 'Error creating backup:';

  @override
  String get keystoreBackupShareButton => 'Share Keystore File';

  @override
  String get keystoreBackupDoneButton => 'Done';

  @override
  String get keystoreBackupSuccessTitle => 'Backup Created Successfully';

  @override
  String get keystoreBackupSuccessMessage => 'Your keystore file has been created. Remember to keep both the file and your password safe.';

  @override
  String get keystoreBackupSaveAsButton => 'Save to File';

  @override
  String get keystoreBackupSaveDialogTitle => 'Save Keystore File';

  @override
  String get keystoreBackupSavedSuccess => 'Keystore file saved successfully';

  @override
  String get keystoreBackupSaveFailed => 'Failed to save keystore file';

  @override
  String get keystoreBackupPasswordTooShort => 'Password must be at least 8 characters';

  @override
  String get keystoreBackupTempLocation => 'Temporary file location';

  @override
  String get keystorePasswordHint => 'Enter your keystore password';

  @override
  String get keystoreRestoreButton => 'Restore Wallet';

  @override
  String get keystoreRestoreExtError => 'Please select a valid .zp file';

  @override
  String get keystoreRestoreNoFile => 'No keystore files found';

  @override
  String get keystoreRestoreFilesTitle => 'Keystore Files';

  @override
  String get editGasDialogTitle => 'Edit Gas Parameters';

  @override
  String get editGasDialogGasPrice => 'Gas Price';

  @override
  String get editGasDialogMaxPriorityFee => 'Max Priority Fee';

  @override
  String get editGasDialogGasLimit => 'Gas Limit';

  @override
  String get editGasDialogInvalidGasValues => 'Invalid gas values. Please check your inputs.';

  @override
  String get addLedgerAccountPageAppBarTitle => 'Add Ledger Account';

  @override
  String get addLedgerAccountPageGetAccountsButton => 'Get Accounts';

  @override
  String get addLedgerAccountPageCreateButton => 'Create';

  @override
  String get addLedgerAccountPageAddButton => 'Update';

  @override
  String get addLedgerAccountPageNoAccountsSelectedError => 'No accounts selected';

  @override
  String get addLedgerAccountPageNoWalletSelectedError => 'No wallet selected';

  @override
  String get transactionHistoryTitle => 'Transaction History';

  @override
  String get transactionHistoryDescription => 'Show addresses from transaction history in the address book.';

  @override
  String get zilStakePageTitle => 'Zilliqa Staking';

  @override
  String get noStakingPoolsFound => 'No Staking Pools Found';

  @override
  String get claimButton => 'Claim';

  @override
  String get stakeButton => 'Stake';

  @override
  String get unstakeButton => 'Unstake';

  @override
  String get aprLabel => 'APR';

  @override
  String get commissionLabel => 'Commission';

  @override
  String get stakedAmount => 'Staked';

  @override
  String get rewardsAvailable => 'Rewards';

  @override
  String get pendingWithdrawals => 'Pending Withdrawals';

  @override
  String get amount => 'Amount';

  @override
  String get claimableIn => 'Claimable in';

  @override
  String get blocks => 'blocks';

  @override
  String get unbondingPeriod => 'Unbonding Period';

  @override
  String get currentBlock => 'Current Block';

  @override
  String get version => 'Version';

  @override
  String get rewardsProgressTitle => 'Rewards Progress';

  @override
  String get ledgerConnectPageTitle => 'Connect Ledger';

  @override
  String get ledgerConnectPageInitializing => 'Initializing...';

  @override
  String get ledgerConnectPageScanningStatus => 'Scanning for Ledger devices...';

  @override
  String ledgerConnectPageFoundDevicesStatus(int count) {
    return 'Found $count device(s)...';
  }

  @override
  String ledgerConnectPageScanErrorStatus(String error) {
    return 'Scan Error: $error';
  }

  @override
  String get ledgerConnectPageScanFinishedNoDevices => 'Scan finished. No devices found.';

  @override
  String ledgerConnectPageScanFinishedWithDevices(int count) {
    return 'Scan finished. Found $count device(s). Select one to connect.';
  }

  @override
  String ledgerConnectPageConnectingStatus(String deviceName, String connectionType) {
    return 'Connecting to $deviceName ($connectionType)...';
  }

  @override
  String ledgerConnectPageConnectionSuccessStatus(String deviceName) {
    return 'Successfully connected to $deviceName!';
  }

  @override
  String get ledgerConnectPageConnectionFailedTitle => 'Connection Failed';

  @override
  String ledgerConnectPageConnectionFailedErrorStatus(String error) {
    return 'Connection Failed: $error';
  }

  @override
  String ledgerConnectPageConnectionFailedGenericContent(String deviceName, String error) {
    return 'Could not connect to $deviceName.\nError: $error';
  }

  @override
  String ledgerConnectPageDisconnectedStatus(String deviceName) {
    return 'Disconnected from $deviceName.';
  }

  @override
  String get ledgerConnectPageGoToSettings => 'Go to Settings';

  @override
  String get ledgerConnectPageNoDevicesFound => 'No devices found. Ensure Ledger is powered on, unlocked, and Bluetooth/USB is enabled.\nPull down or use refresh icon to scan again.';

  @override
  String get durationDay => 'd';

  @override
  String get durationHour => 'h';

  @override
  String get durationMinute => 'm';

  @override
  String get durationLessThanAMinute => '< 1m';

  @override
  String get durationNotAvailable => 'N/A';

  @override
  String get nodes => 'nodes';

  @override
  String get manageTokensPageTitle => 'Tokens';

  @override
  String get manageTokensSearchHint => 'Search tokens or paste address';

  @override
  String get manageTokensFoundToken => 'Found Token';

  @override
  String get manageTokensDeletedTokens => 'Deleted Tokens';

  @override
  String get manageTokensSuggestedTokens => 'Suggested Tokens';

  @override
  String get manageTokensFetchError => 'Failed to fetch token';

  @override
  String get manageTokensWrongChain => 'Token belongs to a different chain';

  @override
  String get manageTokensClear => 'Clear';

  @override
  String get signedMessageTypePersonalSign => 'Personal Sign';

  @override
  String get signedMessageTypeEip712 => 'EIP-712';

  @override
  String get signedMessageTypeUnknown => 'Unknown';

  @override
  String get signedMessageSigner => 'Signer';

  @override
  String get signedMessagePublicKey => 'Public Key';

  @override
  String get signedMessageType => 'Type';

  @override
  String get signedMessageEip712Domain => 'EIP-712 Domain';

  @override
  String get signedMessageDomainName => 'Name';

  @override
  String get signedMessageDomainChainId => 'Chain ID';

  @override
  String get signedMessageDomainContract => 'Contract';

  @override
  String get signedMessagePrimaryType => 'Primary Type';

  @override
  String get signedMessageData => 'Message Data';

  @override
  String get signedMessageContent => 'Content';

  @override
  String get signedMessageMessage => 'Message';

  @override
  String get web3ErrorNoMethod => 'No method specified';

  @override
  String web3ErrorUnsupportedMethod(String method) {
    return 'Method \"$method\" is not supported';
  }

  @override
  String get web3ErrorRequestInProgress => 'A similar request is already being processed';

  @override
  String get web3ErrorNotConnected => 'This domain is not connected. Please connect first.';

  @override
  String web3ErrorInvalidParams(String method, String params) {
    return 'Invalid parameters for $method. Required: $params';
  }

  @override
  String get web3ErrorAddressNotAuthorized => 'The requested address is not authorized';

  @override
  String get web3ErrorUserRejected => 'User rejected';

  @override
  String get web3ErrorUserRejectedRequest => 'User rejected the request';

  @override
  String web3ErrorMissingParam(String param) {
    return 'Missing required parameter: $param';
  }

  @override
  String get web3ErrorNoNativeToken => 'No native token found';

  @override
  String get web3ErrorPermissionNotSupported => 'Only eth_accounts permission is supported';

  @override
  String get web3ErrorNotAuthorizedSuggestTokens => 'This domain is not authorized to suggest tokens.';

  @override
  String get web3ErrorInvalidTokenType => 'Invalid parameters for wallet_watchAsset. Expected ERC20 token type.';

  @override
  String get web3ErrorMissingTokenFields => 'Missing required fields: address, symbol, or decimals.';

  @override
  String get web3ErrorMissingChainFields => 'Missing required fields for wallet_addEthereumChain';

  @override
  String get web3ErrorNoValidRpcUrls => 'No valid HTTP RPC URLs provided';

  @override
  String get web3ErrorMissingChainId => 'Missing required field: chainId';

  @override
  String get web3ErrorChainNotAdded => 'The requested chain has not been added. Use wallet_addEthereumChain first.';

  @override
  String get bipPurposeSetupPageTitle => 'Bitcoin Address';

  @override
  String get bip86Name => 'BIP86 (Taproot)';

  @override
  String get bip86Description => 'P2TR - Addresses starting with bc1p';

  @override
  String get bip84Name => 'BIP84 (Native SegWit)';

  @override
  String get bip84Description => 'P2WPKH - Addresses starting with bc1q';

  @override
  String get bip49Name => 'BIP49 (SegWit)';

  @override
  String get bip49Description => 'P2WPKH-nested-in-P2SH - Addresses starting with 3';

  @override
  String get bip44Name => 'BIP44 (Legacy)';

  @override
  String get bip44Description => 'P2PKH - Addresses starting with 1';
}
