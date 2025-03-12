// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'ZilPay Кошелек';

  @override
  String get initialPagerestoreZilPay => 'Восстановить ZilPay 1.0!';

  @override
  String get initialPagegetStarted => 'Начать';

  @override
  String get restoreRKStorageTitle => 'Перенос ZilPay 1.0 в 2.0';

  @override
  String get restoreRKStorageAccountsPrompt => 'Аккаунты для переноса в ZilPay 2.0. Введите пароль.';

  @override
  String get restoreRKStoragePasswordHint => 'Пароль';

  @override
  String get restoreRKStorageEnterPassword => 'Введите пароль';

  @override
  String get restoreRKStorageErrorPrefix => 'Ошибка:';

  @override
  String get restoreRKStorageRestoreButton => 'Восстановить';

  @override
  String get restoreRKStorageSkipButton => 'Пропустить';

  @override
  String get accountItemBalanceLabel => 'Баланс:';

  @override
  String get sendTokenPageTitle => '';

  @override
  String get sendTokenPageSubmitButton => 'Отправить';

  @override
  String get aboutPageTitle => 'О приложении';

  @override
  String get aboutPageAppName => 'ZilPay';

  @override
  String get aboutPageAppDescription => 'Ваш безопасный блокчейн-кошелек';

  @override
  String get aboutPageAppInfoTitle => 'Информация о приложении';

  @override
  String get aboutPageVersionLabel => 'Версия';

  @override
  String get aboutPageBuildDateLabel => 'Дата сборки';

  @override
  String get aboutPageBuildDateValue => '10 марта 2025';

  @override
  String get aboutPagePlatformLabel => 'Платформа';

  @override
  String get aboutPageDeveloperTitle => 'Разработчик';

  @override
  String get aboutPageAuthorLabel => 'Автор';

  @override
  String get aboutPageAuthorValue => 'Rinat (hicaru)';

  @override
  String get aboutPageWebsiteLabel => 'Веб-сайт';

  @override
  String get aboutPageWebsiteValue => 'https://zilpay.io';

  @override
  String get aboutPageLegalTitle => 'Юридическая информация';

  @override
  String get aboutPagePrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get aboutPageTermsOfService => 'Условия использования';

  @override
  String get aboutPageLicenses => 'Лицензии';

  @override
  String get aboutPageLegalese => '© 2025 ZilPay. Все права защищены.';

  @override
  String get languagePageTitle => 'Язык';

  @override
  String get languagePageSystem => 'Системный';

  @override
  String get secretKeyGeneratorPageTitle => 'Секретный ключ';

  @override
  String get secretKeyGeneratorPagePrivateKey => 'Приватный ключ';

  @override
  String get secretKeyGeneratorPagePublicKey => 'Публичный ключ';

  @override
  String get secretKeyGeneratorPageBackupCheckbox => 'Я сделал резервную копию секретного ключа';

  @override
  String get secretKeyGeneratorPageNextButton => 'Далее';

  @override
  String get walletPageTitle => '';

  @override
  String get walletPageWalletNameHint => 'Название кошелька';

  @override
  String get walletPagePreferencesTitle => 'Настройки кошелька';

  @override
  String get walletPageManageConnections => 'Управление подключениями';

  @override
  String get walletPageBackup => 'Резервная копия';

  @override
  String get walletPageDeleteWallet => 'Удалить кошелек';

  @override
  String get walletPageBiometricReason => 'Включить биометрическую аутентификацию';

  @override
  String get networkPageTitle => '';

  @override
  String get networkPageShowTestnet => 'Показать тестовую сеть';

  @override
  String get networkPageSearchHint => 'Поиск';

  @override
  String get networkPageAddedNetworks => 'Добавленные сети';

  @override
  String get networkPageAvailableNetworks => 'Доступные сети';

  @override
  String get networkPageLoadError => 'Не удалось загрузить сети: ';

  @override
  String get networkPageAddError => 'Не удалось добавить сеть: ';

  @override
  String get receivePageTitle => 'Получить';

  @override
  String receivePageWarning(Object chainName, Object tokenSymbol) {
    return 'Отправляйте только активы $chainName($tokenSymbol) на этот адрес. Другие активы будут потеряны навсегда.';
  }

  @override
  String get receivePageAccountNameHint => 'Имя аккаунта';

  @override
  String get receivePageAmountDialogTitle => 'Введите сумму';

  @override
  String get receivePageAmountDialogHint => '0.0';

  @override
  String get receivePageAmountDialogCancel => 'Отмена';

  @override
  String get receivePageAmountDialogConfirm => 'Подтвердить';

  @override
  String get securityPageTitle => 'Безопасность';

  @override
  String get securityPageNetworkPrivacy => 'Приватность сети';

  @override
  String get securityPageEnsDomains => 'Показывать ENS домены в адресной строке';

  @override
  String get securityPageEnsDescription => 'Имейте в виду, что использование этой функции раскрывает ваш IP-адрес сторонним сервисам IPFS.';

  @override
  String get securityPageIpfsGateway => 'IPFS шлюз';

  @override
  String get securityPageIpfsDescription => 'ZIlPay использует сторонние сервисы для отображения изображений ваших NFT, хранящихся в IPFS, информации, связанной с ENS(ZNS) адресами в адресной строке браузера, и получения иконок для различных токенов. Ваш IP-адрес может быть раскрыт этим сервисам при их использовании.';

  @override
  String get securityPageGasStation => 'Газовая станция';

  @override
  String get securityPageGasDescription => 'Использовать сервер ZilPay для оптимизации использования газа';

  @override
  String get securityPageNodeRanking => 'Ранжирование узлов';

  @override
  String get securityPageNodeDescription => 'Отправлять запросы на сервер ZilPay для получения лучшего узла';

  @override
  String get securityPageEncryptionLevel => 'Уровень шифрования';

  @override
  String get securityPageProtection => 'Защита';

  @override
  String get securityPageCpuLoad => 'Нагрузка ЦП';

  @override
  String get securityPageAes256 => 'AES256';

  @override
  String get securityPageKuznechikGost => 'КУЗНЕЧИК-ГОСТ';

  @override
  String get securityPageNtruPrime => 'NTRUPrime';

  @override
  String get securityPageCyber => 'Cyber';

  @override
  String get securityPageUnknown => 'Неизвестно';

  @override
  String get webViewPageDntLabel => 'DNT';

  @override
  String get webViewPageIncognitoLabel => 'Инкогнито';

  @override
  String get webViewPageLoadError => 'Ошибка загрузки';

  @override
  String get webViewPageTryAgain => 'Попробовать снова';

  @override
  String get addTokenPageTitle => 'Добавить токен';

  @override
  String get addTokenPageTokenInfo => 'Информация о токене';

  @override
  String get addTokenPageHint => 'Адрес, название, символ';

  @override
  String get addTokenPageAddError => 'Не удалось добавить токен:';

  @override
  String get addTokenPageInvalidAddressError => 'Неверный адрес токена или ошибка сети';

  @override
  String get secretPhraseGeneratorPageTitle => 'Новый кошелек';

  @override
  String get secretPhraseGeneratorPageBackupCheckbox => 'Я сохранил секретные слова';

  @override
  String get secretPhraseGeneratorPageNextButton => 'Далее';

  @override
  String get homePageTestnetLabel => 'Тестовая сеть';

  @override
  String get revealSecretKeyTitle => 'Показать секретный ключ';

  @override
  String get revealSecretKeyPasswordHint => 'Пароль';

  @override
  String get revealSecretKeyInvalidPassword => 'неверный пароль, ошибка:';

  @override
  String get revealSecretKeySubmitButton => 'Отправить';

  @override
  String get revealSecretKeyDoneButton => 'Готово';

  @override
  String get revealSecretKeyScamAlertTitle => 'ВНИМАНИЕ МОШЕННИЧЕСТВО';

  @override
  String get revealSecretKeyScamAlertMessage => 'Никогда не делитесь своим секретным ключом с кем-либо. Никогда не вводите его на каких-либо сайтах.';

  @override
  String get setupNetworkSettingsPageTestnetSwitch => 'Тестовая сеть';

  @override
  String get setupNetworkSettingsPageSearchHint => 'Поиск';

  @override
  String get setupNetworkSettingsPageNoNetworks => 'Нет доступных сетей';

  @override
  String setupNetworkSettingsPageNoResults(Object searchQuery) {
    return 'Не найдено сетей для \"$searchQuery\"';
  }

  @override
  String get setupNetworkSettingsPageNextButton => 'Далее';

  @override
  String get setupNetworkSettingsPageTestnetLabel => 'Тестовая сеть';

  @override
  String get setupNetworkSettingsPageMainnetLabel => 'Основная сеть';

  @override
  String get setupNetworkSettingsPageChainIdLabel => 'ID цепи:';

  @override
  String get setupNetworkSettingsPageTokenLabel => 'Токен:';

  @override
  String get setupNetworkSettingsPageExplorerLabel => 'Обозреватель:';

  @override
  String get appearanceSettingsPageTitle => 'Настройки внешнего вида';

  @override
  String get appearanceSettingsPageCompactNumbersTitle => 'Компактные числа';

  @override
  String get appearanceSettingsPageCompactNumbersDescription => 'Включите для отображения сокращенных чисел (например, 20K вместо 20,000).';

  @override
  String get appearanceSettingsPageDeviceSettingsTitle => 'Настройки устройства';

  @override
  String get appearanceSettingsPageDeviceSettingsSubtitle => 'Системные настройки';

  @override
  String get appearanceSettingsPageDeviceSettingsDescription => 'По умолчанию использовать настройки устройства. Тема кошелька будет автоматически настраиваться в соответствии с системными настройками.';

  @override
  String get appearanceSettingsPageDarkModeTitle => 'Темный режим';

  @override
  String get appearanceSettingsPageDarkModeSubtitle => 'Всегда темная';

  @override
  String get appearanceSettingsPageDarkModeDescription => 'Всегда использовать темную тему, независимо от настроек устройства.';

  @override
  String get appearanceSettingsPageLightModeTitle => 'Светлый режим';

  @override
  String get appearanceSettingsPageLightModeSubtitle => 'Всегда светлая';

  @override
  String get appearanceSettingsPageLightModeDescription => 'Всегда использовать светлую тему, независимо от настроек устройства.';

  @override
  String get loginPageBiometricReason => 'Пожалуйста, пройдите аутентификацию';

  @override
  String loginPageWalletTitle(Object index) {
    return 'Кошелек $index';
  }

  @override
  String get loginPagePasswordHint => 'Пароль';

  @override
  String get loginPageUnlockButton => 'Разблокировать';

  @override
  String get loginPageWelcomeBack => 'С возвращением';

  @override
  String get secretKeyRestorePageTitle => 'Восстановление секретного ключа';

  @override
  String get secretKeyRestorePageHint => 'Приватный ключ';

  @override
  String get secretKeyRestorePageInvalidFormat => 'Неверный формат приватного ключа';

  @override
  String get secretKeyRestorePageKeyTitle => 'Приватный ключ';

  @override
  String get secretKeyRestorePageBackupLabel => 'Я сделал резервную копию моего секретного ключа';

  @override
  String get secretKeyRestorePageNextButton => 'Далее';

  @override
  String get addAccountPageTitle => 'Добавить новый аккаунт';

  @override
  String get addAccountPageSubtitle => 'Создать BIP39 аккаунт';

  @override
  String addAccountPageDefaultName(Object index) {
    return 'Аккаунт $index';
  }

  @override
  String get addAccountPageNameHint => 'Имя аккаунта';

  @override
  String get addAccountPageBip39Index => 'BIP39 индекс';

  @override
  String get addAccountPageUseBiometrics => 'Использовать биометрию';

  @override
  String get addAccountPagePasswordHint => 'Пароль';

  @override
  String get addAccountPageZilliqaLegacy => 'Zilliqa Legacy';

  @override
  String get addAccountPageBiometricReason => 'Пройдите аутентификацию для создания нового аккаунта';

  @override
  String addAccountPageBiometricError(Object error) {
    return 'Ошибка биометрической аутентификации: $error';
  }

  @override
  String addAccountPageIndexExists(Object index) {
    return 'Аккаунт с индексом $index уже существует';
  }

  @override
  String get addAccountPageBiometricFailed => 'Биометрическая аутентификация не удалась';

  @override
  String addAccountPageCreateFailed(Object error) {
    return 'Не удалось создать аккаунт: $error';
  }

  @override
  String get addressBookPageTitle => 'Адресная книга';

  @override
  String get addressBookPageEmptyMessage => 'Ваши контакты и их адреса кошельков\nпоявятся здесь.';

  @override
  String addressBookPageNetwork(Object network) {
    return 'Сеть $network';
  }

  @override
  String get browserPageConnectedTab => 'Подключенные';

  @override
  String get browserPageExploreTab => 'Обзор';

  @override
  String get browserPageNoExploreApps => 'Пока нет приложений для обзора';

  @override
  String browserPageSearchHint(Object engine) {
    return 'Искать с помощью $engine или введите адрес';
  }

  @override
  String get browserPageNoConnectedApps => 'Нет подключенных приложений';

  @override
  String get historyPageTitle => 'История транзакций';

  @override
  String get historyPageNoTransactions => 'Пока нет транзакций';

  @override
  String get historyPageSearchHint => 'Поиск транзакций...';

  @override
  String get notificationsSettingsPageTitle => 'Уведомления';

  @override
  String get notificationsSettingsPagePushTitle => 'Push-уведомления';

  @override
  String get notificationsSettingsPagePushDescription => 'Получать уведомления о отправке и подтверждении транзакций, уведомления от подключенных приложений.';

  @override
  String get notificationsSettingsPageWalletsTitle => 'Кошельки';

  @override
  String get notificationsSettingsPageWalletsDescription => 'Уведомления от кошельков';

  @override
  String get notificationsSettingsPageWalletPrefix => 'Кошелек';

  @override
  String get revealSecretPhraseTitle => 'Показать секретную фразу';

  @override
  String get revealSecretPhrasePasswordHint => 'Пароль';

  @override
  String get revealSecretPhraseInvalidPassword => 'неверный пароль, ошибка:';

  @override
  String get revealSecretPhraseSubmitButton => 'Отправить';

  @override
  String get revealSecretPhraseDoneButton => 'Готово';

  @override
  String get revealSecretPhraseScamAlertTitle => 'ВНИМАНИЕ МОШЕННИЧЕСТВО';

  @override
  String get revealSecretPhraseScamAlertDescription => 'Никогда не делитесь своей секретной фразой с кем-либо. Никогда не вводите её на каких-либо сайтах.';

  @override
  String get cipherSettingsPageTitle => 'Настройка шифрования';

  @override
  String get cipherSettingsPageAdvancedButton => 'Продвинутые';

  @override
  String get cipherSettingsPageStandardTitle => 'Стандартное шифрование';

  @override
  String get cipherSettingsPageStandardSubtitle => 'AES-256 + КУЗНЕЧИК-ГОСТ';

  @override
  String get cipherSettingsPageStandardDescription => 'Базовое шифрование с AES-256 и стандартом ГОСТ КУЗНЕЧИК.';

  @override
  String get cipherSettingsPageHybridTitle => 'Гибридное шифрование';

  @override
  String get cipherSettingsPageHybridSubtitle => 'CYBER + КУЗНЕЧИК-ГОСТ';

  @override
  String get cipherSettingsPageHybridDescription => 'Гибридное шифрование, комбинирующее алгоритмы CYBER и КУЗНЕЧИК-ГОСТ.';

  @override
  String get cipherSettingsPageQuantumTitle => 'Квантово-устойчивое';

  @override
  String get cipherSettingsPageQuantumSubtitle => 'CYBER + КУЗНЕЧИК + NTRUP1277';

  @override
  String get cipherSettingsPageQuantumDescription => 'Продвинутое квантово-устойчивое шифрование с NTRUP1277.';

  @override
  String get cipherSettingsPageQuantumWarning => 'Квантово-устойчивое шифрование может повлиять на производительность';

  @override
  String get cipherSettingsPageConfirmButton => 'Подтвердить';

  @override
  String get secretPhraseVerifyPageTitle => 'Проверка секрета';

  @override
  String get secretPhraseVerifyPageSkipButton => 'Пропустить';

  @override
  String get secretPhraseVerifyPageSubtitle => 'Проверка Bip39 секрета';

  @override
  String get secretPhraseVerifyPageNextButton => 'Далее';

  @override
  String get restoreSecretPhrasePageTitle => 'Восстановить кошелек';

  @override
  String get restoreSecretPhrasePageRestoreButton => 'Восстановить';

  @override
  String get settingsPageTitle => 'Настройки';

  @override
  String get settingsPageZilliqaLegacy => 'Zilliqa Legacy';

  @override
  String get settingsPageCurrency => 'Валюта';

  @override
  String get settingsPageAppearance => 'Внешний вид';

  @override
  String get settingsPageNotifications => 'Уведомления';

  @override
  String get settingsPageAddressBook => 'Адресная книга';

  @override
  String get settingsPageSecurityPrivacy => 'Безопасность и конфиденциальность';

  @override
  String get settingsPageNetworks => 'Сети';

  @override
  String get settingsPageLanguage => 'Язык';

  @override
  String get settingsPageBrowser => 'Браузер';

  @override
  String get settingsPageTelegram => 'Telegram';

  @override
  String get settingsPageTwitter => 'Twitter';

  @override
  String get settingsPageGitHub => 'GitHub';

  @override
  String get settingsPageAbout => 'О приложении';

  @override
  String get ledgerConnectPageTitle => 'Подключение Ledger';

  @override
  String get passwordSetupPageTitle => 'Настройка пароля';

  @override
  String get passwordSetupPageSubtitle => 'Создать пароль';

  @override
  String get passwordSetupPageWalletNameHint => 'Название кошелька';

  @override
  String get passwordSetupPagePasswordHint => 'Пароль';

  @override
  String get passwordSetupPageConfirmPasswordHint => 'Подтвердите пароль';

  @override
  String get passwordSetupPageEmptyWalletNameError => 'Название кошелька не может быть пустым';

  @override
  String get passwordSetupPageLongWalletNameError => 'Название кошелька слишком длинное';

  @override
  String get passwordSetupPageShortPasswordError => 'Пароль должен содержать не менее 8 символов';

  @override
  String get passwordSetupPageMismatchPasswordError => 'Пароли не совпадают';

  @override
  String get passwordSetupPageLegacyLabel => 'Legacy';

  @override
  String get passwordSetupPageCreateButton => 'Создать пароль';

  @override
  String get passwordSetupPageAuthReason => 'Пожалуйста, пройдите аутентификацию для быстрого доступа';

  @override
  String get passwordSetupPageSeedType => 'Seed';

  @override
  String get passwordSetupPageKeyType => 'Ключ';

  @override
  String get passwordSetupPageUniversalNetwork => 'Универсальный';

  @override
  String get browserSettingsTitle => 'Настройки браузера';

  @override
  String get browserSettingsBrowserOptions => 'Параметры браузера';

  @override
  String get browserSettingsSearchEngine => 'Поисковая система';

  @override
  String get browserSettingsSearchEngineDescription => 'Настройте поисковую систему по умолчанию';

  @override
  String get browserSettingsSearchEngineTitle => 'Поисковая система';

  @override
  String get browserSettingsContentBlocking => 'Блокировка контента';

  @override
  String get browserSettingsContentBlockingDescription => 'Настройте параметры блокировки контента';

  @override
  String get browserSettingsContentBlockingTitle => 'Блокировка контента';

  @override
  String get browserSettingsPrivacySecurity => 'Конфиденциальность и безопасность';

  @override
  String get browserSettingsCookies => 'Куки';

  @override
  String get browserSettingsCookiesDescription => 'Разрешить сайтам сохранять и читать куки';

  @override
  String get browserSettingsDoNotTrack => 'Не отслеживать';

  @override
  String get browserSettingsDoNotTrackDescription => 'Запрашивать у сайтов не отслеживать ваш просмотр';

  @override
  String get browserSettingsIncognitoMode => 'Режим инкогнито';

  @override
  String get browserSettingsIncognitoModeDescription => 'Просмотр без сохранения истории и куков';

  @override
  String get browserSettingsPerformance => 'Производительность';

  @override
  String get browserSettingsCache => 'Кэш';

  @override
  String get browserSettingsCacheDescription => 'Хранить данные сайтов для быстрой загрузки';

  @override
  String get genWalletOptionsTitle => 'Создать кошелек';

  @override
  String get genWalletOptionsBIP39Title => 'BIP39';

  @override
  String get genWalletOptionsBIP39Subtitle => 'Создать мнемоническую фразу';

  @override
  String get genWalletOptionsSLIP0039Title => 'SLIP-0039';

  @override
  String get genWalletOptionsSLIP0039Subtitle => 'Создать мнемоническую фразу с долями';

  @override
  String get genWalletOptionsPrivateKeyTitle => 'Приватный ключ';

  @override
  String get genWalletOptionsPrivateKeySubtitle => 'Создать только один приватный ключ';

  @override
  String get addWalletOptionsTitle => 'Добавить кошелек';

  @override
  String get addWalletOptionsNewWalletTitle => 'Новый кошелек';

  @override
  String get addWalletOptionsNewWalletSubtitle => 'Создать новый кошелек';

  @override
  String get addWalletOptionsExistingWalletTitle => 'Существующий кошелек';

  @override
  String get addWalletOptionsExistingWalletSubtitle => 'Импортировать кошелек с 24 секретными словами';

  @override
  String get addWalletOptionsPairWithLedgerTitle => 'Подключить Ledger';

  @override
  String get addWalletOptionsPairWithLedgerSubtitle => 'Аппаратный модуль, Bluetooth';

  @override
  String get addWalletOptionsOtherOptions => 'Другие варианты';

  @override
  String get addWalletOptionsWatchAccountTitle => 'Наблюдать за аккаунтом';

  @override
  String get addWalletOptionsWatchAccountSubtitle => 'Для мониторинга активности кошелька без фразы восстановления';

  @override
  String get currencyConversionTitle => 'Основная валюта';

  @override
  String get currencyConversionSearchHint => 'Поиск валют...';

  @override
  String get currencyConversionEngineTitle => 'Источник курсов валют';

  @override
  String get currencyConversionEngineDescription => 'Источник получения курсов валют';

  @override
  String get currencyConversionEngineSelectorTitle => 'Выбрать источник курсов валют';

  @override
  String get currencyConversionEngineNone => 'Нет';

  @override
  String get currencyConversionEngineNoneSubtitle => 'Источник не выбран';

  @override
  String get currencyConversionEngineCoingecko => 'Coingecko';

  @override
  String get currencyConversionEngineCoingeckoSubtitle => 'Получать курсы из Coingecko';

  @override
  String get restoreWalletOptionsTitle => 'Восстановить кошелек';

  @override
  String get restoreWalletOptionsBIP39Title => 'BIP39';

  @override
  String get restoreWalletOptionsBIP39Subtitle => 'Восстановить с помощью мнемонической фразы';

  @override
  String get restoreWalletOptionsSLIP0039Title => 'SLIP-0039';

  @override
  String get restoreWalletOptionsSLIP0039Subtitle => 'Восстановить с помощью разделенной мнемонической фразы';

  @override
  String get restoreWalletOptionsPrivateKeyTitle => 'Приватный ключ';

  @override
  String get restoreWalletOptionsPrivateKeySubtitle => 'Восстановить с помощью приватного ключа';

  @override
  String get restoreWalletOptionsQRCodeTitle => 'QR-код';

  @override
  String get restoreWalletOptionsQRCodeSubtitle => 'Восстановить кошелек сканированием QR-кода';

  @override
  String get argonSettingsModalContentLowMemoryTitle => 'Низкая память';

  @override
  String get argonSettingsModalContentLowMemorySubtitle => '64KB RAM, 3 итерации';

  @override
  String get argonSettingsModalContentLowMemoryDescription => 'Минимальное использование памяти, подходит для устройств с низкими характеристиками.';

  @override
  String get argonSettingsModalContentOwaspTitle => 'OWASP по умолчанию';

  @override
  String get argonSettingsModalContentOwaspSubtitle => '6.5MB RAM, 2 итерации';

  @override
  String get argonSettingsModalContentOwaspDescription => 'Рекомендовано OWASP для общего использования.';

  @override
  String get argonSettingsModalContentSecureTitle => 'Безопасный';

  @override
  String get argonSettingsModalContentSecureSubtitle => '256MB RAM, 4 итерации';

  @override
  String get argonSettingsModalContentSecureDescription => 'Высокая безопасность с увеличенной памятью и итерациями.';

  @override
  String get argonSettingsModalContentSecretHint => 'Введите секрет (опционально)';

  @override
  String get argonSettingsModalContentConfirmButton => 'Подтвердить';

  @override
  String get confirmTransactionContentPasswordHint => 'Пароль';

  @override
  String get confirmTransactionContentUnableToConfirm => 'Невозможно подтвердить';

  @override
  String get confirmTransactionContentConfirm => 'Подтвердить';

  @override
  String get confirmTransactionContentInsufficientBalance => 'Недостаточный баланс';

  @override
  String get confirmTransactionContentNoActiveAccount => 'Нет активного аккаунта';

  @override
  String get confirmTransactionContentFailedLoadTransfer => 'Не удалось загрузить детали перевода';

  @override
  String get authReason => 'Пожалуйста, пройдите аутентификацию';

  @override
  String get addChainModalContentWarning => 'Остерегайтесь сетевых мошенничеств и рисков безопасности.';

  @override
  String get addChainModalContentApprove => 'Подтвердить';

  @override
  String get addChainModalContentDetails => 'Детали';

  @override
  String get addChainModalContentNetworkName => 'Название сети:';

  @override
  String get addChainModalContentCurrencySymbol => 'Символ валюты:';

  @override
  String get addChainModalContentChainId => 'ID цепи:';

  @override
  String get addChainModalContentBlockExplorer => 'Обозреватель блоков:';

  @override
  String get addAddressModalTitle => 'Добавить контакт';

  @override
  String get addAddressModalDescription => 'Введите имя контакта и адрес кошелька для добавления в адресную книгу.';

  @override
  String get addAddressModalNameHint => 'Имя';

  @override
  String get addAddressModalAddressHint => 'Адрес кошелька';

  @override
  String get addAddressModalNameEmptyError => 'Имя не может быть пустым';

  @override
  String get addAddressModalAddressEmptyError => 'Адрес не может быть пустым';

  @override
  String get addAddressModalButton => 'Добавить контакт';

  @override
  String get tokenSelectModalContentSearchHint => 'Поиск';

  @override
  String get signMessageModalContentAuthReason => 'Пожалуйста, пройдите аутентификацию для подписи сообщения';

  @override
  String get signMessageModalContentFailedToSign => 'Не удалось подписать:';

  @override
  String get signMessageModalContentTitle => 'Подписать сообщение';

  @override
  String get signMessageModalContentDescription => 'Просмотрите и подпишите следующее сообщение своим кошельком.';

  @override
  String get signMessageModalContentDomain => 'Домен:';

  @override
  String get signMessageModalContentChainId => 'ID цепи:';

  @override
  String get signMessageModalContentContract => 'Контракт:';

  @override
  String get signMessageModalContentType => 'Тип:';

  @override
  String get signMessageModalContentNoData => 'Нет данных';

  @override
  String get signMessageModalContentPasswordHint => 'Пароль';

  @override
  String get signMessageModalContentProcessing => 'Обработка...';

  @override
  String get signMessageModalContentSign => 'Подписать сообщение';

  @override
  String get deleteWalletModalTitle => 'Удалить кошелек';

  @override
  String get deleteWalletModalWarning => 'Внимание: Это действие нельзя отменить. Ваш кошелек можно восстановить только с помощью секретной фразы. Если у вас нет к ней доступа, вы навсегда потеряете все средства, связанные с этим аккаунтом.';

  @override
  String get deleteWalletModalSecretPhraseWarning => 'Пожалуйста, убедитесь, что у вас есть доступ к вашей секретной фразе, прежде чем продолжить.';

  @override
  String get deleteWalletModalPasswordHint => 'Введите пароль';

  @override
  String get deleteWalletModalSubmit => 'Отправить';

  @override
  String get manageTokensModalContentSearchHint => 'Поиск';

  @override
  String get addressSelectModalContentTitle => 'Выберите адрес';

  @override
  String get addressSelectModalContentSearchHint => 'Поиск / Адрес / ENS';

  @override
  String get addressSelectModalContentUnknown => 'Неизвестно';

  @override
  String get addressSelectModalContentMyAccounts => 'Мои аккаунты';

  @override
  String get addressSelectModalContentAddressBook => 'Адресная книга';

  @override
  String get addressSelectModalContentHistory => 'История';

  @override
  String get changePasswordModalTitle => 'Изменить пароль';

  @override
  String get changePasswordModalDescription => 'Введите ваш текущий пароль и выберите новый пароль для обновления безопасности вашего кошелька.';

  @override
  String get changePasswordModalCurrentPasswordHint => 'Текущий пароль';

  @override
  String get changePasswordModalNewPasswordHint => 'Новый пароль';

  @override
  String get changePasswordModalConfirmPasswordHint => 'Подтвердите новый пароль';

  @override
  String get changePasswordModalCurrentPasswordEmptyError => 'Текущий пароль не может быть пустым';

  @override
  String get changePasswordModalPasswordLengthError => 'Пароль должен быть не менее 6 символов';

  @override
  String get changePasswordModalPasswordsMismatchError => 'Пароли не совпадают';

  @override
  String get changePasswordModalButton => 'Изменить пароль';

  @override
  String get confirmPasswordModalTitle => 'Подтвердить пароль';

  @override
  String get confirmPasswordModalDescription => 'Введите пароль для продолжения.';

  @override
  String get confirmPasswordModalHint => 'Пароль';

  @override
  String get confirmPasswordModalEmptyError => 'Пароль не может быть пустым';

  @override
  String get confirmPasswordModalIncorrectError => 'Неверный пароль';

  @override
  String get confirmPasswordModalGenericError => 'Ошибка:';

  @override
  String get confirmPasswordModalButton => 'Подтвердить';

  @override
  String get qrScannerModalContentTitle => 'Сканировать';

  @override
  String get qrScannerModalContentCameraInitError => 'Ошибка инициализации камеры:';

  @override
  String get qrScannerModalContentTorchError => 'Не удалось переключить вспышку:';

  @override
  String get qrScannerModalContentOpenSettings => 'Открыть настройки';

  @override
  String get chainInfoModalContentNetworkInfoTitle => 'Информация о сети';

  @override
  String get chainInfoModalContentChainLabel => 'Цепь';

  @override
  String get chainInfoModalContentShortNameLabel => 'Короткое название';

  @override
  String get chainInfoModalContentChainIdLabel => 'ID цепи';

  @override
  String get chainInfoModalContentSlip44Label => 'Slip44';

  @override
  String get chainInfoModalContentChainIdsLabel => 'ID цепей';

  @override
  String get chainInfoModalContentTestnetLabel => 'Тестовая сеть';

  @override
  String get chainInfoModalContentYes => 'Да';

  @override
  String get chainInfoModalContentNo => 'Нет';

  @override
  String get chainInfoModalContentDiffBlockTimeLabel => 'Время блока Diff';

  @override
  String get chainInfoModalContentFallbackEnabledLabel => 'Резервный режим включен';

  @override
  String get chainInfoModalContentDecimalsLabel => 'Десятичные знаки';

  @override
  String get chainInfoModalContentRpcNodesTitle => 'RPC узлы';

  @override
  String get chainInfoModalContentExplorersTitle => 'Обозреватели';

  @override
  String get switchChainNetworkContentTitle => 'Выбрать сеть';

  @override
  String get switchChainNetworkContentButton => 'Переключить сеть';

  @override
  String get switchChainNetworkContentTestnetLabel => 'Тестовая сеть';

  @override
  String get switchChainNetworkContentIdLabel => 'ID:';

  @override
  String get watchAssetModalContentTitle => 'Добавить предложенный токен';

  @override
  String get watchAssetModalContentDescription => 'Просмотрите и добавьте следующий токен, предложенный приложением.';

  @override
  String get watchAssetModalContentTokenLabel => 'Токен';

  @override
  String get watchAssetModalContentBalanceLabel => 'Баланс';

  @override
  String get watchAssetModalContentLoadingButton => 'Баланс...';

  @override
  String get watchAssetModalContentAddButton => 'Добавить';

  @override
  String get connectedDappsModalSearchHint => 'Поиск DApps';

  @override
  String get connectedDappsModalNoDapps => 'Нет подключенных DApps';

  @override
  String dappListItemConnected(Object time) {
    return 'Подключено $time';
  }

  @override
  String get dappListItemJustNow => 'только что';

  @override
  String get ledgerConnectDialogWalletNameHint => 'Название кошелька';

  @override
  String get ledgerConnectDialogEmptyWalletName => 'Название кошелька не может быть пустым';

  @override
  String get ledgerConnectDialogWalletNameTooLong => 'Название кошелька слишком длинное';

  @override
  String get ledgerConnectDialogConnectButton => 'Подключить';

  @override
  String get secretRecoveryModalRevealPhraseTitle => 'Показать фразу восстановления';

  @override
  String get secretRecoveryModalRevealPhraseDescription => 'Если вы когда-либо смените браузер или компьютер, вам понадобится эта секретная фраза восстановления для доступа к вашим аккаунтам. Сохраните её в безопасном и секретном месте.';

  @override
  String get secretRecoveryModalRevealPhraseButton => 'Показать';

  @override
  String get secretRecoveryModalShowKeysTitle => 'Показать приватные ключи';

  @override
  String get secretRecoveryModalShowKeysDescription => 'Внимание: Никогда не раскрывайте этот ключ. Любой, кто имеет ваши приватные ключи, может украсть любые активы, хранящиеся на вашем аккаунте.';

  @override
  String get secretRecoveryModalShowKeysButton => 'Экспорт';

  @override
  String get backupConfirmationContentTitle => 'Подтверждение резервного копирования';

  @override
  String get backupConfirmationContentWrittenDown => 'Я записал всё';

  @override
  String get backupConfirmationContentSafelyStored => 'Я надежно сохранил резервную копию';

  @override
  String get backupConfirmationContentWontLose => 'Я уверен, что не потеряю резервную копию';

  @override
  String get backupConfirmationContentNotShare => 'Я понимаю, что нельзя делиться этими словами с кем-либо';

  @override
  String get counterMaxValueError => 'Достигнуто максимальное значение';

  @override
  String get counterMinValueError => 'Достигнуто минимальное значение';

  @override
  String get biometricSwitchFaceId => 'Включить Face ID';

  @override
  String get biometricSwitchFingerprint => 'Включить отпечаток пальца';

  @override
  String get biometricSwitchBiometric => 'Включить биометрический вход';

  @override
  String get biometricSwitchPinCode => 'Включить PIN-код устройства';

  @override
  String get gasFeeOptionLow => 'Низкий';

  @override
  String get gasFeeOptionMarket => 'Рыночный';

  @override
  String get gasFeeOptionAggressive => 'Агрессивный';

  @override
  String get gasDetailsEstimatedGas => 'Расчетный газ:';

  @override
  String get gasDetailsGasPrice => 'Цена газа:';

  @override
  String get gasDetailsBaseFee => 'Базовая комиссия:';

  @override
  String get gasDetailsPriorityFee => 'Приоритетная комиссия:';

  @override
  String get gasDetailsMaxFee => 'Максимальная комиссия:';

  @override
  String get tokenTransferAmountUnknown => 'Неизвестно';
}
