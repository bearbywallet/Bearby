import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
    Locale('en')
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

  /// Russian language option name on LanguagePage
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languagePageRussian;

  /// English language option name on LanguagePage
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languagePageEnglish;

  /// Turkish language option name on LanguagePage
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languagePageTurkish;

  /// Chinese language option name on LanguagePage
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get languagePageChinese;

  /// Uzbek language option name on LanguagePage
  ///
  /// In en, this message translates to:
  /// **'Uzbek'**
  String get languagePageUzbek;

  /// Indonesian language option name on LanguagePage
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get languagePageIndonesian;

  /// Ukrainian language option name on LanguagePage
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get languagePageUkrainian;

  /// Local name for English and System languages on LanguagePage
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languagePageEnglishLocal;

  /// Local name for Russian language on LanguagePage
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languagePageRussianLocal;

  /// Local name for Turkish language on LanguagePage
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get languagePageTurkishLocal;

  /// Local name for Chinese language on LanguagePage
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languagePageChineseLocal;

  /// Local name for Uzbek language on LanguagePage
  ///
  /// In en, this message translates to:
  /// **'O\'zbekcha'**
  String get languagePageUzbekLocal;

  /// Local name for Indonesian language on LanguagePage
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languagePageIndonesianLocal;

  /// Local name for Ukrainian language on LanguagePage
  ///
  /// In en, this message translates to:
  /// **'Українська'**
  String get languagePageUkrainianLocal;

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

  /// Title for the AddTokenPage
  ///
  /// In en, this message translates to:
  /// **'Add Token'**
  String get addTokenPageTitle;

  /// Section title for token information input on AddTokenPage
  ///
  /// In en, this message translates to:
  /// **'Token Information'**
  String get addTokenPageTokenInfo;

  /// Hint text for token input field on AddTokenPage
  ///
  /// In en, this message translates to:
  /// **'Address, name, symbol'**
  String get addTokenPageHint;

  /// Error message prefix when adding token fails on AddTokenPage
  ///
  /// In en, this message translates to:
  /// **'Failed to add token:'**
  String get addTokenPageAddError;

  /// Error message for invalid token address or network issues on AddTokenPage
  ///
  /// In en, this message translates to:
  /// **'Invalid token address or network error'**
  String get addTokenPageInvalidAddressError;

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

  /// Error message prefix when loading chains fails on SetupNetworkSettingsPage
  ///
  /// In en, this message translates to:
  /// **'Failed to load network chains:'**
  String get setupNetworkSettingsPageLoadError;

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
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
