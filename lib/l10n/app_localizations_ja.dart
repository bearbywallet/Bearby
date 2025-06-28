// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ZilPay ウォレット';

  @override
  String get initialPagerestoreZilPay => 'ZilPay 1.0を復元!';

  @override
  String get initialPagegetStarted => '始める';

  @override
  String get restoreRKStorageTitle => 'ZilPay 1.0から2.0への移行';

  @override
  String get restoreRKStorageAccountsPrompt => 'ZilPay 2.0に移行するアカウント。パスワードを入力してください。';

  @override
  String get restoreRKStoragePasswordHint => 'パスワード';

  @override
  String get restoreRKStorageEnterPassword => 'パスワードを入力';

  @override
  String get restoreRKStorageErrorPrefix => 'エラー:';

  @override
  String get restoreRKStorageRestoreButton => '復元';

  @override
  String get restoreRKStorageSkipButton => 'スキップ';

  @override
  String get accountItemBalanceLabel => '残高:';

  @override
  String get sendTokenPageTitle => '';

  @override
  String get sendTokenPageSubmitButton => '送信';

  @override
  String get aboutPageTitle => 'アプリについて';

  @override
  String get aboutPageAppName => 'ZilPay';

  @override
  String get aboutPageAppDescription => '安全なブロックチェーンウォレット';

  @override
  String get aboutPageAppInfoTitle => 'アプリ情報';

  @override
  String get aboutPageVersionLabel => 'バージョン';

  @override
  String get aboutPageBuildDateLabel => 'ビルド日';

  @override
  String get aboutPageBuildDateValue => '2025年3月10日';

  @override
  String get aboutPagePlatformLabel => 'プラットフォーム';

  @override
  String get aboutPageDeveloperTitle => '開発者';

  @override
  String get aboutPageAuthorLabel => '作者';

  @override
  String get aboutPageAuthorValue => 'Rinat (hicaru)';

  @override
  String get aboutPageWebsiteLabel => 'ウェブサイト';

  @override
  String get aboutPageWebsiteValue => 'https://zilpay.io';

  @override
  String get aboutPageLegalTitle => '法的情報';

  @override
  String get aboutPagePrivacyPolicy => 'プライバシーポリシー';

  @override
  String get aboutPageTermsOfService => '利用規約';

  @override
  String get aboutPageLicenses => 'ライセンス';

  @override
  String get aboutPageLegalese => '© 2025 ZilPay. 全ての権利を保有。';

  @override
  String get languagePageTitle => '言語';

  @override
  String get languagePageSystem => 'システム';

  @override
  String get secretKeyGeneratorPageTitle => '秘密鍵';

  @override
  String get secretKeyGeneratorPagePrivateKey => 'プライベートキー';

  @override
  String get secretKeyGeneratorPagePublicKey => 'パブリックキー';

  @override
  String get secretKeyGeneratorPageBackupCheckbox => '秘密鍵をバックアップしました';

  @override
  String get secretKeyGeneratorPageNextButton => '次へ';

  @override
  String get walletPageTitle => '';

  @override
  String get walletPageWalletNameHint => 'ウォレット名';

  @override
  String get walletPagePreferencesTitle => 'ウォレット設定';

  @override
  String get walletPageManageConnections => '接続の管理';

  @override
  String get walletPageBackup => 'バックアップ';

  @override
  String get walletPageDeleteWallet => 'ウォレットを削除';

  @override
  String get walletPageBiometricReason => '生体認証を有効にする';

  @override
  String get networkPageTitle => '';

  @override
  String get networkPageShowTestnet => 'テストネットを表示';

  @override
  String get networkPageSearchHint => '検索';

  @override
  String get networkPageAddedNetworks => '追加したネットワーク';

  @override
  String get networkPageAvailableNetworks => '利用可能なネットワーク';

  @override
  String get networkPageLoadError => 'ネットワークチェーンの読み込みに失敗: ';

  @override
  String get networkPageAddError => 'ネットワークの追加に失敗: ';

  @override
  String get receivePageTitle => '受信';

  @override
  String receivePageWarning(Object chainName, Object tokenSymbol) {
    return 'このアドレスには$chainName($tokenSymbol)資産のみを送信してください。他の資産は永久に失われます。';
  }

  @override
  String get receivePageAccountNameHint => 'アカウント名';

  @override
  String get receivePageAmountDialogTitle => '金額を入力';

  @override
  String get receivePageAmountDialogHint => '0.0';

  @override
  String get receivePageAmountDialogCancel => 'キャンセル';

  @override
  String get receivePageAmountDialogConfirm => '確認';

  @override
  String get securityPageTitle => 'セキュリティ';

  @override
  String get securityPageNetworkPrivacy => 'ネットワークプライバシー';

  @override
  String get securityPageEnsDomains => 'アドレスバーにENSドメインを表示';

  @override
  String get securityPageEnsDescription => 'この機能を使用すると、IPアドレスがIPFSサードパーティサービスに公開されることに注意してください。';

  @override
  String get securityPageIpfsGateway => 'IPFSゲートウェイ';

  @override
  String get securityPageIpfsDescription => 'ZIlPayは、IPFS上のNFT画像の表示、ブラウザのアドレスバーに入力されたENS(ZNS)アドレスに関する情報の表示、およびトークンアイコンの取得にサードパーティサービスを使用します。これらのサービスを利用する際、IPアドレスが公開される可能性があります。';

  @override
  String get securityPageTokensFetcherTitle => 'トークンフェッチャー';

  @override
  String get securityPageTokensFetcherDescription => 'セキュリティページのトークンフェッチャー設定。有効にすると、トークンがサーバーから自動的に取得され、追加できます。';

  @override
  String get securityPageNodeRanking => 'ノードランキング';

  @override
  String get securityPageNodeDescription => '最適なノードを取得するためにZilPayサーバーにリクエストを送信';

  @override
  String get securityPageEncryptionLevel => '暗号化レベル';

  @override
  String get securityPageProtection => '保護';

  @override
  String get securityPageCpuLoad => 'CPU負荷';

  @override
  String get securityPageAes256 => 'AES256';

  @override
  String get securityPageKuznechikGost => 'KUZNECHIK-GOST';

  @override
  String get securityPageNtruPrime => 'NTRUPrime';

  @override
  String get securityPageCyber => 'サイバー';

  @override
  String get securityPageUnknown => '不明';

  @override
  String get webViewPageDntLabel => 'DNT';

  @override
  String get webViewPageIncognitoLabel => 'シークレット';

  @override
  String get webViewPageLoadError => '読み込みに失敗';

  @override
  String get webViewPageTryAgain => '再試行';

  @override
  String get secretPhraseGeneratorPageTitle => '新しいウォレット';

  @override
  String get secretPhraseGeneratorPageBackupCheckbox => '単語をバックアップしました';

  @override
  String get secretPhraseGeneratorPageNextButton => '次へ';

  @override
  String get homePageTestnetLabel => 'テストネット';

  @override
  String get homePageErrorTitle => '信号なし';

  @override
  String get homePageSendButton => '送信';

  @override
  String get homePageReceiveButton => '受信';

  @override
  String get revealSecretKeyTitle => '秘密鍵を表示';

  @override
  String get revealSecretKeyPasswordHint => 'パスワード';

  @override
  String get revealSecretKeyInvalidPassword => '無効なパスワード、エラー:';

  @override
  String get revealSecretKeySubmitButton => '送信';

  @override
  String get revealSecretKeyDoneButton => '完了';

  @override
  String get revealSecretKeyScamAlertTitle => '詐欺警告';

  @override
  String get revealSecretKeyScamAlertMessage => '秘密鍵を他人と共有したり、いかなるウェブサイトにも入力したりしないでください。';

  @override
  String get setupNetworkSettingsPageTestnetSwitch => 'テストネット';

  @override
  String get setupNetworkSettingsPageSearchHint => '検索';

  @override
  String get setupNetworkSettingsPageNoNetworks => '利用可能なネットワークがありません';

  @override
  String setupNetworkSettingsPageNoResults(Object searchQuery) {
    return '\"$searchQuery\"に一致するネットワークが見つかりません';
  }

  @override
  String get setupNetworkSettingsPageNextButton => '次へ';

  @override
  String get setupNetworkSettingsPageTestnetLabel => 'テストネット';

  @override
  String get setupNetworkSettingsPageMainnetLabel => 'メインネット';

  @override
  String get setupNetworkSettingsPageChainIdLabel => 'チェーンID:';

  @override
  String get setupNetworkSettingsPageTokenLabel => 'トークン:';

  @override
  String get setupNetworkSettingsPageExplorerLabel => 'エクスプローラー:';

  @override
  String get appearanceSettingsPageTitle => '外観設定';

  @override
  String get appearanceSettingsPageCompactNumbersTitle => 'コンパクト数字';

  @override
  String get appearanceSettingsPageCompactNumbersDescription => '省略形の数字を表示します（例：20,000の代わりに20K）。';

  @override
  String get appearanceSettingsPageDeviceSettingsTitle => 'デバイス設定';

  @override
  String get appearanceSettingsPageDeviceSettingsSubtitle => 'システムデフォルト';

  @override
  String get appearanceSettingsPageDeviceSettingsDescription => 'デバイスの外観に合わせます。ウォレットのテーマはシステム設定に基づいて自動的に調整されます。';

  @override
  String get appearanceSettingsPageDarkModeTitle => 'ダークモード';

  @override
  String get appearanceSettingsPageDarkModeSubtitle => '常にダーク';

  @override
  String get appearanceSettingsPageDarkModeDescription => 'デバイス設定に関係なく、常にダークテーマを有効にします。';

  @override
  String get appearanceSettingsPageLightModeTitle => 'ライトモード';

  @override
  String get appearanceSettingsPageLightModeSubtitle => '常にライト';

  @override
  String get appearanceSettingsPageLightModeDescription => 'デバイス設定に関係なく、常にライトテーマを有効にします。';

  @override
  String get loginPageBiometricReason => '認証してください';

  @override
  String loginPageWalletTitle(Object index) {
    return 'ウォレット $index';
  }

  @override
  String get loginPagePasswordHint => 'パスワード';

  @override
  String get loginPageUnlockButton => 'ロック解除';

  @override
  String get loginPageWelcomeBack => 'おかえりなさい';

  @override
  String get secretKeyRestorePageTitle => '秘密鍵を復元';

  @override
  String get secretKeyRestorePageHint => 'プライベートキー';

  @override
  String get secretKeyRestorePageInvalidFormat => '無効なプライベートキー形式';

  @override
  String get secretKeyRestorePageKeyTitle => 'プライベートキー';

  @override
  String get secretKeyRestorePageBackupLabel => '秘密鍵をバックアップしました';

  @override
  String get secretKeyRestorePageNextButton => '次へ';

  @override
  String get addAccountPageTitle => '新しいアカウントを追加';

  @override
  String get addAccountPageSubtitle => 'BIP39アカウントを作成';

  @override
  String addAccountPageDefaultName(Object index) {
    return 'アカウント $index';
  }

  @override
  String get addAccountPageNameHint => 'アカウント名';

  @override
  String get addAccountPageBip39Index => 'BIP39インデックス';

  @override
  String get addAccountPageUseBiometrics => '生体認証を使用';

  @override
  String get addAccountPagePasswordHint => 'パスワード';

  @override
  String get addAccountPageZilliqaLegacy => 'Zilliqaレガシー';

  @override
  String get addAccountPageBiometricReason => '新しいアカウントを作成するために認証';

  @override
  String addAccountPageBiometricError(Object error) {
    return '生体認証に失敗: $error';
  }

  @override
  String addAccountPageIndexExists(Object index) {
    return 'インデックス$indexのアカウントはすでに存在します';
  }

  @override
  String get addAccountPageBiometricFailed => '生体認証に失敗しました';

  @override
  String addAccountPageCreateFailed(Object error) {
    return 'アカウントの作成に失敗: $error';
  }

  @override
  String get addressBookPageTitle => 'アドレス帳';

  @override
  String get addressBookPageEmptyMessage => '連絡先とそのウォレットアドレスが\nここに表示されます。';

  @override
  String get addressBookPageDeleteConfirmationTitle => '連絡先を削除';

  @override
  String addressBookPageDeleteConfirmationMessage(String contactName) {
    return '本当に$contactNameをアドレス帳から削除しますか？';
  }

  @override
  String addressBookPageDeleteTooltip(String contactName) {
    return '$contactNameを削除';
  }

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get browserPageConnectedTab => '接続済み';

  @override
  String get browserPageExploreTab => '探索';

  @override
  String get browserPageNoExploreApps => '探索するアプリがまだありません';

  @override
  String browserPageSearchHint(Object engine) {
    return '$engineで検索するかアドレスを入力';
  }

  @override
  String get browserPageNoConnectedApps => '接続されたアプリはありません';

  @override
  String get historyPageTitle => 'トランザクション履歴';

  @override
  String get historyPageNoTransactions => 'トランザクションがありません';

  @override
  String get historyPageSearchHint => 'トランザクションを検索...';

  @override
  String get notificationsSettingsPageTitle => '通知';

  @override
  String get notificationsSettingsPagePushTitle => 'プッシュ通知';

  @override
  String get notificationsSettingsPagePushDescription => 'トランザクションの送信と確認、接続されたアプリからの通知を受け取ります。';

  @override
  String get notificationsSettingsPageWalletsTitle => 'ウォレット';

  @override
  String get notificationsSettingsPageWalletsDescription => 'ウォレットからの通知';

  @override
  String get notificationsSettingsPageWalletPrefix => 'ウォレット';

  @override
  String get revealSecretPhraseTitle => '秘密フレーズを表示';

  @override
  String get revealSecretPhrasePasswordHint => 'パスワード';

  @override
  String get revealSecretPhraseInvalidPassword => '無効なパスワード、エラー:';

  @override
  String get revealSecretPhraseRevealAfter => 'シードフレーズは次の時間後に表示されます:';

  @override
  String get revealSecretPhraseSubmitButton => '送信';

  @override
  String get revealSecretPhraseDoneButton => '完了';

  @override
  String get revealSecretPhraseScamAlertTitle => '詐欺警告';

  @override
  String get revealSecretPhraseScamAlertDescription => '秘密フレーズを他人と共有したり、いかなるウェブサイトにも入力したりしないでください。';

  @override
  String get cipherSettingsPageTitle => '暗号化設定';

  @override
  String get cipherSettingsPageAdvancedButton => '詳細';

  @override
  String get cipherSettingsPageStandardTitle => '標準暗号化';

  @override
  String get cipherSettingsPageStandardSubtitle => 'AES-256 + KUZNECHIK-GOST';

  @override
  String get cipherSettingsPageStandardDescription => 'AES-256とGOST標準KUZNECHIKによる基本的な暗号化。';

  @override
  String get cipherSettingsPageHybridTitle => 'ハイブリッド暗号化';

  @override
  String get cipherSettingsPageHybridSubtitle => 'CYBER + KUZNECHIK-GOST';

  @override
  String get cipherSettingsPageHybridDescription => 'CYBERとKUZNECHIK-GOSTアルゴリズムを組み合わせたハイブリッド暗号化。';

  @override
  String get cipherSettingsPageQuantumTitle => '量子耐性';

  @override
  String get cipherSettingsPageQuantumSubtitle => 'CYBER + KUZNECHIK + NTRUP1277';

  @override
  String get cipherSettingsPageQuantumDescription => 'NTRUP1277による高度な量子耐性暗号化。';

  @override
  String get cipherSettingsPageQuantumWarning => '量子耐性暗号化はパフォーマンスに影響を与える可能性があります';

  @override
  String get cipherSettingsPageConfirmButton => '確認';

  @override
  String get secretPhraseVerifyPageTitle => '秘密を確認';

  @override
  String get secretPhraseVerifyPageSkipButton => 'スキップ';

  @override
  String get secretPhraseVerifyPageSubtitle => 'Bip39秘密を確認';

  @override
  String get secretPhraseVerifyPageNextButton => '次へ';

  @override
  String get restoreSecretPhrasePageTitle => 'ウォレットを復元';

  @override
  String get restoreSecretPhrasePageRestoreButton => '復元';

  @override
  String get checksumValidationFailed => 'チェックサム検証に失敗しました';

  @override
  String get proceedDespiteInvalidChecksum => 'チェックサムエラーがありますが続行しますか？';

  @override
  String get settingsPageTitle => '設定';

  @override
  String get settingsPageZilliqaLegacy => 'Zilliqaレガシー';

  @override
  String get settingsPageCurrency => '通貨';

  @override
  String get settingsPageAppearance => '外観';

  @override
  String get settingsPageNotifications => '通知';

  @override
  String get settingsPageAddressBook => 'アドレス帳';

  @override
  String get settingsPageSecurityPrivacy => 'セキュリティとプライバシー';

  @override
  String get settingsPageNetworks => 'ネットワーク';

  @override
  String get settingsPageLanguage => '言語';

  @override
  String get settingsPageBrowser => 'ブラウザ';

  @override
  String get settingsPageTelegram => 'Telegram';

  @override
  String get settingsPageTwitter => 'Twitter';

  @override
  String get settingsPageGitHub => 'GitHub';

  @override
  String get settingsPageAbout => 'アプリについて';

  @override
  String get passwordSetupPageTitle => 'パスワード設定';

  @override
  String get passwordSetupPageSubtitle => 'パスワードを作成';

  @override
  String get passwordSetupPageWalletNameHint => 'ウォレット名';

  @override
  String get passwordSetupPagePasswordHint => 'パスワード';

  @override
  String get passwordSetupPageConfirmPasswordHint => 'パスワードを確認';

  @override
  String get passwordSetupPageEmptyWalletNameError => 'ウォレット名は空にできません';

  @override
  String get passwordSetupPageLongWalletNameError => 'ウォレット名が長すぎます';

  @override
  String get passwordSetupPageShortPasswordError => 'パスワードは8文字以上である必要があります';

  @override
  String get passwordSetupPageMismatchPasswordError => 'パスワードが一致しません';

  @override
  String get passwordSetupPageLegacyLabel => 'レガシー';

  @override
  String get passwordSetupPageCreateButton => 'パスワードを作成';

  @override
  String get passwordSetupPageAuthReason => 'クイックアクセスを有効にするために認証してください';

  @override
  String get passwordSetupPageSeedType => 'シード';

  @override
  String get passwordSetupPageKeyType => 'キー';

  @override
  String get passwordSetupPageUniversalNetwork => 'ユニバーサル';

  @override
  String get browserSettingsTitle => 'ブラウザ設定';

  @override
  String get browserSettingsBrowserOptions => 'ブラウザオプション';

  @override
  String get browserSettingsSearchEngine => '検索エンジン';

  @override
  String get browserSettingsSearchEngineDescription => 'デフォルトの検索エンジンを設定';

  @override
  String get browserSettingsSearchEngineTitle => '検索エンジン';

  @override
  String get browserSettingsContentBlocking => 'コンテンツブロック';

  @override
  String get browserSettingsContentBlockingDescription => 'コンテンツブロック設定を構成';

  @override
  String get browserSettingsContentBlockingTitle => 'コンテンツブロック';

  @override
  String get browserSettingsPrivacySecurity => 'プライバシーとセキュリティ';

  @override
  String get browserSettingsCookies => 'クッキー';

  @override
  String get browserSettingsCookiesDescription => 'ウェブサイトによるクッキーの保存と読み取りを許可';

  @override
  String get browserSettingsDoNotTrack => '追跡拒否';

  @override
  String get browserSettingsDoNotTrackDescription => 'ブラウジングを追跡しないようウェブサイトに要求';

  @override
  String get browserSettingsIncognitoMode => 'シークレットモード';

  @override
  String get browserSettingsIncognitoModeDescription => '履歴やクッキーを保存せずにブラウズ';

  @override
  String get browserSettingsPerformance => 'パフォーマンス';

  @override
  String get browserSettingsCache => 'キャッシュ';

  @override
  String get browserSettingsClearData => 'データを消去';

  @override
  String get browserSettingsClear => '消去';

  @override
  String get browserSettingsClearCookies => 'Cookieを消去';

  @override
  String get browserSettingsClearCookiesDescription => 'ウェブサイトによって保存されたすべてのCookieを削除';

  @override
  String get browserSettingsClearCache => 'キャッシュを消去';

  @override
  String get browserSettingsClearCacheDescription => 'ブラウジング中に保存された一時ファイルや画像を削除';

  @override
  String get browserSettingsClearLocalStorage => 'ローカルストレージを消去';

  @override
  String get browserSettingsClearLocalStorageDescription => 'デバイスに保存されているウェブサイトのデータを削除';

  @override
  String get browserSettingsCacheDescription => 'より速い読み込みのためにウェブサイトのデータを保存';

  @override
  String get genWalletOptionsTitle => 'ウォレットを生成';

  @override
  String get genWalletOptionsBIP39Title => 'BIP39';

  @override
  String get genWalletOptionsBIP39Subtitle => 'ニーモニックフレーズを生成';

  @override
  String get genWalletOptionsSLIP0039Title => 'SLIP-0039';

  @override
  String get genWalletOptionsSLIP0039Subtitle => '共有付きニーモニックフレーズを生成';

  @override
  String get genWalletOptionsPrivateKeyTitle => 'プライベートキー';

  @override
  String get genWalletOptionsPrivateKeySubtitle => '1つのプライベートキーのみを生成';

  @override
  String get addWalletOptionsTitle => 'ウォレットを追加';

  @override
  String get addWalletOptionsNewWalletTitle => '新しいウォレット';

  @override
  String get addWalletOptionsNewWalletSubtitle => '新しいウォレットを作成';

  @override
  String get addWalletOptionsExistingWalletTitle => '既存のウォレット';

  @override
  String get addWalletOptionsExistingWalletSubtitle => '24の秘密回復単語でウォレットをインポート';

  @override
  String get addWalletOptionsPairWithLedgerTitle => 'Ledgerとペアリング';

  @override
  String get addWalletOptionsPairWithLedgerSubtitle => 'ハードウェアモジュール、Bluetooth';

  @override
  String get addWalletOptionsOtherOptions => 'その他のオプション';

  @override
  String get addWalletOptionsWatchAccountTitle => 'アカウントを監視';

  @override
  String get addWalletOptionsWatchAccountSubtitle => '回復フレーズなしでウォレットの活動をモニター';

  @override
  String get currencyConversionTitle => '主要通貨';

  @override
  String get currencyConversionSearchHint => '通貨を検索...';

  @override
  String get currencyConversionEngineTitle => '通貨エンジン';

  @override
  String get currencyConversionEngineDescription => '通貨レートを取得するエンジン';

  @override
  String get currencyConversionEngineSelectorTitle => '通貨エンジンを選択';

  @override
  String get currencyConversionEngineNone => 'なし';

  @override
  String get currencyConversionEngineNoneSubtitle => 'エンジンが選択されていません';

  @override
  String get currencyConversionEngineCoingecko => 'Coingecko';

  @override
  String get currencyConversionEngineCoingeckoSubtitle => 'Coingeckoからレートを取得';

  @override
  String get restoreWalletOptionsTitle => 'ウォレットを復元';

  @override
  String get restoreWalletOptionsBIP39Title => 'BIP39';

  @override
  String get restoreWalletOptionsBIP39Subtitle => 'ニーモニックフレーズで復元';

  @override
  String get restoreWalletOptionsSLIP0039Title => 'SLIP-0039';

  @override
  String get restoreWalletOptionsSLIP0039Subtitle => '共有ニーモニックフレーズで復元';

  @override
  String get restoreWalletOptionsPrivateKeyTitle => 'プライベートキー';

  @override
  String get restoreWalletOptionsPrivateKeySubtitle => 'プライベートキーで復元';

  @override
  String get restoreWalletOptionsKeyStoreTitle => 'キーストアファイル';

  @override
  String get restoreWalletOptionsKeyStoreSubtitle => 'パスワードで暗号化されたバックアップファイルを使用してウォレットを復元';

  @override
  String get restoreWalletOptionsQRCodeTitle => 'QRコード';

  @override
  String get restoreWalletOptionsQRCodeSubtitle => 'QRコードスキャンでウォレットを復元';

  @override
  String get argonSettingsModalContentLowMemoryTitle => '低メモリ';

  @override
  String get argonSettingsModalContentLowMemorySubtitle => '64KB RAM、3反復';

  @override
  String get argonSettingsModalContentLowMemoryDescription => '最小メモリ使用量、低スペックデバイスに適しています。';

  @override
  String get argonSettingsModalContentOwaspTitle => 'OWASPデフォルト';

  @override
  String get argonSettingsModalContentOwaspSubtitle => '6.5MB RAM、2反復';

  @override
  String get argonSettingsModalContentOwaspDescription => '一般使用向けにOWASPが推奨。';

  @override
  String get argonSettingsModalContentSecureTitle => '安全';

  @override
  String get argonSettingsModalContentSecureSubtitle => '256MB RAM、4反復';

  @override
  String get argonSettingsModalContentSecureDescription => 'メモリと反復回数を増やした高セキュリティ。';

  @override
  String get argonSettingsModalContentSecretHint => '秘密を入力（任意）';

  @override
  String get argonSettingsModalContentConfirmButton => '確認';

  @override
  String get confirmTransactionContentPasswordHint => 'パスワード';

  @override
  String get confirmTransactionContentUnableToConfirm => '確認できません';

  @override
  String get confirmTransactionContentConfirm => '確認';

  @override
  String get confirmTransactionContentInsufficientBalance => '残高不足';

  @override
  String get confirmTransactionContentNoActiveAccount => 'アクティブなアカウントがありません';

  @override
  String get confirmTransactionContentFailedLoadTransfer => '送金詳細の読み込みに失敗';

  @override
  String get confirmTransactionEditGasButtonText => '編集';

  @override
  String get authReason => '認証してください';

  @override
  String get addChainModalContentWarning => 'ネットワーク詐欺とセキュリティリスクに注意してください。';

  @override
  String get addChainModalContentApprove => '承認';

  @override
  String get addChainModalContentDetails => '詳細';

  @override
  String get addChainModalContentNetworkName => 'ネットワーク名:';

  @override
  String get addChainModalContentCurrencySymbol => '通貨記号:';

  @override
  String get addChainModalContentChainId => 'チェーンID:';

  @override
  String get addChainModalContentBlockExplorer => 'ブロックエクスプローラー:';

  @override
  String get addAddressModalTitle => '連絡先を追加';

  @override
  String get addAddressModalDescription => 'アドレス帳に追加する連絡先名とウォレットアドレスを入力してください。';

  @override
  String get addAddressModalNameHint => '名前';

  @override
  String get addAddressModalAddressHint => 'ウォレットアドレス';

  @override
  String get addAddressModalNameEmptyError => '名前は空にできません';

  @override
  String get addAddressModalAddressEmptyError => 'アドレスは空にできません';

  @override
  String get addAddressModalButton => '連絡先を追加';

  @override
  String get tokenSelectModalContentSearchHint => '検索';

  @override
  String get signMessageModalContentAuthReason => 'メッセージに署名するために認証してください';

  @override
  String signMessageModalContentFailedToSign(Object error) {
    return '署名に失敗しました: $error';
  }

  @override
  String get signMessageModalContentTitle => 'メッセージに署名';

  @override
  String get signMessageModalContentDescription => 'ウォレットを使用して以下のメッセージを確認し、署名してください。';

  @override
  String get signMessageModalContentDomain => 'ドメイン：';

  @override
  String get signMessageModalContentChainId => 'チェーンID：';

  @override
  String get signMessageModalContentContract => 'コントラクト：';

  @override
  String get signMessageModalContentType => 'タイプ：';

  @override
  String get signMessageModalContentNoData => 'データなし';

  @override
  String get signMessageModalContentPasswordHint => 'パスワード';

  @override
  String get signMessageModalContentProcessing => '処理中...';

  @override
  String get signMessageModalContentSign => 'メッセージに署名';

  @override
  String get signMessageModalContentScanning => 'Ledgerデバイスをスキャン中...';

  @override
  String get signMessageModalContentNoLedgerDevices => 'Ledgerデバイスが見つかりませんでした';

  @override
  String get signMessageModalContentWalletNotSelected => 'ウォレットが選択されていません';

  @override
  String get signMessageModalContentLedgerNotSelected => 'Ledgerデバイスが選択されていません';

  @override
  String signMessageModalContentFailedToScanLedger(Object error) {
    return 'Ledgerデバイスのスキャンに失敗しました: $error';
  }

  @override
  String signMessageModalContentFailedToSignMessage(Object error) {
    return 'メッセージの署名に失敗しました: $error';
  }

  @override
  String get signMessageModalContentBluetoothOff => 'Bluetoothがオフになっています。Ledgerデバイスのスキャンには有効にしてください。';

  @override
  String get deleteWalletModalTitle => 'ウォレットを削除';

  @override
  String get deleteWalletModalWarning => '警告：この操作は元に戻せません。ウォレットは秘密フレーズを使用してのみ復元できます。アクセスできない場合、このアカウントに関連するすべての資金が永久に失われます。';

  @override
  String get deleteWalletModalSecretPhraseWarning => '続行する前に、秘密フレーズにアクセスできることを確認してください。';

  @override
  String get deleteWalletModalPasswordHint => 'パスワードを入力';

  @override
  String get deleteWalletModalSubmit => '送信';

  @override
  String get manageTokensModalContentSearchHint => '検索';

  @override
  String get addressSelectModalContentTitle => 'アドレスを選択';

  @override
  String get addressSelectModalContentSearchHint => '検索 / アドレス / ENS';

  @override
  String get addressSelectModalContentUnknown => '不明';

  @override
  String get addressSelectModalContentMyAccounts => 'マイアカウント';

  @override
  String get addressSelectModalContentAddressBook => 'アドレス帳';

  @override
  String get addressSelectModalContentHistory => '履歴';

  @override
  String get addressSelectModalContentSender => '送信者';

  @override
  String get changePasswordModalTitle => 'パスワード変更';

  @override
  String get changePasswordModalDescription => '現在のパスワードを入力し、ウォレットのセキュリティを更新するための新しいパスワードを選択してください。';

  @override
  String get changePasswordModalCurrentPasswordHint => '現在のパスワード';

  @override
  String get changePasswordModalNewPasswordHint => '新しいパスワード';

  @override
  String get changePasswordModalConfirmPasswordHint => '新しいパスワードを確認';

  @override
  String get changePasswordModalCurrentPasswordEmptyError => '現在のパスワードは空にできません';

  @override
  String get changePasswordModalPasswordLengthError => 'パスワードは6文字以上である必要があります';

  @override
  String get changePasswordModalPasswordsMismatchError => 'パスワードが一致しません';

  @override
  String get changePasswordModalButton => 'パスワード変更';

  @override
  String get confirmPasswordModalTitle => 'パスワードを確認';

  @override
  String get confirmPasswordModalDescription => '続行するにはパスワードを入力してください。';

  @override
  String get confirmPasswordModalHint => 'パスワード';

  @override
  String get confirmPasswordModalEmptyError => 'パスワードは空にできません';

  @override
  String get confirmPasswordModalGenericError => 'エラー:';

  @override
  String get confirmPasswordModalButton => '確認';

  @override
  String get qrScannerModalContentTitle => 'スキャン';

  @override
  String get qrScannerModalContentCameraInitError => 'カメラ初期化エラー:';

  @override
  String get qrScannerModalContentTorchError => 'トーチの切り替えに失敗:';

  @override
  String get qrScannerModalContentOpenSettings => '設定を開く';

  @override
  String get chainInfoModalContentTokenTitle => 'ネットワークトークン';

  @override
  String get chainInfoModalContentNetworkInfoTitle => 'ネットワーク情報';

  @override
  String get chainInfoModalContentChainLabel => 'チェーン';

  @override
  String get chainInfoModalContentShortNameLabel => '略称';

  @override
  String get chainInfoModalContentChainIdLabel => 'チェーンID';

  @override
  String get chainInfoModalContentSlip44Label => 'Slip44';

  @override
  String get chainInfoModalContentChainIdsLabel => 'チェーンID群';

  @override
  String get chainInfoModalContentTestnetLabel => 'テストネット';

  @override
  String get chainInfoModalContentYes => 'はい';

  @override
  String get chainInfoModalContentNo => 'いいえ';

  @override
  String get chainInfoModalContentDiffBlockTimeLabel => 'ブロック時間差';

  @override
  String get chainInfoModalContentFallbackEnabledLabel => 'フォールバック有効';

  @override
  String get chainInfoModalContentDecimalsLabel => '小数点';

  @override
  String get chainInfoModalContentRpcNodesTitle => 'RPCノード';

  @override
  String get chainInfoModalContentExplorersTitle => 'エクスプローラー';

  @override
  String get chainInfoModalContentDeleteProviderTitle => 'ネットワークを削除';

  @override
  String get chainInfoModalContentSwipeToDelete => '削除';

  @override
  String get switchChainNetworkContentTitle => 'ネットワークを選択';

  @override
  String get switchChainNetworkContentButton => 'ネットワークを切り替え';

  @override
  String get switchChainNetworkContentTestnetLabel => 'テストネット';

  @override
  String get switchChainNetworkContentIdLabel => 'ID:';

  @override
  String get watchAssetModalContentTitle => '提案されたトークンを追加';

  @override
  String get watchAssetModalContentDescription => 'アプリによって提案された以下のトークンを確認して追加します。';

  @override
  String get watchAssetModalContentTokenLabel => 'トークン';

  @override
  String get watchAssetModalContentBalanceLabel => '残高';

  @override
  String get watchAssetModalContentLoadingButton => '残高...';

  @override
  String get watchAssetModalContentAddButton => '追加';

  @override
  String get connectedDappsModalSearchHint => 'DAppsを検索';

  @override
  String get connectedDappsModalNoDapps => '接続されたDAppsはありません';

  @override
  String dappListItemConnected(Object time) {
    return '$timeに接続';
  }

  @override
  String get dappListItemJustNow => 'たった今';

  @override
  String get secretRecoveryModalRevealPhraseTitle => '秘密回復フレーズを表示';

  @override
  String get secretRecoveryModalRevealPhraseDescription => 'ブラウザを変更したりコンピュータを移動する場合、アカウントにアクセスするにはこの秘密回復フレーズが必要です。安全で秘密の場所に保存してください。';

  @override
  String get secretRecoveryModalRevealPhraseButton => '表示';

  @override
  String get secretRecoveryModalShowKeysTitle => 'プライベートキーを表示';

  @override
  String get secretRecoveryModalShowKeysDescription => '警告：このキーを誰にも公開しないでください。プライベートキーを持つ人は、あなたのアカウントにある資産を盗むことができます。';

  @override
  String get secretRecoveryModalShowKeysButton => 'エクスポート';

  @override
  String get secretRecoveryModalKeystoreBackupTitle => 'キーストアバックアップ';

  @override
  String get secretRecoveryModalKeystoreBackupDescription => 'パスワードで保護された暗号化されたキーストアファイルに秘密鍵を保存します。これにより、ウォレットにさらなるセキュリティ層が提供されます。';

  @override
  String get secretRecoveryModalKeystoreBackupButton => 'キーストアバックアップを作成';

  @override
  String get backupConfirmationContentTitle => 'バックアップ確認';

  @override
  String get backupConfirmationWarning => '警告：シードフレーズを正確な順序で紛失または忘れた場合、資金は永久に失われます。シードフレーズを他人と共有しないでください。共有すると資金が盗まれる可能性があります。BIP39リカバリーは厳格であり、復元時の単語の間違いは資金の損失につながります。';

  @override
  String get backupConfirmationContentWrittenDown => 'すべてを書き留めました';

  @override
  String get backupConfirmationContentSafelyStored => 'バックアップを安全に保管しました';

  @override
  String get backupConfirmationContentWontLose => 'バックアップを失わないよう注意します';

  @override
  String get backupConfirmationContentNotShare => 'これらの単語を誰とも共有しないことを理解しています';

  @override
  String get counterMaxValueError => '最大値に達しました';

  @override
  String get counterMinValueError => '最小値に達しました';

  @override
  String get biometricSwitchFaceId => 'Face IDを有効にする';

  @override
  String get biometricSwitchFingerprint => '指紋認証を有効にする';

  @override
  String get biometricSwitchBiometric => '生体認証ログインを有効にする';

  @override
  String get biometricSwitchPinCode => 'デバイスPINを有効にする';

  @override
  String get gasFeeOptionLow => '低';

  @override
  String get gasFeeOptionMarket => '市場';

  @override
  String get gasFeeOptionAggressive => '積極的';

  @override
  String get gasDetailsEstimatedGas => '推定ガス:';

  @override
  String get gasDetailsGasPrice => 'ガス価格:';

  @override
  String get gasDetailsBaseFee => '基本料金:';

  @override
  String get gasDetailsPriorityFee => '優先料金:';

  @override
  String get gasDetailsMaxFee => '最大料金:';

  @override
  String get tokenTransferAmountUnknown => '不明';

  @override
  String get transactionDetailsModal_transaction => '取引';

  @override
  String get transactionDetailsModal_hash => 'ハッシュ';

  @override
  String get transactionDetailsModal_sig => '署名';

  @override
  String get transactionDetailsModal_timestamp => 'タイムスタンプ';

  @override
  String get transactionDetailsModal_blockNumber => 'ブロック番号';

  @override
  String get transactionDetailsModal_nonce => 'ナンス';

  @override
  String get transactionDetailsModal_addresses => 'アドレス';

  @override
  String get transactionDetailsModal_sender => '送信者';

  @override
  String get transactionDetailsModal_recipient => '受信者';

  @override
  String get transactionDetailsModal_contractAddress => 'コントラクトアドレス';

  @override
  String get transactionDetailsModal_network => 'ネットワーク';

  @override
  String get transactionDetailsModal_chainType => 'チェーンタイプ';

  @override
  String get transactionDetailsModal_networkName => 'ネットワーク';

  @override
  String get transactionDetailsModal_gasFees => 'ガスと手数料';

  @override
  String get transactionDetailsModal_fee => '手数料';

  @override
  String get transactionDetailsModal_gasUsed => '使用ガス';

  @override
  String get transactionDetailsModal_gasLimit => 'ガス制限';

  @override
  String get transactionDetailsModal_gasPrice => 'ガス価格';

  @override
  String get transactionDetailsModal_effectiveGasPrice => '有効ガス価格';

  @override
  String get transactionDetailsModal_blobGasUsed => 'ブロブガス使用量';

  @override
  String get transactionDetailsModal_blobGasPrice => 'ブロブガス価格';

  @override
  String get transactionDetailsModal_error => 'エラー';

  @override
  String get transactionDetailsModal_errorMessage => 'エラーメッセージ';

  @override
  String get amountSection_transfer => '送金';

  @override
  String get amountSection_pending => '保留中';

  @override
  String get amountSection_confirmed => '確認済み';

  @override
  String get amountSection_rejected => '拒否済み';

  @override
  String get appConnectModalContent_swipeToConnect => 'スワイプして接続';

  @override
  String get appConnectModalContent_noAccounts => 'アカウントがありません';

  @override
  String get browserActionMenuShare => '共有';

  @override
  String get browserActionMenuCopyLink => 'リンクをコピー';

  @override
  String get browserActionMenuClose => '閉じる';

  @override
  String get keystoreBackupTitle => 'キーストアバックアップ';

  @override
  String get keystoreBackupWarningTitle => 'キーストアファイルを安全に保管';

  @override
  String get keystoreBackupWarningMessage => 'キーストアファイルには暗号化された秘密鍵が含まれています。このファイルを安全な場所に保管し、誰とも共有しないでください。このファイルを復号化するには、作成したパスワードが必要です。';

  @override
  String get keystoreBackupConfirmPasswordHint => 'パスワードを確認';

  @override
  String get keystoreBackupCreateButton => 'バックアップを作成';

  @override
  String get keystoreBackupPasswordsDoNotMatch => 'パスワードが一致しません';

  @override
  String get keystoreBackupPasswordTooShort => 'パスワードは8文字以上である必要があります';

  @override
  String get keystoreBackupError => 'バックアップ作成エラー：';

  @override
  String get keystoreBackupShareButton => 'キーストアファイルを共有';

  @override
  String get keystoreBackupDoneButton => '完了';

  @override
  String get keystoreBackupSuccessTitle => 'バックアップの作成に成功';

  @override
  String get keystoreBackupSuccessMessage => 'キーストアファイルが作成されました。ファイルとパスワードの両方を安全に保管することを忘れないでください。';

  @override
  String get keystoreBackupSaveAsButton => 'ファイルとして保存';

  @override
  String get keystoreBackupSaveDialogTitle => 'キーストアファイルを保存';

  @override
  String get keystoreBackupSavedSuccess => 'キーストアファイルが正常に保存されました';

  @override
  String get keystoreBackupSaveFailed => 'キーストアファイルの保存に失敗しました';

  @override
  String get keystoreBackupTempLocation => '一時ファイルの場所';

  @override
  String get keystorePasswordHint => 'キーストアのパスワードを入力してください';

  @override
  String get keystoreRestoreButton => 'ウォレットを復元';

  @override
  String get keystoreRestoreExtError => '有効な.zpファイルを選択してください';

  @override
  String get keystoreRestoreNoFile => 'キーストアファイルが見つかりません';

  @override
  String get keystoreRestoreFilesTitle => 'キーストアファイル';

  @override
  String get editGasDialogTitle => 'ガスパラメータの編集';

  @override
  String get editGasDialogGasPrice => 'ガス価格';

  @override
  String get editGasDialogMaxPriorityFee => '最大優先手数料';

  @override
  String get editGasDialogGasLimit => 'ガスリミット';

  @override
  String get editGasDialogCancel => 'キャンセル';

  @override
  String get editGasDialogSave => '保存';

  @override
  String get editGasDialogInvalidGasValues => '無効なガス値です。入力を確認してください。';

  @override
  String get addLedgerAccountPageAppBarTitle => 'Ledgerアカウントを追加';

  @override
  String get addLedgerAccountPageGetAccountsButton => 'アカウントを取得';

  @override
  String get addLedgerAccountPageCreateButton => '作成';

  @override
  String get addLedgerAccountPageAddButton => '追加';

  @override
  String get addLedgerAccountPageScanningMessage => 'Ledgerデバイスをスキャン中...';

  @override
  String get addLedgerAccountPageNoDevicesMessage => 'Ledgerデバイスが見つかりません';

  @override
  String get addLedgerAccountPageBluetoothOffError => 'Bluetoothがオフになっています。Ledgerデバイスをスキャンするためにオンにしてください。';

  @override
  String get addLedgerAccountPageEmptyWalletNameError => 'ウォレット名は空にできません';

  @override
  String get addLedgerAccountPageWalletNameTooLongError => 'ウォレット名が長すぎます（最大24文字）';

  @override
  String addLedgerAccountPageFailedToScanError(Object error) {
    return 'Ledgerデバイスのスキャンに失敗しました：$error';
  }

  @override
  String get addLedgerAccountPageNetworkOrLedgerMissingError => 'ネットワークまたはLedgerデータが不足しています';

  @override
  String get addLedgerAccountPageNoAccountsSelectedError => 'アカウントが選択されていません';

  @override
  String get addLedgerAccountPageNoWalletSelectedError => 'ウォレットが選択されていません';

  @override
  String get transactionHistoryTitle => '取引履歴';

  @override
  String get transactionHistoryDescription => 'アドレス帳に取引履歴からのアドレスを表示します。';

  @override
  String get zilStakePageTitle => 'Zilliqa ステーキング';

  @override
  String get noStakingPoolsFound => 'ステーキングプールが見つかりません';

  @override
  String get aprSort => 'APR';

  @override
  String get commissionSort => '手数料';

  @override
  String get tvlSort => 'TVL';

  @override
  String get claimButton => '請求';

  @override
  String get stakeButton => 'ステーク';

  @override
  String get unstakeButton => 'アンステーク';

  @override
  String get aprLabel => 'APR';

  @override
  String get commissionLabel => '手数料';

  @override
  String get tvlLabel => 'TVL';

  @override
  String get lpStakingBadge => 'LP ステーキング';

  @override
  String get stakedAmount => 'ステーク済み';

  @override
  String get rewardsAvailable => '報酬';
}
