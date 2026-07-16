// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Bearby 钱包';

  @override
  String get initialPagerestoreZilPay => '恢复 ZilPay 1.0！';

  @override
  String get initialPagegetStarted => '开始使用';

  @override
  String get restoreRKStorageTitle => '将 ZilPay 1.0 迁移至 2.0';

  @override
  String get restoreRKStorageAccountsPrompt => '要迁移到 ZilPay 2.0 的账户。请输入密码。';

  @override
  String get restoreRKStoragePasswordHint => '密码';

  @override
  String get restoreRKStorageEnterPassword => '请输入密码';

  @override
  String get restoreRKStorageErrorPrefix => '错误：';

  @override
  String get restoreRKStorageRestoreButton => '恢复';

  @override
  String get restoreRKStorageSkipButton => '跳过';

  @override
  String get accountItemBalanceLabel => '余额：';

  @override
  String get sendTokenPageTitle => '发送';

  @override
  String get sendTokenPageSubmitButton => '发送';

  @override
  String get amountChipClear => '清除';

  @override
  String get amountChipMax => '最大';

  @override
  String get aboutPageTitle => '关于';

  @override
  String get aboutPageAppName => 'Bearby';

  @override
  String get aboutPageAppDescription => '您的安全区块链钱包';

  @override
  String get aboutPageAppInfoTitle => '应用程序信息';

  @override
  String get aboutPageVersionLabel => '版本';

  @override
  String get aboutPageBuildDateLabel => '构建日期';

  @override
  String get aboutPageBuildDateValue => '2025年3月10日';

  @override
  String get aboutPagePlatformLabel => '平台';

  @override
  String get aboutPageDeveloperTitle => '开发者';

  @override
  String get aboutPageAuthorLabel => '作者';

  @override
  String get aboutPageAuthorValue => 'Rinat (hicaru)';

  @override
  String get aboutPageWebsiteLabel => '网站';

  @override
  String get aboutPageWebsiteValue => 'https://bearby.io';

  @override
  String get aboutPageLegalTitle => '法律信息';

  @override
  String get aboutPagePrivacyPolicy => '隐私政策';

  @override
  String get aboutPageTermsOfService => '服务条款';

  @override
  String get aboutPageLicenses => '许可证';

  @override
  String get aboutPageLegalese => '© 2025 Bearby。保留所有权利。';

  @override
  String get languagePageTitle => '语言';

  @override
  String get secretKeyGeneratorPageTitle => '密钥';

  @override
  String get secretKeyGeneratorPagePrivateKey => '私钥';

  @override
  String get secretKeyGeneratorPagePublicKey => '公钥';

  @override
  String get secretKeyGeneratorPageBackupCheckbox => '我已备份私钥';

  @override
  String get secretKeyGeneratorPageNextButton => '下一步';

  @override
  String get walletPageWalletNameHint => '钱包名称';

  @override
  String get walletPagePreferencesTitle => '钱包设置';

  @override
  String get walletPageManageConnections => '管理连接';

  @override
  String get walletPageBackup => '备份';

  @override
  String get walletPageDeleteWallet => '删除钱包';

  @override
  String get walletPageBiometricReason => '启用生物识别认证';

  @override
  String get networkPageTitle => '';

  @override
  String get networkPageSearchHint => '搜索';

  @override
  String get networkPageAddError => '添加网络失败：';

  @override
  String get receivePageTitle => '接收';

  @override
  String receivePageWarning(Object chainName, Object tokenSymbol) {
    return '仅向此地址发送 $chainName($tokenSymbol) 资产。其他资产将永久丢失。';
  }

  @override
  String get receivePageBitcoinAddressRotationWarning => 'Bitcoin 会使用地址轮换来保护隐私。此收款地址使用后可能会变化；之前的地址仍对该钱包有效。';

  @override
  String get receivePageAccountNameHint => '账户名称';

  @override
  String get receivePageAmountDialogTitle => '输入金额';

  @override
  String get receivePageAmountDialogHint => '0.0';

  @override
  String get receivePageAmountDialogCancel => '取消';

  @override
  String get receivePageAmountDialogConfirm => '确认';

  @override
  String get btcAddressesModalTitle => 'Bitcoin 地址';

  @override
  String get btcAddressFormatLegacy => '传统 (P2PKH)';

  @override
  String get btcAddressFormatNestedSegwit => '嵌套 SegWit (P2SH)';

  @override
  String get btcAddressFormatSegwit => 'SegWit (P2WPKH)';

  @override
  String get btcAddressFormatTaproot => 'Taproot (P2TR)';

  @override
  String btcAddressFormatUnknown(Object formatByte) {
    return '未知 ($formatByte)';
  }

  @override
  String get btcAddressesModalCurrent => '当前';

  @override
  String get btcAddressesModalUnused => '未使用';

  @override
  String get btcAddressesModalUsed => '已使用';

  @override
  String get btcAddressesModalEmpty => '暂无地址';

  @override
  String btcAddressesModalTxCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 笔交易',
    );
    return '$_temp0';
  }

  @override
  String get securityPageTitle => '安全';

  @override
  String get securityPageNetworkPrivacy => '网络隐私';

  @override
  String get securityPageEnsDomains => '在地址栏中显示 ENS 域名';

  @override
  String get securityPageEnsDescription => '请注意，使用此功能会将您的 IP 地址暴露给第三方 IPFS 服务。';

  @override
  String get securityPageIpfsGateway => 'IPFS 网关';

  @override
  String get securityPageIpfsDescription => 'Bearby 使用第三方服务来显示存储在 IPFS 上的 NFT 图像，显示与浏览器地址栏中输入的 ENS（ZNS）地址相关的信息，以及获取不同代币的图标。当您使用这些服务时，您的 IP 地址可能会暴露给这些服务。';

  @override
  String get securityPageTokensFetcherTitle => '令牌获取器';

  @override
  String get securityPageTokensFetcherDescription => '安全页面上的令牌获取器设置。如果启用，将自动从服务器获取令牌并可添加。';

  @override
  String get securityPageNodeRanking => '节点排名';

  @override
  String get securityPageNodeDescription => '向 Bearby 服务器发出请求以获取最佳节点';

  @override
  String get securityPageClearData => '清除数据';

  @override
  String get securityPageClearImageCache => '清除图像缓存';

  @override
  String get securityPageClearImageCacheDescription => '从临时存储中删除所有缓存的图像';

  @override
  String get secretPhraseGeneratorPageTitle => '新钱包';

  @override
  String get secretPhraseGeneratorPageBackupCheckbox => '我已备份助记词';

  @override
  String get secretPhraseGeneratorPageNextButton => '下一步';

  @override
  String get homePageErrorTitle => '无信号';

  @override
  String get homePageReceiveButton => '接收';

  @override
  String get homePageSendButton => '发送';

  @override
  String get homePageExchangeButton => '兑换';

  @override
  String get exchangePageTitle => '兑换';

  @override
  String get exchangePagePay => '支付';

  @override
  String get exchangePageGet => '获得';

  @override
  String get exchangePageRecipientTitle => 'Select recipient';

  @override
  String get exchangePageConfirm => '确认';

  @override
  String get exchangePageComingSoon => '即将';

  @override
  String get exchangePageNoAssets => '此网络上没有可兑换的资产';

  @override
  String get exchangePageTabSwap => '兑换';

  @override
  String get exchangePageTabLimit => '限价';

  @override
  String get exchangePageTabBuySell => '买卖';

  @override
  String get whitebirdOrdersTitle => '未完成订单';

  @override
  String get whitebirdOrdersEmpty => '没有未完成的WhiteBird订单';

  @override
  String get whitebirdOrdersComplete => '完成支付';

  @override
  String get whitebirdOrdersCancel => '取消订单';

  @override
  String get whitebirdOrdersExpires => '到期';

  @override
  String get whitebirdOrdersWrongNetwork => '请切换到订单所在网络以完成支付';

  @override
  String get exchangeSettingsPriceProtection => '价格保护';

  @override
  String get exchangeSettingsReset => '重置';

  @override
  String get exchangeSettingsSave => '保存';

  @override
  String get exchangeConfirmBest => '最佳';

  @override
  String get exchangeConfirmGasNone => '—';

  @override
  String exchangeConfirmAfterGas(String amount) {
    return '≈ $amount';
  }

  @override
  String get exchangeConfirmSlippage => '滑点';

  @override
  String get exchangeConfirmRecipient => '接收方';

  @override
  String get exchangeConfirmSwipe => '滑动以交换';

  @override
  String get exchangeConfirmUnable => '无法确认';

  @override
  String get exchangeConfirmPassword => '密码';

  @override
  String get exchangeConfirmNoAccount => '没有活动账户';

  @override
  String get exchangeConfirmNoQuote => 'No quote available';

  @override
  String get exchangeConfirmStepApprove => '授权代币';

  @override
  String get exchangeConfirmStepPermit => '签署许可 (EIP-712)';

  @override
  String get exchangeConfirmWrap => '包装';

  @override
  String get exchangeConfirmUnwrap => '解包';

  @override
  String get exchangeConfirmHintApprove => '请在 Ledger 上确认授权…';

  @override
  String get exchangeConfirmHintPermit => '请在 Ledger 上确认许可…';

  @override
  String get exchangeConfirmHintSwap => '请在 Ledger 上确认交换…';

  @override
  String get exchangeConfirmHintPreparing => '准备中…';

  @override
  String exchangeHistoryApprove(String symbol) {
    return '授权 $symbol';
  }

  @override
  String exchangeHistoryPermit(String provider) {
    return 'Permit2 · $provider';
  }

  @override
  String get revealSecretKeyTitle => '显示私钥';

  @override
  String get revealSecretKeyPasswordHint => '密码';

  @override
  String get revealSecretKeyInvalidPassword => '密码无效，错误：';

  @override
  String get revealSecretKeySubmitButton => '提交';

  @override
  String get revealSecretKeyDoneButton => '完成';

  @override
  String get revealSecretKeyScamAlertTitle => '诈骗警告';

  @override
  String get revealSecretKeyScamAlertMessage => '绝不与任何人分享您的私钥。绝不在任何网站上输入。';

  @override
  String get revealSecretKeySecurityTimer => '安全计时器';

  @override
  String get revealSecretKeyRevealAfter => '您的私钥将在以下时间后显示:';

  @override
  String get setupNetworkSettingsPageSearchHint => '搜索';

  @override
  String get setupNetworkSettingsPageNoNetworks => '没有可用的网络';

  @override
  String setupNetworkSettingsPageNoResults(Object searchQuery) {
    return '未找到与\"$searchQuery\"匹配的网络';
  }

  @override
  String get setupNetworkSettingsPageNextButton => '下一步';

  @override
  String get setupNetworkSettingsPageChainIdLabel => '链 ID：';

  @override
  String get setupNetworkSettingsPageTokenLabel => '代币：';

  @override
  String get setupNetworkSettingsPageExplorerLabel => '浏览器：';

  @override
  String get appearanceSettingsPageTitle => '外观设置';

  @override
  String get appearanceSettingsPageCompactNumbersTitle => '简洁数字';

  @override
  String get appearanceSettingsPageCompactNumbersDescription => '启用后显示简短数字（例如，20K 而不是 20,000）。';

  @override
  String get appearanceSettingsPageDeviceSettingsTitle => '设备设置';

  @override
  String get appearanceSettingsPageDeviceSettingsSubtitle => '系统默认';

  @override
  String get appearanceSettingsPageDeviceSettingsDescription => '默认使用您设备的外观。您的钱包主题将根据系统设置自动调整。';

  @override
  String get appearanceSettingsPageDarkModeTitle => '深色模式';

  @override
  String get appearanceSettingsPageDarkModeSubtitle => '始终深色';

  @override
  String get appearanceSettingsPageDarkModeDescription => '始终启用深色主题，无论设备设置如何。';

  @override
  String get appearanceSettingsPageLightModeTitle => '浅色模式';

  @override
  String get appearanceSettingsPageLightModeSubtitle => '始终浅色';

  @override
  String get appearanceSettingsPageLightModeDescription => '始终启用浅色主题，无论设备设置如何。';

  @override
  String get loginPageBiometricReason => '请进行认证';

  @override
  String loginPageWalletTitle(Object index) {
    return '钱包 $index';
  }

  @override
  String get loginPagePasswordHint => '密码';

  @override
  String get loginPageUnlockButton => '解锁';

  @override
  String get loginPageWelcomeBack => '欢迎回来';

  @override
  String get secretKeyRestorePageTitle => '恢复私钥';

  @override
  String get secretKeyRestorePageHint => '私钥';

  @override
  String get secretKeyRestorePageInvalidFormat => '无效的私钥格式';

  @override
  String get secretKeyRestorePageKeyTitle => '私钥';

  @override
  String get secretKeyRestorePageBackupLabel => '我已备份我的私钥';

  @override
  String get secretKeyRestorePageNextButton => '下一步';

  @override
  String addAccountPageDefaultName(Object index) {
    return '账户 $index';
  }

  @override
  String get addAccountPageNameHint => '账户名称';

  @override
  String get addAccountPageBip39Index => 'BIP39 索引';

  @override
  String get addAccountPagePasswordHint => '密码';

  @override
  String get addAccountPageZilliqaLegacy => 'Zilliqa 传统';

  @override
  String get addAccountPageBiometricReason => '认证以创建新账户';

  @override
  String addAccountPageBiometricError(Object error) {
    return '生物识别认证失败：$error';
  }

  @override
  String addAccountPageIndexExists(Object index) {
    return '索引为 $index 的账户已存在';
  }

  @override
  String get addAccountPageBiometricFailed => '生物识别认证失败';

  @override
  String addAccountPageCreateFailed(Object error) {
    return '创建账户失败：$error';
  }

  @override
  String get addAccountPageTitle => '添加账户';

  @override
  String get addAccountPageCreateButton => '创建';

  @override
  String get addressBookPageTitle => '地址簿';

  @override
  String get addressBookPageEmptyMessage => '您的联系人及其钱包地址将\n在此处显示。';

  @override
  String get addressBookPageDeleteConfirmationTitle => '删除联系人';

  @override
  String addressBookPageDeleteConfirmationMessage(String contactName) {
    return '您确定要从地址簿中删除$contactName吗？';
  }

  @override
  String addressBookPageDeleteTooltip(String contactName) {
    return '删除$contactName';
  }

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String browserPageSearchHint(Object engine) {
    return '使用 $engine 搜索或输入地址';
  }

  @override
  String get browserPageNoConnectedApps => '无已连接的应用';

  @override
  String get historyPageTitle => '交易历史';

  @override
  String get historyPageNoTransactions => '暂无交易';

  @override
  String get historyPageSearchHint => '搜索交易...';

  @override
  String get historyItemReceived => '收到';

  @override
  String get historyItemSent => '发送';

  @override
  String get notificationsSettingsPageTitle => '通知';

  @override
  String get notificationsSettingsPagePushTitle => '推送通知';

  @override
  String get notificationsSettingsPagePushDescription => '在交易发送和确认时获取通知，以及来自已连接应用的通知。';

  @override
  String get notificationsSettingsPageWalletsTitle => '钱包';

  @override
  String get notificationsSettingsPageWalletsDescription => '来自钱包的通知';

  @override
  String get notificationsSettingsPageWalletPrefix => '钱包';

  @override
  String get revealSecretPhraseTitle => '显示助记词';

  @override
  String get revealSecretPhrasePasswordHint => '密码';

  @override
  String get revealSecretPhraseInvalidPassword => '密码无效，错误：';

  @override
  String get revealSecretPhraseRevealAfter => '您的助记词将在以下时间后显示:';

  @override
  String get revealSecretPhraseSubmitButton => '提交';

  @override
  String get revealSecretPhraseDoneButton => '完成';

  @override
  String get revealSecretPhraseScamAlertTitle => '诈骗警告';

  @override
  String get revealSecretPhraseScamAlertDescription => '绝不与任何人分享您的助记词。绝不在任何网站上输入。';

  @override
  String get cipherSettingsPageTitle => '加密设置';

  @override
  String get cipherSettingsPageAdvancedButton => '高级';

  @override
  String get cipherSettingsPageStandardTitle => '标准加密';

  @override
  String get cipherSettingsPageStandardSubtitle => 'AES-256 + KUZNECHIK-GOST';

  @override
  String get cipherSettingsPageStandardDescription => '使用 AES-256 和 GOST 标准 KUZNECHIK 的基本加密。';

  @override
  String get cipherSettingsPageHybridTitle => '混合加密';

  @override
  String get cipherSettingsPageHybridSubtitle => 'CYBER + KUZNECHIK-GOST';

  @override
  String get cipherSettingsPageHybridDescription => '结合 CYBER 和 KUZNECHIK-GOST 算法的混合加密。';

  @override
  String get cipherSettingsPageQuantumTitle => '抗量子';

  @override
  String get cipherSettingsPageQuantumSubtitle => 'CYBER + KUZNECHIK + NTRUP1277';

  @override
  String get cipherSettingsPageQuantumDescription => '使用 NTRUP1277 的高级抗量子加密。';

  @override
  String get cipherSettingsPageQuantumWarning => '抗量子加密可能影响性能';

  @override
  String get cipherSettingsPageConfirmButton => '确认';

  @override
  String get secretPhraseVerifyPageTitle => '验证密钥';

  @override
  String get secretPhraseVerifyPageSubtitle => '验证 Bip39 密钥';

  @override
  String get secretPhraseVerifyPageNextButton => '下一步';

  @override
  String get restoreSecretPhrasePageRestoreButton => '恢复';

  @override
  String get checksumValidationFailed => '校验和验证失败';

  @override
  String get proceedDespiteInvalidChecksum => '尽管校验和错误仍继续？';

  @override
  String get settingsPageTitle => '设置';

  @override
  String get settingsPageZilliqaLegacy => 'Zilliqa 传统';

  @override
  String get settingsPageCurrency => '货币';

  @override
  String get settingsPageAppearance => '外观';

  @override
  String get settingsPageNotifications => '通知';

  @override
  String get settingsPageAddressBook => '地址簿';

  @override
  String get settingsPageSecurityPrivacy => '安全与隐私';

  @override
  String get settingsPageNetworks => '网络';

  @override
  String get settingsPageLanguage => '语言';

  @override
  String get settingsPageBrowser => '浏览器';

  @override
  String get settingsPageTelegram => 'Telegram';

  @override
  String get settingsPageTwitter => 'X';

  @override
  String get settingsPageGitHub => 'GitHub';

  @override
  String get settingsPageEmail => '电子邮件';

  @override
  String get settingsPageAbout => '关于';

  @override
  String get passwordSetupPageSubtitle => '创建密码';

  @override
  String get passwordSetupPageWalletNameHint => '钱包名称';

  @override
  String get passwordSetupPagePasswordHint => '密码';

  @override
  String get passwordSetupPageConfirmPasswordHint => '确认密码';

  @override
  String get passwordSetupPageEmptyWalletNameError => '钱包名称不能为空';

  @override
  String get passwordSetupPageLongWalletNameError => '钱包名称过长';

  @override
  String get passwordSetupPageShortPasswordError => '密码至少需要 8 个字符';

  @override
  String get passwordSetupPageMismatchPasswordError => '密码不匹配';

  @override
  String get passwordSetupPageLegacyLabel => '传统';

  @override
  String get passwordSetupPageCreateButton => '创建密码';

  @override
  String get passwordSetupPageAuthReason => '请认证以启用快速访问';

  @override
  String get passwordSetupPageSeedType => '种子';

  @override
  String get passwordSetupPageKeyType => '密钥';

  @override
  String get passwordSetupPageUniversalNetwork => '通用';

  @override
  String get browserSettingsTitle => '浏览器设置';

  @override
  String get browserSettingsBrowserOptions => '浏览器选项';

  @override
  String get browserSettingsSearchEngine => '搜索引擎';

  @override
  String get browserSettingsSearchEngineDescription => '配置您的默认搜索引擎';

  @override
  String get browserSettingsSearchEngineTitle => '搜索引擎';

  @override
  String get browserSettingsContentBlocking => '内容拦截';

  @override
  String get browserSettingsContentBlockingDescription => '配置内容拦截设置';

  @override
  String get browserSettingsContentBlockingTitle => '内容拦截';

  @override
  String get browserSettingsPrivacySecurity => '隐私与安全';

  @override
  String get browserSettingsCookies => 'Cookie';

  @override
  String get browserSettingsCookiesDescription => '允许网站保存和读取 cookie';

  @override
  String get browserSettingsDoNotTrack => '请勿跟踪';

  @override
  String get browserSettingsDoNotTrackDescription => '请求网站不要跟踪您的浏览';

  @override
  String get browserSettingsIncognitoMode => '隐身模式';

  @override
  String get browserSettingsIncognitoModeDescription => '浏览时不保存历史记录或 cookie';

  @override
  String get browserSettingsPerformance => '性能';

  @override
  String get browserSettingsCache => '缓存';

  @override
  String get browserSettingsClearData => '清除数据';

  @override
  String get browserSettingsClear => '清除';

  @override
  String get browserSettingsClearCookies => '清除 Cookie';

  @override
  String get browserSettingsClearCookiesDescription => '删除网站存储的所有 cookie';

  @override
  String get browserSettingsClearCache => '清除缓存';

  @override
  String get browserSettingsClearCacheDescription => '删除浏览时存储的临时文件和图像';

  @override
  String get browserSettingsClearLocalStorage => '清除本地存储';

  @override
  String get browserSettingsClearLocalStorageDescription => '删除本地设备上存储的网站数据';

  @override
  String get browserSettingsCacheDescription => '存储网站数据以加快加载速度';

  @override
  String get genWalletOptionsTitle => '生成钱包';

  @override
  String get genWalletOptionsBIP39Title => 'BIP39';

  @override
  String get genWalletOptionsBIP39Subtitle => '生成助记词';

  @override
  String get genWalletOptionsPrivateKeyTitle => '私钥';

  @override
  String get genWalletOptionsPrivateKeySubtitle => '仅生成一个私钥';

  @override
  String get addWalletOptionsTitle => '添加钱包';

  @override
  String get addWalletOptionsNewWalletTitle => '新钱包';

  @override
  String get addWalletOptionsNewWalletSubtitle => '创建新钱包';

  @override
  String get addWalletOptionsExistingWalletTitle => '现有钱包';

  @override
  String get addWalletOptionsExistingWalletSubtitle => '使用助记词导入钱包';

  @override
  String get addWalletOptionsPairWithLedgerTitle => '与 Ledger 配对';

  @override
  String get addWalletOptionsPairWithLedgerSubtitle => '硬件模块，蓝牙';

  @override
  String get addWalletOptionsOtherOptions => '其他选项';

  @override
  String get addWalletOptionsWatchAccountTitle => '观察账户';

  @override
  String get addWalletOptionsWatchAccountSubtitle => '用于监控钱包活动，无需恢复短语';

  @override
  String get currencyConversionTitle => '主要货币';

  @override
  String get currencyConversionSearchHint => '搜索货币...';

  @override
  String get currencyConversionEngineTitle => '货币引擎';

  @override
  String get currencyConversionEngineDescription => '获取货币汇率的引擎';

  @override
  String get currencyConversionEngineSelectorTitle => '选择货币引擎';

  @override
  String get currencyConversionEngineNone => '无';

  @override
  String get currencyConversionEngineNoneSubtitle => '未选择引擎';

  @override
  String get currencyConversionEngineCoingecko => 'Coingecko';

  @override
  String get currencyConversionEngineCoingeckoSubtitle => '从 Coingecko 获取汇率';

  @override
  String get currencyConversionEngineBearbyRates => 'Bearby Rates';

  @override
  String get currencyConversionEngineBearbyRatesSubtitle => '从 Bearby 获取汇率';

  @override
  String get restoreWalletOptionsTitle => '恢复钱包';

  @override
  String get restoreWalletOptionsBIP39Title => 'BIP39';

  @override
  String get restoreWalletOptionsBIP39Subtitle => '使用助记词恢复';

  @override
  String get restoreWalletOptionsPrivateKeyTitle => '私钥';

  @override
  String get restoreWalletOptionsPrivateKeySubtitle => '使用私钥恢复';

  @override
  String get restoreWalletOptionsKeyStoreTitle => '密钥库文件';

  @override
  String get restoreWalletOptionsKeyStoreSubtitle => '使用密码加密的备份文件恢复钱包';

  @override
  String get restoreWalletOptionsQRCodeTitle => '二维码';

  @override
  String get restoreWalletOptionsQRCodeSubtitle => '通过扫描二维码恢复钱包';

  @override
  String get argonSettingsModalContentLowMemoryTitle => '低内存';

  @override
  String get argonSettingsModalContentLowMemorySubtitle => '64KB RAM，3 次迭代';

  @override
  String get argonSettingsModalContentLowMemoryDescription => '最小内存使用，适用于低端设备。';

  @override
  String get argonSettingsModalContentOwaspTitle => 'OWASP 默认';

  @override
  String get argonSettingsModalContentOwaspSubtitle => '6.5MB RAM，2 次迭代';

  @override
  String get argonSettingsModalContentOwaspDescription => 'OWASP 推荐的一般用途。';

  @override
  String get argonSettingsModalContentSecureTitle => '安全';

  @override
  String get argonSettingsModalContentSecureSubtitle => '256MB RAM，4 次迭代';

  @override
  String get argonSettingsModalContentSecureDescription => '增加内存和迭代次数的高安全性。';

  @override
  String get argonSettingsModalContentSecretHint => '输入密钥（可选）';

  @override
  String get argonSettingsModalContentConfirmButton => '确认';

  @override
  String get confirmTransactionContentPasswordHint => '密码';

  @override
  String get confirmTransactionContentUnableToConfirm => '无法确认';

  @override
  String get confirmTransactionContentConfirm => '确认';

  @override
  String get confirmTransactionContentNoActiveAccount => '无活动账户';

  @override
  String get confirmTransactionContentFailedLoadTransfer => '加载转账详情失败';

  @override
  String get confirmTransactionAdvancedGasButtonText => '高级';

  @override
  String get authReason => '请进行认证';

  @override
  String get addChainModalContentWarning => '警惕网络诈骗和安全风险。';

  @override
  String get addChainModalContentApprove => '批准';

  @override
  String get addChainModalContentDetails => '详情';

  @override
  String get addChainModalContentNetworkName => '网络名称：';

  @override
  String get addChainModalContentCurrencySymbol => '货币符号：';

  @override
  String get addChainModalContentChainId => '链 ID：';

  @override
  String get addChainModalContentBlockExplorer => '区块浏览器：';

  @override
  String get addAddressModalTitle => '添加联系人';

  @override
  String get addAddressModalDescription => '输入联系人姓名和钱包地址以添加到您的地址簿。';

  @override
  String get addAddressModalNameHint => '姓名';

  @override
  String get addAddressModalAddressHint => '钱包地址';

  @override
  String get addAddressModalNameEmptyError => '姓名不能为空';

  @override
  String get addAddressModalAddressEmptyError => '地址不能为空';

  @override
  String get addAddressModalButton => '添加联系人';

  @override
  String get tokenSelectModalContentSearchHint => '搜索';

  @override
  String get signMessageModalContentAuthReason => '请进行身份验证以签署消息';

  @override
  String signMessageModalContentFailedToSign(Object error) {
    return '签名失败：$error';
  }

  @override
  String get signMessageModalContentTitle => '签署消息';

  @override
  String get signMessageModalContentDescription => '使用您的钱包审阅并签署以下消息。';

  @override
  String get signMessageModalContentDomain => '域名：';

  @override
  String get signMessageModalContentChainId => '链ID：';

  @override
  String get signMessageModalContentContract => '合约：';

  @override
  String get signMessageModalContentType => '类型：';

  @override
  String get signMessageModalContentNoData => '无数据';

  @override
  String get signMessageModalContentPasswordHint => '密码';

  @override
  String get signMessageModalContentProcessing => '处理中...';

  @override
  String get signMessageModalContentSign => '签署消息';

  @override
  String get deleteWalletModalTitle => '删除钱包';

  @override
  String get deleteWalletModalWarning => '警告：此操作无法撤销。您的钱包只能使用助记词恢复。如果您无法访问助记词，您将永久失去与此账户关联的所有资金。';

  @override
  String get deleteWalletModalSecretPhraseWarning => '请确保您能够访问您的助记词，然后再继续。';

  @override
  String get deleteWalletModalPasswordHint => '输入密码';

  @override
  String get deleteWalletModalSubmit => '提交';

  @override
  String get addressSelectModalContentTitle => '选择收款人';

  @override
  String get addressSelectModalContentSearchHint => '搜索 / 地址 / ENS';

  @override
  String get addressSelectModalContentUnknown => '未知';

  @override
  String get addressSelectModalContentEmpty => '暂无联系人 — 粘贴地址或扫描二维码';

  @override
  String get walletCardPasteOrScan => '粘贴地址或扫描二维码';

  @override
  String get addressSelectModalContentMyAccounts => '我的账户';

  @override
  String get addressSelectModalContentAddressBook => '地址簿';

  @override
  String get addressSelectModalContentHistory => '历史';

  @override
  String get addressSelectModalContentSender => '发送方';

  @override
  String get changePasswordModalTitle => '更改密码';

  @override
  String get changePasswordModalDescription => '输入您当前的密码并选择新密码以更新您的钱包安全性。';

  @override
  String get changePasswordModalCurrentPasswordHint => '当前密码';

  @override
  String get changePasswordModalNewPasswordHint => '新密码';

  @override
  String get changePasswordModalConfirmPasswordHint => '确认新密码';

  @override
  String get changePasswordModalCurrentPasswordEmptyError => '当前密码不能为空';

  @override
  String get changePasswordModalPasswordLengthError => '密码必须至少有 6 个字符';

  @override
  String get changePasswordModalPasswordsMismatchError => '密码不匹配';

  @override
  String get changePasswordModalButton => '更改密码';

  @override
  String get confirmPasswordModalTitle => '确认密码';

  @override
  String get confirmPasswordModalDescription => '输入您的密码以继续。';

  @override
  String get confirmPasswordModalHint => '密码';

  @override
  String get confirmPasswordModalEmptyError => '密码不能为空';

  @override
  String get confirmPasswordModalGenericError => '错误：';

  @override
  String get confirmPasswordModalButton => '确认';

  @override
  String get qrScannerModalContentTitle => '扫描';

  @override
  String get qrScannerModalContentCameraInitError => '相机初始化错误：';

  @override
  String get chainInfoModalContentTokenTitle => '网络代币';

  @override
  String get chainInfoModalContentNetworkInfoTitle => '网络信息';

  @override
  String get chainInfoModalContentChainLabel => '链';

  @override
  String get chainInfoModalContentShortNameLabel => '简称';

  @override
  String get chainInfoModalContentChainIdLabel => '链 ID';

  @override
  String get chainInfoModalContentSlip44Label => 'Slip44';

  @override
  String get chainInfoModalContentChainIdsLabel => '链 ID';

  @override
  String get chainInfoModalContentTestnetLabel => '测试网';

  @override
  String get chainInfoModalContentYes => '是';

  @override
  String get chainInfoModalContentNo => '否';

  @override
  String get chainInfoModalContentDiffBlockTimeLabel => '区块时间差异';

  @override
  String get chainInfoModalContentFallbackEnabledLabel => '启用回退';

  @override
  String get chainInfoModalContentDecimalsLabel => '小数位';

  @override
  String get chainInfoModalContentRpcNodesTitle => 'RPC 节点';

  @override
  String get chainInfoModalContentExplorersTitle => '浏览器';

  @override
  String get chainInfoModalContentDeleteProviderTitle => '删除网络';

  @override
  String get chainInfoModalContentSwipeToDelete => '删除网络';

  @override
  String get chainConfigPageAdvancedButton => '高级';

  @override
  String get switchChainNetworkContentTitle => '选择网络';

  @override
  String get switchChainNetworkContentButton => '切换网络';

  @override
  String get switchChainNetworkContentTestnetLabel => '测试网';

  @override
  String get switchChainNetworkContentIdLabel => 'ID：';

  @override
  String get watchAssetModalContentTitle => '添加建议的代币';

  @override
  String get watchAssetModalContentDescription => '查看并添加应用建议的以下代币。';

  @override
  String get watchAssetModalContentTokenLabel => '代币';

  @override
  String get watchAssetModalContentBalanceLabel => '余额';

  @override
  String get watchAssetModalContentLoadingButton => '余额...';

  @override
  String get watchAssetModalContentAddButton => '添加';

  @override
  String get connectedDappsModalSearchHint => '搜索 DApps';

  @override
  String get connectedDappsModalNoDapps => '无已连接的 DApps';

  @override
  String get wcSectionTitle => 'WalletConnect';

  @override
  String get wcBrowserSectionTitle => '浏览器';

  @override
  String get wcNewConnection => '新建连接';

  @override
  String get wcPasteUri => '粘贴 wc: URI';

  @override
  String get wcDisconnect => '断开连接';

  @override
  String get wcPairFailed => 'WalletConnect 配对失败';

  @override
  String get wcApproveFailed => 'WalletConnect 会话批准失败';

  @override
  String get wcConnecting => '正在连接 WalletConnect…';

  @override
  String dappListItemConnected(Object time) {
    return '已连接 $time';
  }

  @override
  String get dappListItemJustNow => '刚刚';

  @override
  String get secretRecoveryModalRevealPhraseTitle => '显示助记词';

  @override
  String get secretRecoveryModalRevealPhraseDescription => '如果您更换浏览器或更换电脑，您将需要这个助记词来访问您的账户。将它们保存在安全且隐秘的地方。';

  @override
  String get secretRecoveryModalRevealPhraseButton => '显示';

  @override
  String get secretRecoveryModalShowKeysTitle => '显示私钥';

  @override
  String get secretRecoveryModalShowKeysDescription => '警告：绝不要泄露此密钥。任何拥有您私钥的人都可以窃取您账户中的任何资产。';

  @override
  String get secretRecoveryModalShowKeysButton => '导出';

  @override
  String get secretRecoveryModalKeystoreBackupTitle => '密钥库备份';

  @override
  String get secretRecoveryModalKeystoreBackupDescription => '将您的私钥保存在密码保护的加密密钥库文件中。这为您的钱包提供了额外的安全层。';

  @override
  String get secretRecoveryModalKeystoreBackupButton => '创建密钥库备份';

  @override
  String get backupConfirmationContentTitle => '备份确认';

  @override
  String get backupConfirmationWarning => '警告：如果您丢失或忘记助记词的确切顺序，您将永久失去您的资金。绝不与任何人分享您的助记词，否则他们可能会窃取您的资金。BIP39恢复是严格的 - 恢复过程中任何单词错误都将导致资金损失。';

  @override
  String get backupConfirmationContentWrittenDown => '我已经写下了全部内容';

  @override
  String get backupConfirmationContentSafelyStored => '我已安全存储备份';

  @override
  String get backupConfirmationContentWontLose => '我确信不会丢失备份';

  @override
  String get backupConfirmationContentNotShare => '我明白不要与任何人分享这些单词';

  @override
  String get counterMaxValueError => '已达到最大值';

  @override
  String get counterMinValueError => '已达到最小值';

  @override
  String get biometricSwitchTouchId => '启用触控ID';

  @override
  String get biometricSwitchFaceId => '启用面容ID';

  @override
  String get biometricSwitchOpticId => '启用光学ID';

  @override
  String get biometricSwitchFingerprint => '启用指纹';

  @override
  String get biometricSwitchBiometric => '启用生物识别登录';

  @override
  String get biometricSwitchPinCode => '启用设备PIN码';

  @override
  String get gasFeeOptionLow => '低';

  @override
  String get gasFeeOptionMarket => '市场';

  @override
  String get gasFeeOptionAggressive => '激进';

  @override
  String get gasDetailsEstimatedGas => '估计gas用量：';

  @override
  String get gasDetailsGasPrice => 'gas价格：';

  @override
  String get gasDetailsBaseFee => '基础费用：';

  @override
  String get gasDetailsPriorityFee => '优先费用：';

  @override
  String get gasDetailsMaxFee => '最高费用：';

  @override
  String get tokenTransferAmountUnknown => '未知';

  @override
  String get transactionDetailsModal_transaction => '交易';

  @override
  String get transactionDetailsModal_hash => '哈希';

  @override
  String get transactionDetailsModal_sig => '签名';

  @override
  String get transactionDetailsModal_timestamp => '时间戳';

  @override
  String get transactionDetailsModal_blockNumber => '区块号';

  @override
  String get transactionDetailsModal_nonce => '随机数';

  @override
  String get transactionDetailsModal_addresses => '地址';

  @override
  String get transactionDetailsModal_sender => '发送方';

  @override
  String get transactionDetailsModal_recipient => '接收方';

  @override
  String get transactionDetailsModal_contractAddress => '合约地址';

  @override
  String get transactionDetailsModal_network => '网络';

  @override
  String get transactionDetailsModal_chainType => '链类型';

  @override
  String get transactionDetailsModal_networkName => '网络';

  @override
  String get transactionDetailsModal_gasFees => 'Gas和费用';

  @override
  String get transactionDetailsModal_fee => '费用';

  @override
  String get transactionDetailsModal_gasUsed => '已用Gas';

  @override
  String get transactionDetailsModal_gasLimit => 'Gas限制';

  @override
  String get transactionDetailsModal_gasPrice => 'Gas价格';

  @override
  String get transactionDetailsModal_effectiveGasPrice => '有效Gas价格';

  @override
  String get transactionDetailsModal_blobGasUsed => '已用Blob Gas';

  @override
  String get transactionDetailsModal_blobGasPrice => 'Blob Gas价格';

  @override
  String get transactionDetailsModal_error => '错误';

  @override
  String get transactionDetailsModal_errorMessage => '错误信息';

  @override
  String get transactionDetailsModal_from => '来源';

  @override
  String get transactionDetailsModal_to => '去向';

  @override
  String get transactionDetailsModal_age => '时长';

  @override
  String get transactionDetailsModal_inputValue => '输入合计';

  @override
  String get transactionDetailsModal_outputValue => '输出合计';

  @override
  String get transactionDetailsModal_btcPrice => 'BTC 价格';

  @override
  String get transactionDetailsModal_coinbase => 'Coinbase';

  @override
  String get transactionDetailsModal_rbf => 'RBF';

  @override
  String get transactionDetailsModal_locktime => '锁定时间';

  @override
  String get transactionDetailsModal_version => '版本';

  @override
  String get transactionDetailsModal_feesProperties => '费用与属性';

  @override
  String transactionDetailsModal_inputsOutputsSummary(int inputCount, int outputCount) {
    String _temp0 = intl.Intl.pluralLogic(
      inputCount,
      locale: localeName,
      other: '$inputCount 个输入',
    );
    String _temp1 = intl.Intl.pluralLogic(
      outputCount,
      locale: localeName,
      other: '$outputCount 个输出',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get amountSection_transfer => '转账';

  @override
  String get amountSection_pending => '待处理';

  @override
  String get amountSection_confirmed => '已确认';

  @override
  String get amountSection_rejected => '已拒绝';

  @override
  String get appConnectModalContent_swipeToConnect => '滑动连接';

  @override
  String get appConnectModalContent_noAccounts => '无可用账户';

  @override
  String get browserActionMenuShare => '分享';

  @override
  String get browserActionMenuCopyLink => '复制链接';

  @override
  String get browserActionMenuRefresh => '刷新';

  @override
  String get browserActionMenuUrlBarTop => '地址栏置顶';

  @override
  String get keystoreBackupTitle => '密钥库备份';

  @override
  String get keystoreBackupWarningTitle => '保护您的密钥库文件';

  @override
  String get keystoreBackupWarningMessage => '密钥库文件包含您的加密私钥。将此文件保存在安全位置，绝不与任何人分享。您需要创建的密码来解密此文件。';

  @override
  String get keystoreBackupConfirmPasswordHint => '确认密码';

  @override
  String get keystoreBackupCreateButton => '创建备份';

  @override
  String get keystoreBackupError => '创建备份错误：';

  @override
  String get keystoreBackupShareButton => '分享密钥库文件';

  @override
  String get keystoreBackupDoneButton => '完成';

  @override
  String get keystoreBackupSuccessTitle => '备份创建成功';

  @override
  String get keystoreBackupSuccessMessage => '您的密钥库文件已创建。请记住保管好文件和密码。';

  @override
  String get keystoreBackupSaveAsButton => '保存至文件';

  @override
  String get keystoreBackupSaveDialogTitle => '保存密钥库文件';

  @override
  String get keystoreBackupSavedSuccess => '密钥库文件保存成功';

  @override
  String get keystoreBackupSaveFailed => '密钥库文件保存失败';

  @override
  String get keystoreBackupPasswordTooShort => '密码必须至少8个字符';

  @override
  String get keystoreBackupTempLocation => '临时文件位置';

  @override
  String get keystorePasswordHint => '输入您的密钥库密码';

  @override
  String get keystoreRestoreButton => '恢复钱包';

  @override
  String get keystoreRestoreExtError => '请选择有效的.zp文件';

  @override
  String get keystoreRestoreNoFile => '未找到密钥库文件';

  @override
  String get keystoreRestoreFilesTitle => '密钥库文件';

  @override
  String get editGasDialogTitle => '编辑燃料参数';

  @override
  String get editGasDialogGasPrice => '燃料价格';

  @override
  String get editGasDialogMaxPriorityFee => '最大优先费用';

  @override
  String get editGasDialogGasLimit => '燃料限制';

  @override
  String get editGasDialogInvalidGasValues => '燃料值无效。请检查您的输入。';

  @override
  String get addLedgerAccountPageGetAccountsButton => '获取账户';

  @override
  String get addLedgerAccountPageCreateButton => '创建';

  @override
  String get addLedgerAccountPageAddButton => '添加';

  @override
  String get addLedgerAccountPageNoAccountsSelectedError => '未选择任何账户';

  @override
  String get addLedgerAccountPageNoWalletSelectedError => '未选择钱包';

  @override
  String get addLedgerAccountPageLedgerIndex => 'Ledger 索引';

  @override
  String get transactionHistoryTitle => '交易历史';

  @override
  String get transactionHistoryDescription => '在地址簿中显示来自交易历史的地址。';

  @override
  String get zilStakePageTitle => 'Zilliqa 质押';

  @override
  String get noStakingPoolsFound => '未找到质押池';

  @override
  String get stakingErrorTitle => '加载质押池失败';

  @override
  String get stakingErrorRetry => '重试';

  @override
  String get claimButton => '领取';

  @override
  String get stakeButton => '质押';

  @override
  String get unstakeButton => '取消质押';

  @override
  String get aprLabel => '年化率';

  @override
  String get commissionLabel => '佣金';

  @override
  String get stakedAmount => '已质押';

  @override
  String get rewardsAvailable => '可用奖励';

  @override
  String get pendingWithdrawals => '待处理提款';

  @override
  String get amount => '数量';

  @override
  String get claimableIn => '可领取于';

  @override
  String get blocks => '区块';

  @override
  String get unbondingPeriod => '解绑期';

  @override
  String get currentBlock => '当前区块';

  @override
  String get version => '版本';

  @override
  String get rewardsProgressTitle => '收益进度';

  @override
  String get ledgerConnectPageTitle => '连接 Ledger';

  @override
  String get ledgerConnectPageInitializing => '正在初始化...';

  @override
  String get ledgerConnectPageScanningStatus => '正在扫描 Ledger 设备...';

  @override
  String ledgerConnectPageFoundDevicesStatus(int count) {
    return '已找到 $count 个设备...';
  }

  @override
  String ledgerConnectPageScanErrorStatus(String error) {
    return '扫描错误: $error';
  }

  @override
  String get ledgerConnectPageScanFinishedNoDevices => '扫描完成。未找到任何设备。';

  @override
  String ledgerConnectPageScanFinishedWithDevices(int count) {
    return '扫描完成。找到 $count 个设备。请选择一个进行连接。';
  }

  @override
  String ledgerConnectPageConnectingStatus(String deviceName, String connectionType) {
    return '正在连接到 $deviceName ($connectionType)...';
  }

  @override
  String get ledgerConnectPageConnectionFailedTitle => '连接失败';

  @override
  String ledgerConnectPageConnectionFailedErrorStatus(String error) {
    return '连接失败: $error';
  }

  @override
  String ledgerConnectPageConnectionFailedGenericContent(String deviceName, String error) {
    return '无法连接到 $deviceName。\n错误: $error';
  }

  @override
  String ledgerConnectPageDisconnectedStatus(String deviceName) {
    return '已从 $deviceName 断开连接。';
  }

  @override
  String get ledgerConnectPageGoToSettings => '前往设置';

  @override
  String get ledgerConnectPageNoDevicesFound => '未找到设备。请确保 Ledger 已开机、解锁，并启用了蓝牙/USB。\n下拉或使用刷新图标再次扫描。';

  @override
  String get durationDay => '天';

  @override
  String get durationHour => '小时';

  @override
  String get durationMinute => '分钟';

  @override
  String get durationLessThanAMinute => '< 1分钟';

  @override
  String get durationNotAvailable => '不适用';

  @override
  String get nodes => '节点';

  @override
  String get manageTokensPageTitle => '代币';

  @override
  String get manageTokensSearchHint => '搜索代币或粘贴地址';

  @override
  String get manageTokensFoundToken => '找到的代币';

  @override
  String get manageTokensDeletedTokens => '已删除的代币';

  @override
  String get manageTokensSuggestedTokens => '推荐代币';

  @override
  String get manageTokensFetchError => '获取代币失败';

  @override
  String get manageTokensWrongChain => '代币属于其他链';

  @override
  String get manageTokensClear => '清除';

  @override
  String get signedMessageTypePersonalSign => '个人签名';

  @override
  String get signedMessageTypeEip712 => 'EIP-712';

  @override
  String get signedMessageTypeUnknown => '未知';

  @override
  String get signedMessageSigner => '签名者';

  @override
  String get signedMessagePublicKey => '公钥';

  @override
  String get signedMessageType => '类型';

  @override
  String get signedMessageEip712Domain => 'EIP-712 域';

  @override
  String get signedMessageDomainName => '名称';

  @override
  String get signedMessageDomainChainId => '链 ID';

  @override
  String get signedMessageDomainContract => '合约';

  @override
  String get signedMessagePrimaryType => '主类型';

  @override
  String get signedMessageData => '消息数据';

  @override
  String get signedMessageContent => '内容';

  @override
  String get signedMessageMessage => '消息';

  @override
  String get web3ErrorNoMethod => '未指定方法';

  @override
  String web3ErrorUnsupportedMethod(String method) {
    return '不支持方法 \"$method\"';
  }

  @override
  String get web3ErrorRequestInProgress => '类似的请求已在处理中';

  @override
  String get web3ErrorNotConnected => '此域名未连接。请先连接。';

  @override
  String web3ErrorInvalidParams(String method, String params) {
    return '$method 的参数无效。需要：$params';
  }

  @override
  String get web3ErrorAddressNotAuthorized => '请求的地址未授权';

  @override
  String get web3ErrorUserRejected => '用户拒绝';

  @override
  String get web3ErrorUserRejectedRequest => '用户拒绝了请求';

  @override
  String web3ErrorMissingParam(String param) {
    return '缺少必需参数：$param';
  }

  @override
  String get web3ErrorNoNativeToken => '未找到原生代币';

  @override
  String get web3ErrorPermissionNotSupported => '仅支持 eth_accounts 权限';

  @override
  String get web3ErrorNotAuthorizedSuggestTokens => '此域名未授权建议代币。';

  @override
  String get web3ErrorInvalidTokenType => 'wallet_watchAsset 的参数无效。需要 ERC20 代币类型。';

  @override
  String get web3ErrorMissingTokenFields => '缺少必需字段：address、symbol 或 decimals。';

  @override
  String get web3ErrorMissingChainFields => 'wallet_addEthereumChain 缺少必需字段';

  @override
  String get web3ErrorNoValidRpcUrls => '未提供有效的 HTTP RPC URL';

  @override
  String get web3ErrorMissingChainId => '缺少必需字段：chainId';

  @override
  String get web3ErrorChainNotAdded => '请求的链尚未添加。请先使用 wallet_addEthereumChain。';

  @override
  String get bipPurposeSetupPageTitle => '比特币地址';

  @override
  String get bip86Name => 'BIP86 (Taproot)';

  @override
  String get bip86Description => 'P2TR - 以bc1p开头的地址';

  @override
  String get bip84Name => 'BIP84 (Native SegWit)';

  @override
  String get bip84Description => 'P2WPKH - 以bc1q开头的地址';

  @override
  String get bip49Name => 'BIP49 (SegWit)';

  @override
  String get bip49Description => 'P2WPKH-nested-in-P2SH - 以3开头的地址';

  @override
  String get bip44Name => 'BIP44 (Legacy)';

  @override
  String get bip44Description => 'P2PKH - 以1开头的地址';

  @override
  String get addNetworkPageTitle => '添加网络';

  @override
  String get addNetworkFieldName => '网络名称';

  @override
  String get addNetworkFieldShortName => '简称';

  @override
  String get addNetworkFieldChain => '链类型';

  @override
  String get addNetworkFieldRpc => 'RPC URL';

  @override
  String get addNetworkFieldChainId => '链 ID';

  @override
  String get addNetworkFieldExplorerUrl => '区块浏览器 URL';

  @override
  String get addNetworkFieldTokenSymbol => '代币符号';

  @override
  String get addNetworkFieldTokenDecimals => '小数位';

  @override
  String get addNetworkFieldTestnet => '测试网';

  @override
  String get addNetworkPageButton => '添加网络';

  @override
  String get addNetworkPageErrorRequired => '请填写所有必填字段';

  @override
  String get addNetworkPageErrorInvalidRpc => '请输入有效的 RPC URL';

  @override
  String get addNetworkPageErrorInvalidChainId => '请输入有效的链 ID';

  @override
  String get addNetworkPageSuccess => '网络添加成功';

  @override
  String get qrCodeUnrecognizedError => '无法识别二维码，请使用支持的格式。';

  @override
  String get qrCodeScanError => '读取二维码失败，请重试。';

  @override
  String get homePageQrScanErrorTitle => '错误';

  @override
  String get homePageQrScanOkButton => '确定';

  @override
  String get qrCodeEmptySeedError => '二维码不包含助记词。';

  @override
  String get qrCodeInvalidWordsError => '二维码包含无效的 BIP39 单词。';

  @override
  String get qrCodeInvalidKeyError => '二维码包含无效的私钥。';

  @override
  String get deprecatedLabel => '(已弃用)';

  @override
  String get restoreWalletOptionsPrivateKeyDeprecatedSubtitle => 'Bitcoin 网络已弃用。请使用 BIP39。';
}
