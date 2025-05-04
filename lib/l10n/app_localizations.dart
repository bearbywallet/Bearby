import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ru'),
    Locale('zh')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'ZilPay Wallet'**
  String get appTitle;

  /// Button text to restore from ZilPay 1.0
  ///
  /// In en, this message translates to:
  /// **'Restore ZilPay 1.0!'**
  String get initialPagerestoreZilPay;

  /// Button text to begin using the app
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get initialPagegetStarted;

  /// Title for the RestoreRKStorage page showing wallet migration
  ///
  /// In en, this message translates to:
  /// **'Migrate ZilPay 1.0 to 2.0'**
  String get restoreRKStorageTitle;

  /// Prompt text instructing user to enter password for account migration on RestoreRKStorage page
  ///
  /// In en, this message translates to:
  /// **'Accounts to migrate to ZilPay 2.0. Enter password.'**
  String get restoreRKStorageAccountsPrompt;

  /// Hint text for password input field on RestoreRKStorage page
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get restoreRKStoragePasswordHint;

  /// Error message when password field is empty on RestoreRKStorage page
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get restoreRKStorageEnterPassword;

  /// Prefix for error messages on RestoreRKStorage page
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get restoreRKStorageErrorPrefix;

  /// Text for restore button on RestoreRKStorage page
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreRKStorageRestoreButton;

  /// Text for skip button on RestoreRKStorage page
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get restoreRKStorageSkipButton;

  /// Label for balance display in AccountItem widget
  ///
  /// In en, this message translates to:
  /// **'Balance:'**
  String get accountItemBalanceLabel;

  /// Title for the SendTokenPage (currently empty as per original code)
  ///
  /// In en, this message translates to:
  /// **''**
  String get sendTokenPageTitle;

  /// Text for the submit button on SendTokenPage
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get sendTokenPageSubmitButton;

  /// Title for the AboutPage
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutPageTitle;

  /// Application name displayed in logo section on AboutPage
  ///
  /// In en, this message translates to:
  /// **'ZilPay'**
  String get aboutPageAppName;

  /// Description text below app name on AboutPage
  ///
  /// In en, this message translates to:
  /// **'Your Secure Blockchain Wallet'**
  String get aboutPageAppDescription;

  /// Title for application info section on AboutPage
  ///
  /// In en, this message translates to:
  /// **'Application Info'**
  String get aboutPageAppInfoTitle;

  /// Label for version info on AboutPage
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutPageVersionLabel;

  /// Label for build date on AboutPage
  ///
  /// In en, this message translates to:
  /// **'Build Date'**
  String get aboutPageBuildDateLabel;

  /// Value for build date on AboutPage
  ///
  /// In en, this message translates to:
  /// **'March 10, 2025'**
  String get aboutPageBuildDateValue;

  /// Label for platform info on AboutPage
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get aboutPagePlatformLabel;

  /// Title for developer section on AboutPage
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get aboutPageDeveloperTitle;

  /// Label for author info on AboutPage
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get aboutPageAuthorLabel;

  /// Value for author info on AboutPage
  ///
  /// In en, this message translates to:
  /// **'Rinat (hicaru)'**
  String get aboutPageAuthorValue;

  /// Label for website info on AboutPage
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get aboutPageWebsiteLabel;

  /// Value for website info on AboutPage
  ///
  /// In en, this message translates to:
  /// **'https://zilpay.io'**
  String get aboutPageWebsiteValue;

  /// Title for legal section on AboutPage
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get aboutPageLegalTitle;

  /// Text for privacy policy link on AboutPage
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get aboutPagePrivacyPolicy;

  /// Text for terms of service link on AboutPage
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get aboutPageTermsOfService;

  /// Text for licenses link on AboutPage
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get aboutPageLicenses;

  /// Legal text for license page from AboutPage
  ///
  /// In en, this message translates to:
  /// **'© 2025 ZilPay. All rights reserved.'**
  String get aboutPageLegalese;

  /// Title for the LanguagePage
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languagePageTitle;

  /// System language option name on LanguagePage
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languagePageSystem;

  /// Title for the SecretKeyGeneratorPage
  ///
  /// In en, this message translates to:
  /// **'Secret Key'**
  String get secretKeyGeneratorPageTitle;

  /// Label for private key display on SecretKeyGeneratorPage
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get secretKeyGeneratorPagePrivateKey;

  /// Label for public key display on SecretKeyGeneratorPage
  ///
  /// In en, this message translates to:
  /// **'Public Key'**
  String get secretKeyGeneratorPagePublicKey;

  /// Text for backup confirmation checkbox on SecretKeyGeneratorPage
  ///
  /// In en, this message translates to:
  /// **'I have backup secret key'**
  String get secretKeyGeneratorPageBackupCheckbox;

  /// Text for next button on SecretKeyGeneratorPage
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get secretKeyGeneratorPageNextButton;

  /// Title for the WalletPage (empty as per original implementation)
  ///
  /// In en, this message translates to:
  /// **''**
  String get walletPageTitle;

  /// Hint text for wallet name input on WalletPage
  ///
  /// In en, this message translates to:
  /// **'Wallet name'**
  String get walletPageWalletNameHint;

  /// Title for preferences section on WalletPage
  ///
  /// In en, this message translates to:
  /// **'Wallet preferences'**
  String get walletPagePreferencesTitle;

  /// Label for manage connections preference item on WalletPage
  ///
  /// In en, this message translates to:
  /// **'Manage connections'**
  String get walletPageManageConnections;

  /// Label for backup preference item on WalletPage
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get walletPageBackup;

  /// Text for delete wallet button on WalletPage
  ///
  /// In en, this message translates to:
  /// **'Delete Wallet'**
  String get walletPageDeleteWallet;

  /// Reason text for biometric authentication prompt on WalletPage
  ///
  /// In en, this message translates to:
  /// **'Enable biometric authentication'**
  String get walletPageBiometricReason;

  /// Title for the NetworkPage (empty as per original implementation)
  ///
  /// In en, this message translates to:
  /// **''**
  String get networkPageTitle;

  /// Label for testnet toggle switch on NetworkPage
  ///
  /// In en, this message translates to:
  /// **'Show Testnet'**
  String get networkPageShowTestnet;

  /// Hint text for search input on NetworkPage
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get networkPageSearchHint;

  /// Section title for added networks on NetworkPage
  ///
  /// In en, this message translates to:
  /// **'Added Networks'**
  String get networkPageAddedNetworks;

  /// Section title for available networks on NetworkPage
  ///
  /// In en, this message translates to:
  /// **'Available Networks'**
  String get networkPageAvailableNetworks;

  /// Error message prefix when loading networks fails on NetworkPage
  ///
  /// In en, this message translates to:
  /// **'Failed to load network chains: '**
  String get networkPageLoadError;

  /// Error message prefix when adding a network fails on NetworkPage
  ///
  /// In en, this message translates to:
  /// **'Failed to add network: '**
  String get networkPageAddError;

  /// Title for the ReceivePage
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get receivePageTitle;

  /// Warning message displayed on ReceivePage with chain name and token symbol placeholders
  ///
  /// In en, this message translates to:
  /// **'Only send {chainName}({tokenSymbol}) assets to this address. Other assets will be lost forever.'**
  String receivePageWarning(Object chainName, Object tokenSymbol);

  /// Hint text for account name input on ReceivePage
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get receivePageAccountNameHint;

  /// Title for the amount input dialog on ReceivePage
  ///
  /// In en, this message translates to:
  /// **'Enter Amount'**
  String get receivePageAmountDialogTitle;

  /// Hint text for the amount input field in dialog on ReceivePage
  ///
  /// In en, this message translates to:
  /// **'0.0'**
  String get receivePageAmountDialogHint;

  /// Cancel button text in amount dialog on ReceivePage
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get receivePageAmountDialogCancel;

  /// Confirm button text in amount dialog on ReceivePage
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get receivePageAmountDialogConfirm;

  /// Title for the SecurityPage
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityPageTitle;

  /// Section title for network privacy settings on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'Network Privacy'**
  String get securityPageNetworkPrivacy;

  /// Label for ENS domains toggle on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'Show ENS domains in address bar'**
  String get securityPageEnsDomains;

  /// Description for ENS domains setting on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'Keep in mind that using this feature exposes your IP address to IPFS third-party services.'**
  String get securityPageEnsDescription;

  /// Label for IPFS gateway setting on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'IPFS gateway'**
  String get securityPageIpfsGateway;

  /// Description for IPFS gateway setting on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'ZIlPay uses third-party services to show images of your NFTs stored on IPFS, display information related to ENS(ZNS) addresses entered in your browser\'s address bar, and fetch icons for different tokens. Your IP address may be exposed to these services when you\'re using them.'**
  String get securityPageIpfsDescription;

  /// Label for gas station setting on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'Gas station'**
  String get securityPageGasStation;

  /// Description for gas station setting on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'Use ZilPay server for optimize your gas usage'**
  String get securityPageGasDescription;

  /// Label for node ranking setting on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'Node ranking'**
  String get securityPageNodeRanking;

  /// Description for node ranking setting on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'Make requests to ZilPay server for fetch best node'**
  String get securityPageNodeDescription;

  /// Section title for encryption level settings on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'Encryption Level'**
  String get securityPageEncryptionLevel;

  /// Label for protection progress bar in encryption card on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'Protection'**
  String get securityPageProtection;

  /// Label for CPU load progress bar in encryption card on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'CPU Load'**
  String get securityPageCpuLoad;

  /// Name of AES256 encryption algorithm on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'AES256'**
  String get securityPageAes256;

  /// Name of KUZNECHIK-GOST encryption algorithm on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'KUZNECHIK-GOST'**
  String get securityPageKuznechikGost;

  /// Name of NTRUPrime encryption algorithm on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'NTRUPrime'**
  String get securityPageNtruPrime;

  /// Name of Cyber encryption algorithm on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'Cyber'**
  String get securityPageCyber;

  /// Fallback name for unknown encryption algorithm on SecurityPage
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get securityPageUnknown;

  /// Label indicating Do Not Track is enabled in the WebViewPage app bar
  ///
  /// In en, this message translates to:
  /// **'DNT'**
  String get webViewPageDntLabel;

  /// Label indicating Incognito mode is enabled in the WebViewPage app bar
  ///
  /// In en, this message translates to:
  /// **'Incognito'**
  String get webViewPageIncognitoLabel;

  /// Error message title when web page fails to load on WebViewPage
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get webViewPageLoadError;

  /// Button text to retry loading the web page on WebViewPage
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get webViewPageTryAgain;

  /// Title for the SecretPhraseGeneratorPage
  ///
  /// In en, this message translates to:
  /// **'New Wallet'**
  String get secretPhraseGeneratorPageTitle;

  /// Text for backup confirmation checkbox on SecretPhraseGeneratorPage
  ///
  /// In en, this message translates to:
  /// **'I have backup words'**
  String get secretPhraseGeneratorPageBackupCheckbox;

  /// Text for next button on SecretPhraseGeneratorPage
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get secretPhraseGeneratorPageNextButton;

  /// Label displayed when using a testnet on HomePage
  ///
  /// In en, this message translates to:
  /// **'Testnet'**
  String get homePageTestnetLabel;

  /// Label displayed when shows error on home page
  ///
  /// In en, this message translates to:
  /// **'No signal'**
  String get homePageErrorTitle;

  /// Title for the RevealSecretKey page
  ///
  /// In en, this message translates to:
  /// **'Reveal Secret Key'**
  String get revealSecretKeyTitle;

  /// Hint text for password input on RevealSecretKey page
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get revealSecretKeyPasswordHint;

  /// Error message prefix for invalid password on RevealSecretKey page
  ///
  /// In en, this message translates to:
  /// **'invalid password, error:'**
  String get revealSecretKeyInvalidPassword;

  /// Text for submit button on RevealSecretKey page
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get revealSecretKeySubmitButton;

  /// Text for done button after revealing secret key on RevealSecretKey page
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get revealSecretKeyDoneButton;

  /// Title for scam alert section on RevealSecretKey page
  ///
  /// In en, this message translates to:
  /// **'SCAM ALERT'**
  String get revealSecretKeyScamAlertTitle;

  /// Message content for scam alert section on RevealSecretKey page
  ///
  /// In en, this message translates to:
  /// **'Never share your secret key with anyone. Never input it on any website.'**
  String get revealSecretKeyScamAlertMessage;

  /// Label for Testnet switch on SetupNetworkSettingsPage
  ///
  /// In en, this message translates to:
  /// **'Testnet'**
  String get setupNetworkSettingsPageTestnetSwitch;

  /// Hint text for search input on SetupNetworkSettingsPage
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get setupNetworkSettingsPageSearchHint;

  /// Message when no networks are available on SetupNetworkSettingsPage
  ///
  /// In en, this message translates to:
  /// **'No networks available'**
  String get setupNetworkSettingsPageNoNetworks;

  /// Message when no networks match search query on SetupNetworkSettingsPage
  ///
  /// In en, this message translates to:
  /// **'No networks found for \"{searchQuery}\"'**
  String setupNetworkSettingsPageNoResults(Object searchQuery);

  /// Text for Next button on SetupNetworkSettingsPage
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get setupNetworkSettingsPageNextButton;

  /// Label indicating Testnet in network item on SetupNetworkSettingsPage
  ///
  /// In en, this message translates to:
  /// **'Testnet'**
  String get setupNetworkSettingsPageTestnetLabel;

  /// Label indicating Mainnet in network item on SetupNetworkSettingsPage
  ///
  /// In en, this message translates to:
  /// **'Mainnet'**
  String get setupNetworkSettingsPageMainnetLabel;

  /// Label prefix for Chain ID in network item on SetupNetworkSettingsPage
  ///
  /// In en, this message translates to:
  /// **'Chain ID:'**
  String get setupNetworkSettingsPageChainIdLabel;

  /// Label prefix for Token in network item on SetupNetworkSettingsPage
  ///
  /// In en, this message translates to:
  /// **'Token:'**
  String get setupNetworkSettingsPageTokenLabel;

  /// Label prefix for Explorer in network item on SetupNetworkSettingsPage
  ///
  /// In en, this message translates to:
  /// **'Explorer:'**
  String get setupNetworkSettingsPageExplorerLabel;

  /// Title for the Appearance Settings page
  ///
  /// In en, this message translates to:
  /// **'Appearance Settings'**
  String get appearanceSettingsPageTitle;

  /// Title for the Compact Numbers switch setting
  ///
  /// In en, this message translates to:
  /// **'Compact Numbers'**
  String get appearanceSettingsPageCompactNumbersTitle;

  /// Description for the Compact Numbers switch setting
  ///
  /// In en, this message translates to:
  /// **'Enable to display abbreviated numbers (e.g., 20K instead of 20,000).'**
  String get appearanceSettingsPageCompactNumbersDescription;

  /// Title for the Device Settings theme option
  ///
  /// In en, this message translates to:
  /// **'Device settings'**
  String get appearanceSettingsPageDeviceSettingsTitle;

  /// Subtitle for the Device Settings theme option
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get appearanceSettingsPageDeviceSettingsSubtitle;

  /// Description for the Device Settings theme option
  ///
  /// In en, this message translates to:
  /// **'Default to your device\'s appearance. Your wallet theme will automatically adjust based on your system settings.'**
  String get appearanceSettingsPageDeviceSettingsDescription;

  /// Title for the Dark Mode theme option
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get appearanceSettingsPageDarkModeTitle;

  /// Subtitle for the Dark Mode theme option
  ///
  /// In en, this message translates to:
  /// **'Always dark'**
  String get appearanceSettingsPageDarkModeSubtitle;

  /// Description for the Dark Mode theme option
  ///
  /// In en, this message translates to:
  /// **'Keep the dark theme enabled at all times, regardless of your device settings.'**
  String get appearanceSettingsPageDarkModeDescription;

  /// Title for the Light Mode theme option
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get appearanceSettingsPageLightModeTitle;

  /// Subtitle for the Light Mode theme option
  ///
  /// In en, this message translates to:
  /// **'Always light'**
  String get appearanceSettingsPageLightModeSubtitle;

  /// Description for the Light Mode theme option
  ///
  /// In en, this message translates to:
  /// **'Keep the light theme enabled at all times, regardless of your device settings.'**
  String get appearanceSettingsPageLightModeDescription;

  /// Reason text for biometric authentication prompt on the Login page
  ///
  /// In en, this message translates to:
  /// **'Please authenticate'**
  String get loginPageBiometricReason;

  /// Default title for a wallet item when no custom name is provided on the Login page
  ///
  /// In en, this message translates to:
  /// **'Wallet {index}'**
  String loginPageWalletTitle(Object index);

  /// Hint text for the password input field on the Login page
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPagePasswordHint;

  /// Text for the unlock button on the Login page
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get loginPageUnlockButton;

  /// Welcome message displayed on the Login page
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginPageWelcomeBack;

  /// Title for the Secret Key Restore page
  ///
  /// In en, this message translates to:
  /// **'Restore Secret Key'**
  String get secretKeyRestorePageTitle;

  /// Hint text for the private key input field on the Secret Key Restore page
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get secretKeyRestorePageHint;

  /// Error message displayed when the private key format is invalid on the Secret Key Restore page
  ///
  /// In en, this message translates to:
  /// **'Invalid private key format'**
  String get secretKeyRestorePageInvalidFormat;

  /// Title for the private key display section on the Secret Key Restore page
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get secretKeyRestorePageKeyTitle;

  /// Label for the backup confirmation checkbox on the Secret Key Restore page
  ///
  /// In en, this message translates to:
  /// **'I have backed up my secret key'**
  String get secretKeyRestorePageBackupLabel;

  /// Text for the Next button on the Secret Key Restore page
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get secretKeyRestorePageNextButton;

  /// Title for the Add Account page
  ///
  /// In en, this message translates to:
  /// **'Add New Account'**
  String get addAccountPageTitle;

  /// Subtitle for the Add Account page
  ///
  /// In en, this message translates to:
  /// **'Create BIP39 Account'**
  String get addAccountPageSubtitle;

  /// Default account name format for the Add Account page
  ///
  /// In en, this message translates to:
  /// **'Account {index}'**
  String addAccountPageDefaultName(Object index);

  /// Hint text for the account name input field on the Add Account page
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get addAccountPageNameHint;

  /// Label for the BIP39 index counter on the Add Account page
  ///
  /// In en, this message translates to:
  /// **'BIP39 Index'**
  String get addAccountPageBip39Index;

  /// Label for the biometrics option on the Add Account page
  ///
  /// In en, this message translates to:
  /// **'Use Biometrics'**
  String get addAccountPageUseBiometrics;

  /// Hint text for the password input field on the Add Account page
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get addAccountPagePasswordHint;

  /// Label for the Zilliqa Legacy switch on the Add Account page
  ///
  /// In en, this message translates to:
  /// **'Zilliqa Legacy'**
  String get addAccountPageZilliqaLegacy;

  /// Reason text for biometric authentication prompt on the Add Account page
  ///
  /// In en, this message translates to:
  /// **'Authenticate to create a new account'**
  String get addAccountPageBiometricReason;

  /// Error message for biometric authentication failure on the Add Account page
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed: {error}'**
  String addAccountPageBiometricError(Object error);

  /// Error message when an account with the given index already exists on the Add Account page
  ///
  /// In en, this message translates to:
  /// **'Account with index {index} already exists'**
  String addAccountPageIndexExists(Object index);

  /// Error message when biometric authentication fails on the Add Account page
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed'**
  String get addAccountPageBiometricFailed;

  /// Error message when account creation fails on the Add Account page
  ///
  /// In en, this message translates to:
  /// **'Failed to create account: {error}'**
  String addAccountPageCreateFailed(Object error);

  /// Title for the Address Book page
  ///
  /// In en, this message translates to:
  /// **'Address Book'**
  String get addressBookPageTitle;

  /// Message displayed when the address book is empty on the Address Book page
  ///
  /// In en, this message translates to:
  /// **'Your contacts and their wallet address will\nappear here.'**
  String get addressBookPageEmptyMessage;

  /// Network label format for each address entry on the Address Book page
  ///
  /// In en, this message translates to:
  /// **'Network {network}'**
  String addressBookPageNetwork(Object network);

  /// Label for the Connected tab on the Browser page
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get browserPageConnectedTab;

  /// Label for the Explore tab on the Browser page
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get browserPageExploreTab;

  /// Message displayed when there are no apps to explore on the Browser page
  ///
  /// In en, this message translates to:
  /// **'No apps to explore yet'**
  String get browserPageNoExploreApps;

  /// Hint text for the search bar on the Browser page
  ///
  /// In en, this message translates to:
  /// **'Search with {engine} or enter address'**
  String browserPageSearchHint(Object engine);

  /// Message displayed when there are no connected apps on the Browser page
  ///
  /// In en, this message translates to:
  /// **'No connected apps'**
  String get browserPageNoConnectedApps;

  /// Title displayed at the top of the HistoryPage component
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get historyPageTitle;

  /// Message shown in the HistoryPage when there are no transactions to display
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get historyPageNoTransactions;

  /// Hint text displayed in the search input field on the HistoryPage
  ///
  /// In en, this message translates to:
  /// **'Search transactions...'**
  String get historyPageSearchHint;

  /// Title displayed in the app bar of the NotificationsSettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSettingsPageTitle;

  /// Title for the push notifications switch setting in the NotificationsSettingsPage
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get notificationsSettingsPagePushTitle;

  /// Description text for the push notifications switch setting in the NotificationsSettingsPage
  ///
  /// In en, this message translates to:
  /// **'Get notifications when tx sent and confirm, Notifications from connected apps.'**
  String get notificationsSettingsPagePushDescription;

  /// Title for the wallets section in the NotificationsSettingsPage
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get notificationsSettingsPageWalletsTitle;

  /// Description text for the wallets section in the NotificationsSettingsPage
  ///
  /// In en, this message translates to:
  /// **'Notifications from wallets'**
  String get notificationsSettingsPageWalletsDescription;

  /// Prefix used for unnamed wallets in the NotificationsSettingsPage, followed by wallet number
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get notificationsSettingsPageWalletPrefix;

  /// Title displayed in the app bar of the RevealSecretPhrase component
  ///
  /// In en, this message translates to:
  /// **'Reveal Secret Phrase'**
  String get revealSecretPhraseTitle;

  /// Hint text displayed in the password input field of the RevealSecretPhrase component
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get revealSecretPhrasePasswordHint;

  /// Error message prefix shown when password validation fails in the RevealSecretPhrase component
  ///
  /// In en, this message translates to:
  /// **'invalid password, error:'**
  String get revealSecretPhraseInvalidPassword;

  /// Text on the submit button in the RevealSecretPhrase component
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get revealSecretPhraseSubmitButton;

  /// Text on the done button displayed after revealing the secret phrase in the RevealSecretPhrase component
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get revealSecretPhraseDoneButton;

  /// Title of the scam alert section in the RevealSecretPhrase component
  ///
  /// In en, this message translates to:
  /// **'SCAM ALERT'**
  String get revealSecretPhraseScamAlertTitle;

  /// Description text in the scam alert section of the RevealSecretPhrase component
  ///
  /// In en, this message translates to:
  /// **'Never share your secret phrase with anyone. Never input it on any website.'**
  String get revealSecretPhraseScamAlertDescription;

  /// Title displayed in the app bar of the CipherSettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Encryption Setup'**
  String get cipherSettingsPageTitle;

  /// Text on the advanced settings button in the CipherSettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get cipherSettingsPageAdvancedButton;

  /// Title for the standard encryption option in the CipherSettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Standard Encryption'**
  String get cipherSettingsPageStandardTitle;

  /// Subtitle for the standard encryption option in the CipherSettingsPage component
  ///
  /// In en, this message translates to:
  /// **'AES-256 + KUZNECHIK-GOST'**
  String get cipherSettingsPageStandardSubtitle;

  /// Description for the standard encryption option in the CipherSettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Basic encryption with AES-256 and GOST standard KUZNECHIK.'**
  String get cipherSettingsPageStandardDescription;

  /// Title for the hybrid encryption option in the CipherSettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Hybrid Encryption'**
  String get cipherSettingsPageHybridTitle;

  /// Subtitle for the hybrid encryption option in the CipherSettingsPage component
  ///
  /// In en, this message translates to:
  /// **'CYBER + KUZNECHIK-GOST'**
  String get cipherSettingsPageHybridSubtitle;

  /// Description for the hybrid encryption option in the CipherSettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Hybrid encryption combining CYBER and KUZNECHIK-GOST algorithms.'**
  String get cipherSettingsPageHybridDescription;

  /// Title for the quantum-resistant encryption option in the CipherSettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Quantum-Resistant'**
  String get cipherSettingsPageQuantumTitle;

  /// Subtitle for the quantum-resistant encryption option in the CipherSettingsPage component
  ///
  /// In en, this message translates to:
  /// **'CYBER + KUZNECHIK + NTRUP1277'**
  String get cipherSettingsPageQuantumSubtitle;

  /// Description for the quantum-resistant encryption option in the CipherSettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Advanced quantum-resistant encryption with NTRUP1277.'**
  String get cipherSettingsPageQuantumDescription;

  /// Warning text displayed when quantum-resistant encryption is selected in the CipherSettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Quantum-resistant encryption may impact performance'**
  String get cipherSettingsPageQuantumWarning;

  /// Text on the confirm button in the CipherSettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get cipherSettingsPageConfirmButton;

  /// Title displayed in the app bar of the SecretPhraseVerifyPage component
  ///
  /// In en, this message translates to:
  /// **'Verify Secret'**
  String get secretPhraseVerifyPageTitle;

  /// Text on the skip button in the SecretPhraseVerifyPage component
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get secretPhraseVerifyPageSkipButton;

  /// Subtitle text displayed below the app bar in the SecretPhraseVerifyPage component
  ///
  /// In en, this message translates to:
  /// **'Verify Bip39 Secret'**
  String get secretPhraseVerifyPageSubtitle;

  /// Text on the next button in the SecretPhraseVerifyPage component
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get secretPhraseVerifyPageNextButton;

  /// Title displayed in the app bar of the RestoreSecretPhrasePage component
  ///
  /// In en, this message translates to:
  /// **'Restore Wallet'**
  String get restoreSecretPhrasePageTitle;

  /// Text on the restore button in the RestoreSecretPhrasePage component
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreSecretPhrasePageRestoreButton;

  /// Text displayed when BIP39 checksum validation fails
  ///
  /// In en, this message translates to:
  /// **'Checksum validation failed'**
  String get checksumValidationFailed;

  /// Text for the checkbox to proceed despite invalid checksum
  ///
  /// In en, this message translates to:
  /// **'Continue despite checksum error?'**
  String get proceedDespiteInvalidChecksum;

  /// Title displayed in the app bar of the SettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsPageTitle;

  /// Label for the Zilliqa Legacy switch in the SettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Zilliqa Legacy'**
  String get settingsPageZilliqaLegacy;

  /// Label for the Currency settings item in the SettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsPageCurrency;

  /// Label for the Appearance settings item in the SettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsPageAppearance;

  /// Label for the Notifications settings item in the SettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsPageNotifications;

  /// Label for the Address Book settings item in the SettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Address book'**
  String get settingsPageAddressBook;

  /// Label for the Security & Privacy settings item in the SettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Security & privacy'**
  String get settingsPageSecurityPrivacy;

  /// Label for the Networks settings item in the SettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Networks'**
  String get settingsPageNetworks;

  /// Label for the Language settings item in the SettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsPageLanguage;

  /// Label for the Browser settings item in the SettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Browser'**
  String get settingsPageBrowser;

  /// Label for the Telegram settings item in the SettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get settingsPageTelegram;

  /// Label for the Twitter settings item in the SettingsPage component
  ///
  /// In en, this message translates to:
  /// **'Twitter'**
  String get settingsPageTwitter;

  /// Label for the GitHub settings item in the SettingsPage component
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get settingsPageGitHub;

  /// Label for the About settings item in the SettingsPage component
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsPageAbout;

  /// Title displayed in the app bar of the PasswordSetupPage component
  ///
  /// In en, this message translates to:
  /// **'Password Setup'**
  String get passwordSetupPageTitle;

  /// Subtitle text displayed at the top of the PasswordSetupPage component
  ///
  /// In en, this message translates to:
  /// **'Create Password'**
  String get passwordSetupPageSubtitle;

  /// Hint text for the wallet name input field in the PasswordSetupPage component
  ///
  /// In en, this message translates to:
  /// **'Wallet Name'**
  String get passwordSetupPageWalletNameHint;

  /// Hint text for the password input field in the PasswordSetupPage component
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordSetupPagePasswordHint;

  /// Hint text for the confirm password input field in the PasswordSetupPage component
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get passwordSetupPageConfirmPasswordHint;

  /// Error message displayed when wallet name is empty in the PasswordSetupPage component
  ///
  /// In en, this message translates to:
  /// **'Wallet name cannot be empty'**
  String get passwordSetupPageEmptyWalletNameError;

  /// Error message displayed when wallet name exceeds length limit in the PasswordSetupPage component
  ///
  /// In en, this message translates to:
  /// **'Wallet name is too long'**
  String get passwordSetupPageLongWalletNameError;

  /// Error message displayed when password is too short in the PasswordSetupPage component
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordSetupPageShortPasswordError;

  /// Error message displayed when passwords do not match in the PasswordSetupPage component
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordSetupPageMismatchPasswordError;

  /// Label for the Zilliqa Legacy switch in the PasswordSetupPage component
  ///
  /// In en, this message translates to:
  /// **'Legacy'**
  String get passwordSetupPageLegacyLabel;

  /// Text on the create password button in the PasswordSetupPage component
  ///
  /// In en, this message translates to:
  /// **'Create Password'**
  String get passwordSetupPageCreateButton;

  /// Reason text displayed during biometric authentication in the PasswordSetupPage component
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to enable quick access'**
  String get passwordSetupPageAuthReason;

  /// Type label used in wallet name generation for seed-based wallets in the PasswordSetupPage component
  ///
  /// In en, this message translates to:
  /// **'Seed'**
  String get passwordSetupPageSeedType;

  /// Type label used in wallet name generation for key-based wallets in the PasswordSetupPage component
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get passwordSetupPageKeyType;

  /// Default network name used in wallet name generation when no specific network is provided in the PasswordSetupPage component
  ///
  /// In en, this message translates to:
  /// **'Universal'**
  String get passwordSetupPageUniversalNetwork;

  /// Title for the Browser Settings page
  ///
  /// In en, this message translates to:
  /// **'Browser Settings'**
  String get browserSettingsTitle;

  /// Section title for browser options
  ///
  /// In en, this message translates to:
  /// **'Browser Options'**
  String get browserSettingsBrowserOptions;

  /// Title for search engine setting
  ///
  /// In en, this message translates to:
  /// **'Search Engine'**
  String get browserSettingsSearchEngine;

  /// Description for search engine setting
  ///
  /// In en, this message translates to:
  /// **'Configure your default search engine'**
  String get browserSettingsSearchEngineDescription;

  /// Title for search engine selection modal
  ///
  /// In en, this message translates to:
  /// **'Search Engine'**
  String get browserSettingsSearchEngineTitle;

  /// Title for content blocking setting
  ///
  /// In en, this message translates to:
  /// **'Content Blocking'**
  String get browserSettingsContentBlocking;

  /// Description for content blocking setting
  ///
  /// In en, this message translates to:
  /// **'Configure content blocking settings'**
  String get browserSettingsContentBlockingDescription;

  /// Title for content blocking selection modal
  ///
  /// In en, this message translates to:
  /// **'Content Blocking'**
  String get browserSettingsContentBlockingTitle;

  /// Section title for privacy and security settings
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get browserSettingsPrivacySecurity;

  /// Title for cookies setting
  ///
  /// In en, this message translates to:
  /// **'Cookies'**
  String get browserSettingsCookies;

  /// Description for cookies setting
  ///
  /// In en, this message translates to:
  /// **'Allow websites to save and read cookies'**
  String get browserSettingsCookiesDescription;

  /// Title for do not track setting
  ///
  /// In en, this message translates to:
  /// **'Do Not Track'**
  String get browserSettingsDoNotTrack;

  /// Description for do not track setting
  ///
  /// In en, this message translates to:
  /// **'Request websites not to track your browsing'**
  String get browserSettingsDoNotTrackDescription;

  /// Title for incognito mode setting
  ///
  /// In en, this message translates to:
  /// **'Incognito Mode'**
  String get browserSettingsIncognitoMode;

  /// Description for incognito mode setting
  ///
  /// In en, this message translates to:
  /// **'Browse without saving history or cookies'**
  String get browserSettingsIncognitoModeDescription;

  /// Section title for performance settings
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get browserSettingsPerformance;

  /// Title for cache setting
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get browserSettingsCache;

  /// Section title for clear data options in browser settings
  ///
  /// In en, this message translates to:
  /// **'Clear Data'**
  String get browserSettingsClearData;

  /// Button text for clearing browser data
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get browserSettingsClear;

  /// Title for the clear cookies option
  ///
  /// In en, this message translates to:
  /// **'Clear Cookies'**
  String get browserSettingsClearCookies;

  /// Description explaining what clearing cookies does
  ///
  /// In en, this message translates to:
  /// **'Delete all cookies stored by websites'**
  String get browserSettingsClearCookiesDescription;

  /// Title for the clear cache option
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get browserSettingsClearCache;

  /// Description explaining what clearing cache does
  ///
  /// In en, this message translates to:
  /// **'Delete temporary files and images stored during browsing'**
  String get browserSettingsClearCacheDescription;

  /// Title for the clear local storage option
  ///
  /// In en, this message translates to:
  /// **'Clear Local Storage'**
  String get browserSettingsClearLocalStorage;

  /// Description explaining what clearing local storage does
  ///
  /// In en, this message translates to:
  /// **'Delete website data stored locally on your device'**
  String get browserSettingsClearLocalStorageDescription;

  /// Description for cache setting
  ///
  /// In en, this message translates to:
  /// **'Store website data for faster loading'**
  String get browserSettingsCacheDescription;

  /// Title for the Generate Wallet Options page
  ///
  /// In en, this message translates to:
  /// **'Generate Wallet'**
  String get genWalletOptionsTitle;

  /// Title for BIP39 wallet generation option
  ///
  /// In en, this message translates to:
  /// **'BIP39'**
  String get genWalletOptionsBIP39Title;

  /// Subtitle for BIP39 wallet generation option
  ///
  /// In en, this message translates to:
  /// **'Generate Mnemonic phrase'**
  String get genWalletOptionsBIP39Subtitle;

  /// Title for SLIP-0039 wallet generation option
  ///
  /// In en, this message translates to:
  /// **'SLIP-0039'**
  String get genWalletOptionsSLIP0039Title;

  /// Subtitle for SLIP-0039 wallet generation option
  ///
  /// In en, this message translates to:
  /// **'Generate Mnemonic phrase with share'**
  String get genWalletOptionsSLIP0039Subtitle;

  /// Title for Private Key wallet generation option
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get genWalletOptionsPrivateKeyTitle;

  /// Subtitle for Private Key wallet generation option
  ///
  /// In en, this message translates to:
  /// **'Generate just one private key'**
  String get genWalletOptionsPrivateKeySubtitle;

  /// Title for the Add Wallet Options page
  ///
  /// In en, this message translates to:
  /// **'Add Wallet'**
  String get addWalletOptionsTitle;

  /// Title for new wallet option
  ///
  /// In en, this message translates to:
  /// **'New Wallet'**
  String get addWalletOptionsNewWalletTitle;

  /// Subtitle for new wallet option
  ///
  /// In en, this message translates to:
  /// **'Create new wallet'**
  String get addWalletOptionsNewWalletSubtitle;

  /// Title for existing wallet option
  ///
  /// In en, this message translates to:
  /// **'Existing Wallet'**
  String get addWalletOptionsExistingWalletTitle;

  /// Subtitle for existing wallet option
  ///
  /// In en, this message translates to:
  /// **'Import wallet with a 24 secret recovery words'**
  String get addWalletOptionsExistingWalletSubtitle;

  /// Title for pair with Ledger option
  ///
  /// In en, this message translates to:
  /// **'Pair with Ledger'**
  String get addWalletOptionsPairWithLedgerTitle;

  /// Subtitle for pair with Ledger option
  ///
  /// In en, this message translates to:
  /// **'Hardware module, Bluetooth'**
  String get addWalletOptionsPairWithLedgerSubtitle;

  /// Section title for other wallet options
  ///
  /// In en, this message translates to:
  /// **'Other options'**
  String get addWalletOptionsOtherOptions;

  /// Title for watch account option
  ///
  /// In en, this message translates to:
  /// **'Watch Account'**
  String get addWalletOptionsWatchAccountTitle;

  /// Subtitle for watch account option
  ///
  /// In en, this message translates to:
  /// **'For monitor wallet activity without recovery phrase'**
  String get addWalletOptionsWatchAccountSubtitle;

  /// Title for the Currency Conversion page
  ///
  /// In en, this message translates to:
  /// **'Primary Currency'**
  String get currencyConversionTitle;

  /// Hint text for the currency search input
  ///
  /// In en, this message translates to:
  /// **'Search currencies...'**
  String get currencyConversionSearchHint;

  /// Title for the currency engine selection
  ///
  /// In en, this message translates to:
  /// **'Currency Engine'**
  String get currencyConversionEngineTitle;

  /// Description for the currency engine selection
  ///
  /// In en, this message translates to:
  /// **'Engine for fetching currency rates'**
  String get currencyConversionEngineDescription;

  /// Title for the currency engine selector modal
  ///
  /// In en, this message translates to:
  /// **'Select Currency Engine'**
  String get currencyConversionEngineSelectorTitle;

  /// Title for the 'None' engine option
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get currencyConversionEngineNone;

  /// Subtitle for the 'None' engine option
  ///
  /// In en, this message translates to:
  /// **'No engine selected'**
  String get currencyConversionEngineNoneSubtitle;

  /// Title for the 'Coingecko' engine option
  ///
  /// In en, this message translates to:
  /// **'Coingecko'**
  String get currencyConversionEngineCoingecko;

  /// Subtitle for the 'Coingecko' engine option
  ///
  /// In en, this message translates to:
  /// **'Fetch rates from Coingecko'**
  String get currencyConversionEngineCoingeckoSubtitle;

  /// Title for the Restore Wallet Options page
  ///
  /// In en, this message translates to:
  /// **'Restore Wallet'**
  String get restoreWalletOptionsTitle;

  /// Title for BIP39 restore option
  ///
  /// In en, this message translates to:
  /// **'BIP39'**
  String get restoreWalletOptionsBIP39Title;

  /// Subtitle for BIP39 restore option
  ///
  /// In en, this message translates to:
  /// **'Restore with Mnemonic phrase'**
  String get restoreWalletOptionsBIP39Subtitle;

  /// Title for SLIP-0039 restore option
  ///
  /// In en, this message translates to:
  /// **'SLIP-0039'**
  String get restoreWalletOptionsSLIP0039Title;

  /// Subtitle for SLIP-0039 restore option
  ///
  /// In en, this message translates to:
  /// **'Restore with Shared Mnemonic phrase'**
  String get restoreWalletOptionsSLIP0039Subtitle;

  /// Title for Private Key restore option
  ///
  /// In en, this message translates to:
  /// **'Private Key'**
  String get restoreWalletOptionsPrivateKeyTitle;

  /// Subtitle for Private Key restore option
  ///
  /// In en, this message translates to:
  /// **'Restore with private key'**
  String get restoreWalletOptionsPrivateKeySubtitle;

  /// Title for keystore restore option
  ///
  /// In en, this message translates to:
  /// **'Keystore File'**
  String get restoreWalletOptionsKeyStoreTitle;

  /// Subtitle for keystore restore option
  ///
  /// In en, this message translates to:
  /// **'Restore wallet using password-encrypted backup file'**
  String get restoreWalletOptionsKeyStoreSubtitle;

  /// Title for QR code restore option
  ///
  /// In en, this message translates to:
  /// **'QRcode'**
  String get restoreWalletOptionsQRCodeTitle;

  /// Subtitle for QR code restore option
  ///
  /// In en, this message translates to:
  /// **'Restore wallet by QRcode scanning'**
  String get restoreWalletOptionsQRCodeSubtitle;

  /// Title for low memory Argon2 parameter option in ArgonSettingsModalContent
  ///
  /// In en, this message translates to:
  /// **'Low Memory'**
  String get argonSettingsModalContentLowMemoryTitle;

  /// Subtitle for low memory Argon2 parameter option in ArgonSettingsModalContent
  ///
  /// In en, this message translates to:
  /// **'64KB RAM, 3 iterations'**
  String get argonSettingsModalContentLowMemorySubtitle;

  /// Description for low memory Argon2 parameter option in ArgonSettingsModalContent
  ///
  /// In en, this message translates to:
  /// **'Minimal memory usage, suitable for low-end devices.'**
  String get argonSettingsModalContentLowMemoryDescription;

  /// Title for OWASP default Argon2 parameter option in ArgonSettingsModalContent
  ///
  /// In en, this message translates to:
  /// **'OWASP Default'**
  String get argonSettingsModalContentOwaspTitle;

  /// Subtitle for OWASP default Argon2 parameter option in ArgonSettingsModalContent
  ///
  /// In en, this message translates to:
  /// **'6.5MB RAM, 2 iterations'**
  String get argonSettingsModalContentOwaspSubtitle;

  /// Description for OWASP default Argon2 parameter option in ArgonSettingsModalContent
  ///
  /// In en, this message translates to:
  /// **'Recommended by OWASP for general use.'**
  String get argonSettingsModalContentOwaspDescription;

  /// Title for secure Argon2 parameter option in ArgonSettingsModalContent
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get argonSettingsModalContentSecureTitle;

  /// Subtitle for secure Argon2 parameter option in ArgonSettingsModalContent
  ///
  /// In en, this message translates to:
  /// **'256MB RAM, 4 iterations'**
  String get argonSettingsModalContentSecureSubtitle;

  /// Description for secure Argon2 parameter option in ArgonSettingsModalContent
  ///
  /// In en, this message translates to:
  /// **'High security with increased memory and iterations.'**
  String get argonSettingsModalContentSecureDescription;

  /// Hint text for secret input field in ArgonSettingsModalContent
  ///
  /// In en, this message translates to:
  /// **'Enter secret (optional)'**
  String get argonSettingsModalContentSecretHint;

  /// Text for confirm button in ArgonSettingsModalContent
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get argonSettingsModalContentConfirmButton;

  /// Hint text for the password input field in the ConfirmTransactionContent modal.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get confirmTransactionContentPasswordHint;

  /// Text displayed on the swipe button when confirmation is not possible in the ConfirmTransactionContent modal.
  ///
  /// In en, this message translates to:
  /// **'Unable to confirm'**
  String get confirmTransactionContentUnableToConfirm;

  /// Text displayed on the swipe button to confirm the transaction in the ConfirmTransactionContent modal.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmTransactionContentConfirm;

  /// Error message shown when the user has insufficient balance to complete the transaction in the ConfirmTransactionContent modal.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance'**
  String get confirmTransactionContentInsufficientBalance;

  /// Error message thrown when no active account is found in the ConfirmTransactionContent modal.
  ///
  /// In en, this message translates to:
  /// **'No active account'**
  String get confirmTransactionContentNoActiveAccount;

  /// Error message displayed when transfer details fail to load in the ConfirmTransactionContent modal.
  ///
  /// In en, this message translates to:
  /// **'Failed to load transfer details'**
  String get confirmTransactionContentFailedLoadTransfer;

  /// Text displayed on the edit gas button in the ConfirmTransactionContent modal.
  ///
  /// In en, this message translates to:
  /// **'Edit gas'**
  String get confirmTransactionEditGasButtonText;

  /// Reason text displayed during authentication prompt in the ConfirmTransactionContent modal.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate'**
  String get authReason;

  /// Warning text displayed at the bottom of the AddChainModalContent modal to alert users about potential risks.
  ///
  /// In en, this message translates to:
  /// **'Beware of network scams and security risks.'**
  String get addChainModalContentWarning;

  /// Text on the swipe button to confirm adding the chain in the AddChainModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get addChainModalContentApprove;

  /// Title for the details section in the AddChainModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get addChainModalContentDetails;

  /// Label for the network name field in the details section of the AddChainModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Network Name:'**
  String get addChainModalContentNetworkName;

  /// Label for the currency symbol field in the details section of the AddChainModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Currency Symbol:'**
  String get addChainModalContentCurrencySymbol;

  /// Label for the chain ID field in the details section of the AddChainModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Chain ID:'**
  String get addChainModalContentChainId;

  /// Label for the block explorer URL field in the details section of the AddChainModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Block Explorer:'**
  String get addChainModalContentBlockExplorer;

  /// Title text for the AddAddressModal modal.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get addAddressModalTitle;

  /// Description text explaining the purpose of the AddAddressModal modal.
  ///
  /// In en, this message translates to:
  /// **'Enter the contact name and wallet address to add to your address book.'**
  String get addAddressModalDescription;

  /// Hint text for the name input field in the AddAddressModal modal.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get addAddressModalNameHint;

  /// Hint text for the wallet address input field in the AddAddressModal modal.
  ///
  /// In en, this message translates to:
  /// **'Wallet Address'**
  String get addAddressModalAddressHint;

  /// Error message displayed when the name field is empty in the AddAddressModal modal.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get addAddressModalNameEmptyError;

  /// Error message displayed when the address field is empty in the AddAddressModal modal.
  ///
  /// In en, this message translates to:
  /// **'Address cannot be empty'**
  String get addAddressModalAddressEmptyError;

  /// Text on the button to confirm adding a contact in the AddAddressModal modal.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get addAddressModalButton;

  /// Hint text for the search input field in the TokenSelectModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tokenSelectModalContentSearchHint;

  /// Reason text for authentication prompt in the SignMessageModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to sign the message'**
  String get signMessageModalContentAuthReason;

  /// Error message format when signing fails in the SignMessageModalContent modal, with {error} placeholder for the error details.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign: {error}'**
  String signMessageModalContentFailedToSign(Object error);

  /// Title text for the SignMessageModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Sign Message'**
  String get signMessageModalContentTitle;

  /// Description text explaining the purpose of the SignMessageModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Review and sign the following message with your wallet.'**
  String get signMessageModalContentDescription;

  /// Label for the domain field in the typed data section of the SignMessageModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Domain:'**
  String get signMessageModalContentDomain;

  /// Label for the chain ID field in the typed data section of the SignMessageModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Chain ID:'**
  String get signMessageModalContentChainId;

  /// Label for the verifying contract field in the typed data section of the SignMessageModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Contract:'**
  String get signMessageModalContentContract;

  /// Label for the primary type field in the typed data section of the SignMessageModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Type:'**
  String get signMessageModalContentType;

  /// Text displayed when no message data is provided in the SignMessageModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get signMessageModalContentNoData;

  /// Hint text for the password input field in the SignMessageModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signMessageModalContentPasswordHint;

  /// Text displayed on the swipe button while processing in the SignMessageModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get signMessageModalContentProcessing;

  /// Text displayed on the swipe button to confirm signing in the SignMessageModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Sign Message'**
  String get signMessageModalContentSign;

  /// Text displayed below the progress indicator when scanning for Ledger devices in the SignMessageModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Scanning Ledger devices...'**
  String get signMessageModalContentScanning;

  /// Error message displayed when no Ledger devices are found after scanning in the SignMessageModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'No Ledger devices found'**
  String get signMessageModalContentNoLedgerDevices;

  /// Error message displayed when no wallet is selected in the SignMessageModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Wallet not selected'**
  String get signMessageModalContentWalletNotSelected;

  /// Error message displayed when no Ledger device is selected in the SignMessageModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Ledger device not selected'**
  String get signMessageModalContentLedgerNotSelected;

  /// Error message format when scanning for Ledger devices fails in the SignMessageModalContent modal, with {error} placeholder for the error details.
  ///
  /// In en, this message translates to:
  /// **'Failed to scan Ledger devices: {error}'**
  String signMessageModalContentFailedToScanLedger(Object error);

  /// Error message format when signing a message with a Ledger device fails in the SignMessageModalContent modal, with {error} placeholder for the error details.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign message: {error}'**
  String signMessageModalContentFailedToSignMessage(Object error);

  /// Error message displayed when Bluetooth is not enabled during Ledger device scanning in the SignMessageModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is turned off. Please enable it to scan for Ledger devices.'**
  String get signMessageModalContentBluetoothOff;

  /// Title text for the DeleteWalletModal modal.
  ///
  /// In en, this message translates to:
  /// **'Delete Wallet'**
  String get deleteWalletModalTitle;

  /// Warning text about the irreversible nature of deleting a wallet in the DeleteWalletModal modal.
  ///
  /// In en, this message translates to:
  /// **'Warning: This action cannot be undone. Your wallet can only be recovered using your secret phrase. If you don\'t have access to it, you will permanently lose all funds associated with this account.'**
  String get deleteWalletModalWarning;

  /// Additional warning text emphasizing the importance of the secret phrase in the DeleteWalletModal modal.
  ///
  /// In en, this message translates to:
  /// **'Please make sure you have access to your secret phrase before proceeding.'**
  String get deleteWalletModalSecretPhraseWarning;

  /// Hint text for the password input field in the DeleteWalletModal modal.
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get deleteWalletModalPasswordHint;

  /// Text on the button to confirm wallet deletion in the DeleteWalletModal modal.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get deleteWalletModalSubmit;

  /// Hint text for the search input field in the ManageTokensModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get manageTokensModalContentSearchHint;

  /// Title text for the AddressSelectModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Select Address'**
  String get addressSelectModalContentTitle;

  /// Hint text for the search input field in the AddressSelectModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Search / Address / ENS'**
  String get addressSelectModalContentSearchHint;

  /// Default name used for an unknown address or QR code result in the AddressSelectModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get addressSelectModalContentUnknown;

  /// Section title for the 'My Accounts' list in the AddressSelectModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'My Accounts'**
  String get addressSelectModalContentMyAccounts;

  /// Section title for the 'Address Book' list in the AddressSelectModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Address Book'**
  String get addressSelectModalContentAddressBook;

  /// Section title for the 'History' list in the AddressSelectModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get addressSelectModalContentHistory;

  /// Label shown on addresses that belong to the sender account in the AddressSelectModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get addressSelectModalContentSender;

  /// Title text for the ChangePasswordModal modal.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordModalTitle;

  /// Description text explaining the purpose of the ChangePasswordModal modal.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password and choose a new password to update your wallet security.'**
  String get changePasswordModalDescription;

  /// Hint text for the current password input field in the ChangePasswordModal modal.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get changePasswordModalCurrentPasswordHint;

  /// Hint text for the new password input field in the ChangePasswordModal modal.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get changePasswordModalNewPasswordHint;

  /// Hint text for the confirm new password input field in the ChangePasswordModal modal.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get changePasswordModalConfirmPasswordHint;

  /// Error message displayed when the current password field is empty in the ChangePasswordModal modal.
  ///
  /// In en, this message translates to:
  /// **'Current password cannot be empty'**
  String get changePasswordModalCurrentPasswordEmptyError;

  /// Error message displayed when the new password is less than 6 characters in the ChangePasswordModal modal.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get changePasswordModalPasswordLengthError;

  /// Error message displayed when the new password and confirmation do not match in the ChangePasswordModal modal.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get changePasswordModalPasswordsMismatchError;

  /// Text on the button to confirm password change in the ChangePasswordModal modal.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordModalButton;

  /// Title text for the ConfirmPasswordModal modal.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordModalTitle;

  /// Description text explaining the purpose of the ConfirmPasswordModal modal.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to continue.'**
  String get confirmPasswordModalDescription;

  /// Hint text for the password input field in the ConfirmPasswordModal modal.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get confirmPasswordModalHint;

  /// Error message displayed when the password field is empty in the ConfirmPasswordModal modal.
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty'**
  String get confirmPasswordModalEmptyError;

  /// Error message displayed when the entered password is incorrect in the ConfirmPasswordModal modal.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get confirmPasswordModalIncorrectError;

  /// Prefix for generic error messages followed by the specific error in the ConfirmPasswordModal modal.
  ///
  /// In en, this message translates to:
  /// **'Error:'**
  String get confirmPasswordModalGenericError;

  /// Text on the button to confirm the password in the ConfirmPasswordModal modal.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmPasswordModalButton;

  /// Title text for the QRScannerModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get qrScannerModalContentTitle;

  /// Prefix for error message when camera initialization fails in the QRScannerModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Camera initialization error:'**
  String get qrScannerModalContentCameraInitError;

  /// Prefix for error message when toggling the torch fails in the QRScannerModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Failed to toggle torch:'**
  String get qrScannerModalContentTorchError;

  /// Text on the button to open app settings when camera permission is denied on iOS in the QRScannerModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get qrScannerModalContentOpenSettings;

  /// Title text for the network token section in the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Network Token'**
  String get chainInfoModalContentTokenTitle;

  /// Title text for the network information section in the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Network Information'**
  String get chainInfoModalContentNetworkInfoTitle;

  /// Label for the chain field in the network information section of the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get chainInfoModalContentChainLabel;

  /// Label for the short name field in the network information section of the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Short Name'**
  String get chainInfoModalContentShortNameLabel;

  /// Label for the chain ID field in the network information section of the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Chain ID'**
  String get chainInfoModalContentChainIdLabel;

  /// Label for the Slip44 field in the network information section of the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Slip44'**
  String get chainInfoModalContentSlip44Label;

  /// Label for the chain IDs field in the network information section of the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Chain IDs'**
  String get chainInfoModalContentChainIdsLabel;

  /// Label for the testnet field in the network information section of the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Testnet'**
  String get chainInfoModalContentTestnetLabel;

  /// Text displayed for a true testnet value in the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get chainInfoModalContentYes;

  /// Text displayed for a false testnet value in the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get chainInfoModalContentNo;

  /// Label for the diff block time field in the network information section of the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Diff Block Time'**
  String get chainInfoModalContentDiffBlockTimeLabel;

  /// Label for the fallback enabled switch in the network information section of the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Fallback Enabled'**
  String get chainInfoModalContentFallbackEnabledLabel;

  /// Label for the decimals field in the first token section of the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Decimals'**
  String get chainInfoModalContentDecimalsLabel;

  /// Title text for the RPC nodes section in the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'RPC Nodes'**
  String get chainInfoModalContentRpcNodesTitle;

  /// Title text for the explorers section in the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Explorers'**
  String get chainInfoModalContentExplorersTitle;

  /// Title text for the delete network section in the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Delete Network'**
  String get chainInfoModalContentDeleteProviderTitle;

  /// Text displayed on the swipe button for deleting a network in the ChainInfoModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Delete network'**
  String get chainInfoModalContentSwipeToDelete;

  /// Title text for the SwitchChainNetworkContent modal.
  ///
  /// In en, this message translates to:
  /// **'Select Network'**
  String get switchChainNetworkContentTitle;

  /// Text on the swipe button to confirm network switch in the SwitchChainNetworkContent modal.
  ///
  /// In en, this message translates to:
  /// **'Switch Network'**
  String get switchChainNetworkContentButton;

  /// Label displayed next to a testnet network name in the SwitchChainNetworkContent modal.
  ///
  /// In en, this message translates to:
  /// **'Testnet'**
  String get switchChainNetworkContentTestnetLabel;

  /// Label prefix for the chain ID in the network details row of the SwitchChainNetworkContent modal.
  ///
  /// In en, this message translates to:
  /// **'ID:'**
  String get switchChainNetworkContentIdLabel;

  /// Title text for the WatchAssetModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Add suggested token'**
  String get watchAssetModalContentTitle;

  /// Description text explaining the purpose of the WatchAssetModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Review and add the following token suggested by the app.'**
  String get watchAssetModalContentDescription;

  /// Label for the token column in the WatchAssetModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get watchAssetModalContentTokenLabel;

  /// Label for the balance column in the WatchAssetModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get watchAssetModalContentBalanceLabel;

  /// Text on the swipe button while loading balance in the WatchAssetModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Balance...'**
  String get watchAssetModalContentLoadingButton;

  /// Text on the swipe button to confirm adding the token in the WatchAssetModalContent modal.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get watchAssetModalContentAddButton;

  /// Hint text for the search input in the ConnectedDappsModalContent component
  ///
  /// In en, this message translates to:
  /// **'Search DApps'**
  String get connectedDappsModalSearchHint;

  /// Text displayed when no DApps are connected in the ConnectedDappsModalContent component
  ///
  /// In en, this message translates to:
  /// **'No connected DApps'**
  String get connectedDappsModalNoDapps;

  /// Text showing when a DApp was last connected in the DappListItem component, where {time} is a placeholder for the formatted time
  ///
  /// In en, this message translates to:
  /// **'Connected {time}'**
  String dappListItemConnected(Object time);

  /// Text indicating a DApp was connected very recently in the DappListItem component
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get dappListItemJustNow;

  /// Title for the secret recovery phrase option in the SecretRecoveryModal component
  ///
  /// In en, this message translates to:
  /// **'Reveal Secret Recovery Phrase'**
  String get secretRecoveryModalRevealPhraseTitle;

  /// Description text for the secret recovery phrase option in the SecretRecoveryModal component
  ///
  /// In en, this message translates to:
  /// **'If you ever change browsers or move computers, you will need this Secret Recovery Phrase to access your accounts. Save them somewhere safe and secret.'**
  String get secretRecoveryModalRevealPhraseDescription;

  /// Button text for revealing the secret recovery phrase in the SecretRecoveryModal component
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get secretRecoveryModalRevealPhraseButton;

  /// Title for the private keys option in the SecretRecoveryModal component
  ///
  /// In en, this message translates to:
  /// **'Show Private Keys'**
  String get secretRecoveryModalShowKeysTitle;

  /// Description text for the private keys option in the SecretRecoveryModal component
  ///
  /// In en, this message translates to:
  /// **'Warning: Never disclose this key. Anyone with your private keys can steal any assets held in your account.'**
  String get secretRecoveryModalShowKeysDescription;

  /// Button text for exporting private keys in the SecretRecoveryModal component
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get secretRecoveryModalShowKeysButton;

  /// Title text for the keystore backup option in the SecretRecoveryModal component
  ///
  /// In en, this message translates to:
  /// **'Keystore Backup'**
  String get secretRecoveryModalKeystoreBackupTitle;

  /// Description text for the keystore backup option in the SecretRecoveryModal component
  ///
  /// In en, this message translates to:
  /// **'Save your private keys in a password-protected encrypted keystore file. This provides an additional layer of security for your wallet.'**
  String get secretRecoveryModalKeystoreBackupDescription;

  /// Button text for the keystore backup option in the SecretRecoveryModal component
  ///
  /// In en, this message translates to:
  /// **'Create Keystore Backup'**
  String get secretRecoveryModalKeystoreBackupButton;

  /// Title for the backup confirmation modal in the BackupConfirmationContent component
  ///
  /// In en, this message translates to:
  /// **'Backup Confirmation'**
  String get backupConfirmationContentTitle;

  /// Warning message about the importance of keeping seed phrases safe and in correct order
  ///
  /// In en, this message translates to:
  /// **'WARNING: If you lose or forget your seed phrase in the exact order, you will lose your funds permanently. Never share your seed phrase with anyone or they may steal your funds. BIP39 recovery is strict - any mistake in the words during recovery will result in loss of funds.'**
  String get backupConfirmationWarning;

  /// Confirmation item indicating the user has written down the backup in the BackupConfirmationContent component
  ///
  /// In en, this message translates to:
  /// **'I have written down all'**
  String get backupConfirmationContentWrittenDown;

  /// Confirmation item indicating the user has safely stored the backup in the BackupConfirmationContent component
  ///
  /// In en, this message translates to:
  /// **'I have safely stored the backup'**
  String get backupConfirmationContentSafelyStored;

  /// Confirmation item indicating the user is confident they won't lose the backup in the BackupConfirmationContent component
  ///
  /// In en, this message translates to:
  /// **'I am sure I won\'t lose the backup'**
  String get backupConfirmationContentWontLose;

  /// Confirmation item indicating the user understands not to share the backup words in the BackupConfirmationContent component
  ///
  /// In en, this message translates to:
  /// **'I understand not to share these words with anyone'**
  String get backupConfirmationContentNotShare;

  /// Error message displayed when the Counter widget reaches its maximum value
  ///
  /// In en, this message translates to:
  /// **'Maximum value reached'**
  String get counterMaxValueError;

  /// Error message displayed when the Counter widget reaches its minimum value
  ///
  /// In en, this message translates to:
  /// **'Minimum value reached'**
  String get counterMinValueError;

  /// Text displayed for enabling Face ID in the BiometricSwitch widget
  ///
  /// In en, this message translates to:
  /// **'Enable Face ID'**
  String get biometricSwitchFaceId;

  /// Text displayed for enabling Fingerprint in the BiometricSwitch widget
  ///
  /// In en, this message translates to:
  /// **'Enable Fingerprint'**
  String get biometricSwitchFingerprint;

  /// Text displayed for enabling Biometric Login in the BiometricSwitch widget
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric Login'**
  String get biometricSwitchBiometric;

  /// Text displayed for enabling Device PIN in the BiometricSwitch widget
  ///
  /// In en, this message translates to:
  /// **'Enable Device PIN'**
  String get biometricSwitchPinCode;

  /// Title for the low gas fee option in GasEIP1559 widget
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get gasFeeOptionLow;

  /// Title for the market gas fee option in GasEIP1559 widget
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get gasFeeOptionMarket;

  /// Title for the aggressive gas fee option in GasEIP1559 widget
  ///
  /// In en, this message translates to:
  /// **'Aggressive'**
  String get gasFeeOptionAggressive;

  /// Label for estimated gas in GasDetails widget
  ///
  /// In en, this message translates to:
  /// **'Estimated Gas:'**
  String get gasDetailsEstimatedGas;

  /// Label for gas price in GasDetails widget
  ///
  /// In en, this message translates to:
  /// **'Gas Price:'**
  String get gasDetailsGasPrice;

  /// Label for base fee in GasDetails widget
  ///
  /// In en, this message translates to:
  /// **'Base Fee:'**
  String get gasDetailsBaseFee;

  /// Label for priority fee in GasDetails widget
  ///
  /// In en, this message translates to:
  /// **'Priority Fee:'**
  String get gasDetailsPriorityFee;

  /// Label for max fee in GasDetails widget
  ///
  /// In en, this message translates to:
  /// **'Max Fee:'**
  String get gasDetailsMaxFee;

  /// Text displayed when the sender or recipient name is not provided in the TokenTransferAmount widget
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get tokenTransferAmountUnknown;

  /// Title for the transaction details section in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transactionDetailsModal_transaction;

  /// Label for transaction hash in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Hash'**
  String get transactionDetailsModal_hash;

  /// Label for transaction signature in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Sig'**
  String get transactionDetailsModal_sig;

  /// Label for transaction timestamp in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get transactionDetailsModal_timestamp;

  /// Label for block number in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Block Number'**
  String get transactionDetailsModal_blockNumber;

  /// Label for transaction nonce in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Nonce'**
  String get transactionDetailsModal_nonce;

  /// Title for addresses section in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get transactionDetailsModal_addresses;

  /// Label for sender address in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get transactionDetailsModal_sender;

  /// Label for recipient address in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get transactionDetailsModal_recipient;

  /// Label for contract address in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Contract Address'**
  String get transactionDetailsModal_contractAddress;

  /// Title for network section in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get transactionDetailsModal_network;

  /// Label for chain type in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Chain Type'**
  String get transactionDetailsModal_chainType;

  /// Label for network name in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get transactionDetailsModal_networkName;

  /// Title for gas and fees section in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Gas & Fees'**
  String get transactionDetailsModal_gasFees;

  /// Label for transaction fee in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get transactionDetailsModal_fee;

  /// Label for gas used in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Gas Used'**
  String get transactionDetailsModal_gasUsed;

  /// Label for gas limit in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Gas Limit'**
  String get transactionDetailsModal_gasLimit;

  /// Label for gas price in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Gas Price'**
  String get transactionDetailsModal_gasPrice;

  /// Label for effective gas price in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Effective Gas Price'**
  String get transactionDetailsModal_effectiveGasPrice;

  /// Label for blob gas used in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Blob Gas Used'**
  String get transactionDetailsModal_blobGasUsed;

  /// Label for blob gas price in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Blob Gas Price'**
  String get transactionDetailsModal_blobGasPrice;

  /// Title for error section in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get transactionDetailsModal_error;

  /// Label for error message in TransactionDetailsModal
  ///
  /// In en, this message translates to:
  /// **'Error Message'**
  String get transactionDetailsModal_errorMessage;

  /// Title for transfer section in _AmountSection
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get amountSection_transfer;

  /// Status text for pending transaction in _AmountSection
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get amountSection_pending;

  /// Status text for confirmed transaction in _AmountSection
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get amountSection_confirmed;

  /// Status text for rejected transaction in _AmountSection
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get amountSection_rejected;

  /// Text for the swipe button in _AppConnectModalContent
  ///
  /// In en, this message translates to:
  /// **'Swipe to Connect'**
  String get appConnectModalContent_swipeToConnect;

  /// Text shown when no accounts are available in _AppConnectModalContent
  ///
  /// In en, this message translates to:
  /// **'No accounts available'**
  String get appConnectModalContent_noAccounts;

  /// Menu item text for sharing the current page
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get browserActionMenuShare;

  /// Menu item text for copying the current page link
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get browserActionMenuCopyLink;

  /// Menu item text for closing the current page or tab
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get browserActionMenuClose;

  /// Title for the Keystore Backup screen
  ///
  /// In en, this message translates to:
  /// **'Keystore Backup'**
  String get keystoreBackupTitle;

  /// Title for the warning alert on the Keystore Backup screen
  ///
  /// In en, this message translates to:
  /// **'Secure Your Keystore File'**
  String get keystoreBackupWarningTitle;

  /// Warning message explaining the importance of securing the keystore file
  ///
  /// In en, this message translates to:
  /// **'The keystore file contains your encrypted private keys. Keep this file in a secure location and never share it with anyone. You will need the password you create to decrypt this file.'**
  String get keystoreBackupWarningMessage;

  /// Placeholder text for the password confirmation field
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get keystoreBackupConfirmPasswordHint;

  /// Text for the button to create a keystore backup
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get keystoreBackupCreateButton;

  /// Error message shown when the entered passwords don't match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get keystoreBackupPasswordsDoNotMatch;

  /// Error message shown when the password is too short
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get keystoreBackupPasswordTooShort;

  /// Prefix for error messages when backup creation fails
  ///
  /// In en, this message translates to:
  /// **'Error creating backup:'**
  String get keystoreBackupError;

  /// Text for the button to share the created keystore file
  ///
  /// In en, this message translates to:
  /// **'Share Keystore File'**
  String get keystoreBackupShareButton;

  /// Text for the button to dismiss the screen after backup is complete
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get keystoreBackupDoneButton;

  /// Title for the success message when backup is created
  ///
  /// In en, this message translates to:
  /// **'Backup Created Successfully'**
  String get keystoreBackupSuccessTitle;

  /// Message explaining that backup creation was successful and reminding about security
  ///
  /// In en, this message translates to:
  /// **'Your keystore file has been created. Remember to keep both the file and your password safe.'**
  String get keystoreBackupSuccessMessage;

  /// Button text to open file picker and save keystore file
  ///
  /// In en, this message translates to:
  /// **'Save to File'**
  String get keystoreBackupSaveAsButton;

  /// Dialog title for the file save picker
  ///
  /// In en, this message translates to:
  /// **'Save Keystore File'**
  String get keystoreBackupSaveDialogTitle;

  /// Message shown when keystore was saved successfully
  ///
  /// In en, this message translates to:
  /// **'Keystore file saved successfully'**
  String get keystoreBackupSavedSuccess;

  /// Error message when keystore file save failed
  ///
  /// In en, this message translates to:
  /// **'Failed to save keystore file'**
  String get keystoreBackupSaveFailed;

  /// Label for displaying the temporary file location
  ///
  /// In en, this message translates to:
  /// **'Temporary file location'**
  String get keystoreBackupTempLocation;

  /// Hint text for the keystore password input field
  ///
  /// In en, this message translates to:
  /// **'Enter your keystore password'**
  String get keystorePasswordHint;

  /// Button text to restore the wallet from keystore
  ///
  /// In en, this message translates to:
  /// **'Restore Wallet'**
  String get keystoreRestoreButton;

  /// title when we have keystore files
  ///
  /// In en, this message translates to:
  /// **'Please select a valid .zp file'**
  String get keystoreRestoreExtError;

  /// No description provided for @keystoreRestoreNoFile.
  ///
  /// In en, this message translates to:
  /// **'No keystore files found'**
  String get keystoreRestoreNoFile;

  /// No description provided for @keystoreRestoreFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Keystore Files'**
  String get keystoreRestoreFilesTitle;

  /// Title of the dialog for editing gas parameters
  ///
  /// In en, this message translates to:
  /// **'Edit Gas Parameters'**
  String get editGasDialogTitle;

  /// Label for gas price input field in the gas edit dialog
  ///
  /// In en, this message translates to:
  /// **'Gas Price'**
  String get editGasDialogGasPrice;

  /// Label for max priority fee input field in the gas edit dialog
  ///
  /// In en, this message translates to:
  /// **'Max Priority Fee'**
  String get editGasDialogMaxPriorityFee;

  /// Label for gas limit input field in the gas edit dialog
  ///
  /// In en, this message translates to:
  /// **'Gas Limit'**
  String get editGasDialogGasLimit;

  /// Button text to cancel gas parameter changes
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get editGasDialogCancel;

  /// Button text to save gas parameter changes
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editGasDialogSave;

  /// Error message shown when invalid gas values are entered
  ///
  /// In en, this message translates to:
  /// **'Invalid gas values. Please check your inputs.'**
  String get editGasDialogInvalidGasValues;

  /// Title for the app bar in the AddLedgerAccountPage component
  ///
  /// In en, this message translates to:
  /// **'Add Ledger Account'**
  String get addLedgerAccountPageAppBarTitle;

  /// Button text for fetching accounts from a Ledger device in the AddLedgerAccountPage component
  ///
  /// In en, this message translates to:
  /// **'Get Accounts'**
  String get addLedgerAccountPageGetAccountsButton;

  /// Button text for creating a new wallet in the AddLedgerAccountPage component
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get addLedgerAccountPageCreateButton;

  /// Button text for adding accounts to an existing wallet in the AddLedgerAccountPage component
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addLedgerAccountPageAddButton;

  /// Message displayed while scanning for Ledger devices in the AddLedgerAccountPage component
  ///
  /// In en, this message translates to:
  /// **'Scanning for Ledger devices...'**
  String get addLedgerAccountPageScanningMessage;

  /// Message displayed when no Ledger devices are found in the AddLedgerAccountPage component
  ///
  /// In en, this message translates to:
  /// **'No Ledger devices found'**
  String get addLedgerAccountPageNoDevicesMessage;

  /// Error message displayed when Bluetooth is disabled in the AddLedgerAccountPage component
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is turned off. Please enable it to scan for Ledger devices.'**
  String get addLedgerAccountPageBluetoothOffError;

  /// Error message displayed when the wallet name is empty in the AddLedgerAccountPage component
  ///
  /// In en, this message translates to:
  /// **'Wallet name cannot be empty'**
  String get addLedgerAccountPageEmptyWalletNameError;

  /// Error message displayed when the wallet name exceeds the maximum length in the AddLedgerAccountPage component
  ///
  /// In en, this message translates to:
  /// **'Wallet name is too long (max 24 characters)'**
  String get addLedgerAccountPageWalletNameTooLongError;

  /// Error message displayed when scanning for Ledger devices fails in the AddLedgerAccountPage component, with a placeholder for the error details
  ///
  /// In en, this message translates to:
  /// **'Failed to scan for Ledger devices: {error}'**
  String addLedgerAccountPageFailedToScanError(Object error);

  /// Error message displayed when network or Ledger data is missing in the AddLedgerAccountPage component
  ///
  /// In en, this message translates to:
  /// **'Network or Ledger data is missing'**
  String get addLedgerAccountPageNetworkOrLedgerMissingError;

  /// Error message displayed when no accounts are selected for creating a wallet in the AddLedgerAccountPage component
  ///
  /// In en, this message translates to:
  /// **'No accounts selected'**
  String get addLedgerAccountPageNoAccountsSelectedError;

  /// Error message displayed when no wallet is selected for adding accounts in the AddLedgerAccountPage component
  ///
  /// In en, this message translates to:
  /// **'No wallet selected'**
  String get addLedgerAccountPageNoWalletSelectedError;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ja', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ja': return AppLocalizationsJa();
    case 'ru': return AppLocalizationsRu();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
