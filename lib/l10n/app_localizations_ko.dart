// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'ZilPay 지갑';

  @override
  String get initialPagerestoreZilPay => 'ZilPay 1.0 복원!';

  @override
  String get initialPagegetStarted => '시작하기';

  @override
  String get restoreRKStorageTitle => 'ZilPay 1.0에서 2.0으로 마이그레이션';

  @override
  String get restoreRKStorageAccountsPrompt => 'ZilPay 2.0으로 마이그레이션할 계정. 비밀번호 입력.';

  @override
  String get restoreRKStoragePasswordHint => '비밀번호';

  @override
  String get restoreRKStorageEnterPassword => '비밀번호 입력';

  @override
  String get restoreRKStorageErrorPrefix => '오류:';

  @override
  String get restoreRKStorageRestoreButton => '복원';

  @override
  String get restoreRKStorageSkipButton => '건너뛰기';

  @override
  String get accountItemBalanceLabel => '잔액:';

  @override
  String get sendTokenPageTitle => '';

  @override
  String get sendTokenPageSubmitButton => '제출';

  @override
  String get aboutPageTitle => '정보';

  @override
  String get aboutPageAppName => 'ZilPay';

  @override
  String get aboutPageAppDescription => '안전한 블록체인 지갑';

  @override
  String get aboutPageAppInfoTitle => '앱 정보';

  @override
  String get aboutPageVersionLabel => '버전';

  @override
  String get aboutPageBuildDateLabel => '빌드 날짜';

  @override
  String get aboutPageBuildDateValue => '2025년 3월 10일';

  @override
  String get aboutPagePlatformLabel => '플랫폼';

  @override
  String get aboutPageDeveloperTitle => '개발자';

  @override
  String get aboutPageAuthorLabel => '저자';

  @override
  String get aboutPageAuthorValue => 'Rinat (hicaru)';

  @override
  String get aboutPageWebsiteLabel => '웹사이트';

  @override
  String get aboutPageWebsiteValue => 'https://zilpay.io';

  @override
  String get aboutPageLegalTitle => '법적 사항';

  @override
  String get aboutPagePrivacyPolicy => '개인정보 보호정책';

  @override
  String get aboutPageTermsOfService => '서비스 약관';

  @override
  String get aboutPageLicenses => '라이선스';

  @override
  String get aboutPageLegalese => '© 2025 ZilPay. 모든 권리 보유.';

  @override
  String get languagePageTitle => '언어';

  @override
  String get languagePageSystem => '시스템';

  @override
  String get secretKeyGeneratorPageTitle => '비밀 키';

  @override
  String get secretKeyGeneratorPagePrivateKey => '개인 키';

  @override
  String get secretKeyGeneratorPagePublicKey => '공개 키';

  @override
  String get secretKeyGeneratorPageBackupCheckbox => '비밀 키 백업 완료';

  @override
  String get secretKeyGeneratorPageNextButton => '다음';

  @override
  String get walletPageTitle => '';

  @override
  String get walletPageWalletNameHint => '지갑 이름';

  @override
  String get walletPagePreferencesTitle => '지갑 설정';

  @override
  String get walletPageManageConnections => '연결 관리';

  @override
  String get walletPageBackup => '백업';

  @override
  String get walletPageDeleteWallet => '지갑 삭제';

  @override
  String get walletPageBiometricReason => '생체 인증 활성화';

  @override
  String get networkPageTitle => '';

  @override
  String get networkPageShowTestnet => '테스트넷 표시';

  @override
  String get networkPageSearchHint => '검색';

  @override
  String get networkPageAddedNetworks => '추가된 네트워크';

  @override
  String get networkPageAvailableNetworks => '사용 가능한 네트워크';

  @override
  String get networkPageAddError => '네트워크 추가 실패: ';

  @override
  String get receivePageTitle => '수신';

  @override
  String receivePageWarning(Object chainName, Object tokenSymbol) {
    return '이 주소로 $chainName($tokenSymbol) 자산만 보내세요. 다른 자산은 영구적으로 손실됩니다.';
  }

  @override
  String get receivePageAccountNameHint => '계정 이름';

  @override
  String get receivePageAmountDialogTitle => '금액 입력';

  @override
  String get receivePageAmountDialogHint => '0.0';

  @override
  String get receivePageAmountDialogCancel => '취소';

  @override
  String get receivePageAmountDialogConfirm => '확인';

  @override
  String get securityPageTitle => '보안';

  @override
  String get securityPageNetworkPrivacy => '네트워크 프라이버시';

  @override
  String get securityPageEnsDomains => '주소 표시줄에 ENS 도메인 표시';

  @override
  String get securityPageEnsDescription => '이 기능을 사용하면 IP 주소가 IPFS 타사 서비스에 노출될 수 있습니다.';

  @override
  String get securityPageIpfsGateway => 'IPFS 게이트웨이';

  @override
  String get securityPageIpfsDescription => 'ZIlPay는 타사 서비스를 사용하여 IPFS에 저장된 NFT 이미지를 표시하고, 브라우저 주소 표시줄에 입력된 ENS(ZNS) 주소 관련 정보를 표시하며, 다양한 토큰 아이콘을 가져옵니다. 이를 사용할 때 IP 주소가 노출될 수 있습니다.';

  @override
  String get securityPageTokensFetcherTitle => '토큰 가져오기';

  @override
  String get securityPageTokensFetcherDescription => '활성화되면 토큰이 서버에서 자동으로 가져와 추가될 수 있습니다.';

  @override
  String get securityPageNodeRanking => '노드 랭킹';

  @override
  String get securityPageNodeDescription => '최적 노드를 가져오기 위해 ZilPay 서버에 요청';

  @override
  String get securityPageEncryptionLevel => '암호화 수준';

  @override
  String get securityPageProtection => '보호';

  @override
  String get securityPageCpuLoad => 'CPU 부하';

  @override
  String get securityPageAes256 => 'AES256';

  @override
  String get securityPageKuznechikGost => 'KUZNECHIK-GOST';

  @override
  String get securityPageNtruPrime => 'NTRUPrime';

  @override
  String get securityPageCyber => 'Cyber';

  @override
  String get securityPageUnknown => '알 수 없음';

  @override
  String get webViewPageDntLabel => 'DNT';

  @override
  String get webViewPageIncognitoLabel => '시크릿 모드';

  @override
  String get webViewPageLoadError => '로드 실패';

  @override
  String get webViewPageTryAgain => '다시 시도';

  @override
  String get secretPhraseGeneratorPageTitle => '새 지갑';

  @override
  String get secretPhraseGeneratorPageBackupCheckbox => '단어 백업 완료';

  @override
  String get secretPhraseGeneratorPageNextButton => '다음';

  @override
  String get homePageErrorTitle => '신호 없음';

  @override
  String get homePageSendButton => '보내기';

  @override
  String get homePageReceiveButton => '수신';

  @override
  String get revealSecretKeyTitle => '비밀 키 공개';

  @override
  String get revealSecretKeyPasswordHint => '비밀번호';

  @override
  String get revealSecretKeyInvalidPassword => '잘못된 비밀번호, 오류:';

  @override
  String get revealSecretKeySubmitButton => '제출';

  @override
  String get revealSecretKeyDoneButton => '완료';

  @override
  String get revealSecretKeyScamAlertTitle => '사기 경고';

  @override
  String get revealSecretKeyScamAlertMessage => '비밀 키를 누구와도 공유하지 마세요. 웹사이트에 입력하지 마세요.';

  @override
  String get setupNetworkSettingsPageTestnetSwitch => '테스트넷';

  @override
  String get setupNetworkSettingsPageSearchHint => '검색';

  @override
  String get setupNetworkSettingsPageNoNetworks => '사용 가능한 네트워크 없음';

  @override
  String setupNetworkSettingsPageNoResults(Object searchQuery) {
    return '\"$searchQuery\"에 대한 네트워크 없음';
  }

  @override
  String get setupNetworkSettingsPageNextButton => '다음';

  @override
  String get setupNetworkSettingsPageTestnetLabel => '테스트넷';

  @override
  String get setupNetworkSettingsPageMainnetLabel => '메인넷';

  @override
  String get setupNetworkSettingsPageChainIdLabel => '체인 ID:';

  @override
  String get setupNetworkSettingsPageTokenLabel => '토큰:';

  @override
  String get setupNetworkSettingsPageExplorerLabel => '탐색기:';

  @override
  String get appearanceSettingsPageTitle => '모양 설정';

  @override
  String get appearanceSettingsPageCompactNumbersTitle => '압축 숫자';

  @override
  String get appearanceSettingsPageCompactNumbersDescription => '압축 숫자 표시 활성화 (예: 20K 대신 20,000).';

  @override
  String get appearanceSettingsPageDeviceSettingsTitle => '기기 설정';

  @override
  String get appearanceSettingsPageDeviceSettingsSubtitle => '시스템 기본값';

  @override
  String get appearanceSettingsPageDeviceSettingsDescription => '기기 모양에 기본 설정. 시스템 설정에 따라 지갑 테마가 자동 조정됩니다.';

  @override
  String get appearanceSettingsPageDarkModeTitle => '다크 모드';

  @override
  String get appearanceSettingsPageDarkModeSubtitle => '항상 다크';

  @override
  String get appearanceSettingsPageDarkModeDescription => '기기 설정과 상관없이 다크 테마 항상 활성화.';

  @override
  String get appearanceSettingsPageLightModeTitle => '라이트 모드';

  @override
  String get appearanceSettingsPageLightModeSubtitle => '항상 라이트';

  @override
  String get appearanceSettingsPageLightModeDescription => '기기 설정과 상관없이 라이트 테마 항상 활성화.';

  @override
  String get loginPageBiometricReason => '인증하세요';

  @override
  String loginPageWalletTitle(Object index) {
    return '지갑 $index';
  }

  @override
  String get loginPagePasswordHint => '비밀번호';

  @override
  String get loginPageUnlockButton => '잠금 해제';

  @override
  String get loginPageWelcomeBack => '환영합니다';

  @override
  String get secretKeyRestorePageTitle => '비밀 키 복원';

  @override
  String get secretKeyRestorePageHint => '개인 키';

  @override
  String get secretKeyRestorePageInvalidFormat => '잘못된 개인 키 형식';

  @override
  String get secretKeyRestorePageKeyTitle => '개인 키';

  @override
  String get secretKeyRestorePageBackupLabel => '비밀 키 백업 완료';

  @override
  String get secretKeyRestorePageNextButton => '다음';

  @override
  String get addAccountPageTitle => '새 계정 추가';

  @override
  String get addAccountPageSubtitle => 'BIP39 계정 생성';

  @override
  String addAccountPageDefaultName(Object index) {
    return '계정 $index';
  }

  @override
  String get addAccountPageNameHint => '계정 이름';

  @override
  String get addAccountPageBip39Index => 'BIP39 인덱스';

  @override
  String get addAccountPageUseBiometrics => '생체 인식 사용';

  @override
  String get addAccountPagePasswordHint => '비밀번호';

  @override
  String get addAccountPageZilliqaLegacy => 'Zilliqa 레거시';

  @override
  String get addAccountPageBiometricReason => '새 계정 생성 인증';

  @override
  String addAccountPageBiometricError(Object error) {
    return '생체 인증 실패: $error';
  }

  @override
  String addAccountPageIndexExists(Object index) {
    return '인덱스 $index 계정 이미 존재';
  }

  @override
  String get addAccountPageBiometricFailed => '생체 인증 실패';

  @override
  String addAccountPageCreateFailed(Object error) {
    return '계정 생성 실패: $error';
  }

  @override
  String get addressBookPageTitle => '주소록';

  @override
  String get addressBookPageEmptyMessage => '연락처와 지갑 주소가\n여기에 표시됩니다.';

  @override
  String get addressBookPageDeleteConfirmationTitle => '연락처 삭제';

  @override
  String addressBookPageDeleteConfirmationMessage(String contactName) {
    return '주소록에서 $contactName을(를) 삭제하시겠습니까?';
  }

  @override
  String addressBookPageDeleteTooltip(String contactName) {
    return '$contactName 삭제';
  }

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get browserPageExploreTab => '탐색';

  @override
  String get browserPageNoExploreApps => '탐색할 앱 없음';

  @override
  String browserPageSearchHint(Object engine) {
    return '$engine으로 검색 또는 주소 입력';
  }

  @override
  String get browserPageNoConnectedApps => '연결된 앱 없음';

  @override
  String get historyPageTitle => '거래 내역';

  @override
  String get historyPageNoTransactions => '거래 없음';

  @override
  String get historyPageSearchHint => '거래 검색...';

  @override
  String get notificationsSettingsPageTitle => '알림';

  @override
  String get notificationsSettingsPagePushTitle => '푸시 알림';

  @override
  String get notificationsSettingsPagePushDescription => '거래 전송 및 확인 시 알림, 연결된 앱 알림.';

  @override
  String get notificationsSettingsPageWalletsTitle => '지갑';

  @override
  String get notificationsSettingsPageWalletsDescription => '지갑 알림';

  @override
  String get notificationsSettingsPageWalletPrefix => '지갑';

  @override
  String get revealSecretPhraseTitle => '비밀 구문 공개';

  @override
  String get revealSecretPhrasePasswordHint => '비밀번호';

  @override
  String get revealSecretPhraseInvalidPassword => '잘못된 비밀번호, 오류:';

  @override
  String get revealSecretPhraseRevealAfter => '비밀 구문 공개 시간:';

  @override
  String get revealSecretPhraseSubmitButton => '제출';

  @override
  String get revealSecretPhraseDoneButton => '완료';

  @override
  String get revealSecretPhraseScamAlertTitle => '사기 경고';

  @override
  String get revealSecretPhraseScamAlertDescription => '비밀 구문을 누구와도 공유하지 마세요. 웹사이트에 입력하지 마세요.';

  @override
  String get cipherSettingsPageTitle => '암호화 설정';

  @override
  String get cipherSettingsPageAdvancedButton => '고급';

  @override
  String get cipherSettingsPageStandardTitle => '표준 암호화';

  @override
  String get cipherSettingsPageStandardSubtitle => 'AES-256 + KUZNECHIK-GOST';

  @override
  String get cipherSettingsPageStandardDescription => 'AES-256과 GOST 표준 KUZNECHIK 기본 암호화.';

  @override
  String get cipherSettingsPageHybridTitle => '하이브리드 암호화';

  @override
  String get cipherSettingsPageHybridSubtitle => 'CYBER + KUZNECHIK-GOST';

  @override
  String get cipherSettingsPageHybridDescription => 'CYBER와 KUZNECHIK-GOST 알고리즘 결합 하이브리드 암호화.';

  @override
  String get cipherSettingsPageQuantumTitle => '양자 내성';

  @override
  String get cipherSettingsPageQuantumSubtitle => 'CYBER + KUZNECHIK + NTRUP1277';

  @override
  String get cipherSettingsPageQuantumDescription => 'NTRUP1277 고급 양자 내성 암호화.';

  @override
  String get cipherSettingsPageQuantumWarning => '양자 내성 암호화는 성능에 영향을 줄 수 있습니다';

  @override
  String get cipherSettingsPageConfirmButton => '확인';

  @override
  String get secretPhraseVerifyPageTitle => '비밀 확인';

  @override
  String get secretPhraseVerifyPageSubtitle => 'Bip39 비밀 확인';

  @override
  String get secretPhraseVerifyPageNextButton => '다음';

  @override
  String get restoreSecretPhrasePageTitle => '지갑 복원';

  @override
  String get restoreSecretPhrasePageRestoreButton => '복원';

  @override
  String get checksumValidationFailed => '체크섬 검증 실패';

  @override
  String get proceedDespiteInvalidChecksum => '체크섬 오류에도 불구하고 계속?';

  @override
  String get settingsPageTitle => '설정';

  @override
  String get settingsPageZilliqaLegacy => 'Zilliqa 레거시';

  @override
  String get settingsPageCurrency => '통화';

  @override
  String get settingsPageAppearance => '모양';

  @override
  String get settingsPageNotifications => '알림';

  @override
  String get settingsPageAddressBook => '주소록';

  @override
  String get settingsPageSecurityPrivacy => '보안 및 프라이버시';

  @override
  String get settingsPageNetworks => '네트워크';

  @override
  String get settingsPageLanguage => '언어';

  @override
  String get settingsPageBrowser => '브라우저';

  @override
  String get settingsPageTelegram => 'Telegram';

  @override
  String get settingsPageTwitter => 'Twitter';

  @override
  String get settingsPageGitHub => 'GitHub';

  @override
  String get settingsPageAbout => '정보';

  @override
  String get passwordSetupPageTitle => '비밀번호 설정';

  @override
  String get passwordSetupPageSubtitle => '비밀번호 생성';

  @override
  String get passwordSetupPageWalletNameHint => '지갑 이름';

  @override
  String get passwordSetupPagePasswordHint => '비밀번호';

  @override
  String get passwordSetupPageConfirmPasswordHint => '비밀번호 확인';

  @override
  String get passwordSetupPageEmptyWalletNameError => '지갑 이름 비울 수 없음';

  @override
  String get passwordSetupPageLongWalletNameError => '지갑 이름 너무 길음';

  @override
  String get passwordSetupPageShortPasswordError => '비밀번호 최소 8자';

  @override
  String get passwordSetupPageMismatchPasswordError => '비밀번호 불일치';

  @override
  String get passwordSetupPageLegacyLabel => '레거시';

  @override
  String get passwordSetupPageCreateButton => '비밀번호 생성';

  @override
  String get passwordSetupPageAuthReason => '빠른 액세스 활성화 인증';

  @override
  String get passwordSetupPageSeedType => '시드';

  @override
  String get passwordSetupPageKeyType => '키';

  @override
  String get passwordSetupPageUniversalNetwork => '범용';

  @override
  String get browserSettingsTitle => '브라우저 설정';

  @override
  String get browserSettingsBrowserOptions => '브라우저 옵션';

  @override
  String get browserSettingsSearchEngine => '검색 엔진';

  @override
  String get browserSettingsSearchEngineDescription => '기본 검색 엔진 구성';

  @override
  String get browserSettingsSearchEngineTitle => '검색 엔진';

  @override
  String get browserSettingsContentBlocking => '콘텐츠 차단';

  @override
  String get browserSettingsContentBlockingDescription => '콘텐츠 차단 설정 구성';

  @override
  String get browserSettingsContentBlockingTitle => '콘텐츠 차단';

  @override
  String get browserSettingsPrivacySecurity => '프라이버시 및 보안';

  @override
  String get browserSettingsCookies => '쿠키';

  @override
  String get browserSettingsCookiesDescription => '웹사이트가 쿠키 저장 및 읽기 허용';

  @override
  String get browserSettingsDoNotTrack => '추적 금지';

  @override
  String get browserSettingsDoNotTrackDescription => '웹사이트에 브라우징 추적 금지 요청';

  @override
  String get browserSettingsIncognitoMode => '시크릿 모드';

  @override
  String get browserSettingsIncognitoModeDescription => '기록 또는 쿠키 저장 없이 브라우징';

  @override
  String get browserSettingsPerformance => '성능';

  @override
  String get browserSettingsCache => '캐시';

  @override
  String get browserSettingsClearData => '데이터 지우기';

  @override
  String get browserSettingsClear => '지우기';

  @override
  String get browserSettingsClearCookies => '쿠키 지우기';

  @override
  String get browserSettingsClearCookiesDescription => '웹사이트가 저장한 모든 쿠키 삭제';

  @override
  String get browserSettingsClearCache => '캐시 지우기';

  @override
  String get browserSettingsClearCacheDescription => '브라우징 중 저장된 임시 파일 및 이미지 삭제';

  @override
  String get browserSettingsClearLocalStorage => '로컬 스토리지 지우기';

  @override
  String get browserSettingsClearLocalStorageDescription => '기기에 저장된 웹사이트 데이터 삭제';

  @override
  String get browserSettingsCacheDescription => '더 빠른 로드를 위해 웹사이트 데이터 저장';

  @override
  String get genWalletOptionsTitle => '지갑 생성';

  @override
  String get genWalletOptionsBIP39Title => 'BIP39';

  @override
  String get genWalletOptionsBIP39Subtitle => 'Mnemonic 구문 생성';

  @override
  String get genWalletOptionsPrivateKeyTitle => '개인 키';

  @override
  String get genWalletOptionsPrivateKeySubtitle => '하나의 개인 키 생성';

  @override
  String get addWalletOptionsTitle => '지갑 추가';

  @override
  String get addWalletOptionsNewWalletTitle => '새 지갑';

  @override
  String get addWalletOptionsNewWalletSubtitle => '새 지갑 생성';

  @override
  String get addWalletOptionsExistingWalletTitle => '기존 지갑';

  @override
  String get addWalletOptionsExistingWalletSubtitle => '24개의 비밀 복구 단어로 지갑 가져오기';

  @override
  String get addWalletOptionsPairWithLedgerTitle => 'Ledger 페어링';

  @override
  String get addWalletOptionsPairWithLedgerSubtitle => '하드웨어 모듈, Bluetooth';

  @override
  String get addWalletOptionsOtherOptions => '기타 옵션';

  @override
  String get addWalletOptionsWatchAccountTitle => '감시 계정';

  @override
  String get addWalletOptionsWatchAccountSubtitle => '복구 구문 없이 지갑 활동 모니터링';

  @override
  String get currencyConversionTitle => '기본 통화';

  @override
  String get currencyConversionSearchHint => '통화 검색...';

  @override
  String get currencyConversionEngineTitle => '통화 엔진';

  @override
  String get currencyConversionEngineDescription => '통화 환율 가져오기 엔진';

  @override
  String get currencyConversionEngineSelectorTitle => '통화 엔진 선택';

  @override
  String get currencyConversionEngineNone => '없음';

  @override
  String get currencyConversionEngineNoneSubtitle => '엔진 선택 안 함';

  @override
  String get currencyConversionEngineCoingecko => 'Coingecko';

  @override
  String get currencyConversionEngineCoingeckoSubtitle => 'Coingecko에서 환율 가져오기';

  @override
  String get restoreWalletOptionsTitle => '지갑 복원';

  @override
  String get restoreWalletOptionsBIP39Title => 'BIP39';

  @override
  String get restoreWalletOptionsBIP39Subtitle => 'Mnemonic 구문으로 복원';

  @override
  String get restoreWalletOptionsPrivateKeyTitle => '개인 키';

  @override
  String get restoreWalletOptionsPrivateKeySubtitle => '개인 키로 복원';

  @override
  String get restoreWalletOptionsKeyStoreTitle => '키스토어 파일';

  @override
  String get restoreWalletOptionsKeyStoreSubtitle => '비밀번호 암호화 백업 파일로 지갑 복원';

  @override
  String get restoreWalletOptionsQRCodeTitle => 'QR코드';

  @override
  String get restoreWalletOptionsQRCodeSubtitle => 'QR코드 스캔으로 지갑 복원';

  @override
  String get argonSettingsModalContentLowMemoryTitle => '저 메모리';

  @override
  String get argonSettingsModalContentLowMemorySubtitle => '64KB RAM, 3 반복';

  @override
  String get argonSettingsModalContentLowMemoryDescription => '저사양 기기에 적합한 최소 메모리 사용.';

  @override
  String get argonSettingsModalContentOwaspTitle => 'OWASP 기본';

  @override
  String get argonSettingsModalContentOwaspSubtitle => '6.5MB RAM, 2 반복';

  @override
  String get argonSettingsModalContentOwaspDescription => 'OWASP에서 일반 용도로 추천.';

  @override
  String get argonSettingsModalContentSecureTitle => '보안';

  @override
  String get argonSettingsModalContentSecureSubtitle => '256MB RAM, 4 반복';

  @override
  String get argonSettingsModalContentSecureDescription => '메모리 및 반복 증가 고보안.';

  @override
  String get argonSettingsModalContentSecretHint => '비밀 입력 (선택)';

  @override
  String get argonSettingsModalContentConfirmButton => '확인';

  @override
  String get confirmTransactionContentPasswordHint => '비밀번호';

  @override
  String get confirmTransactionContentUnableToConfirm => '확인 불가';

  @override
  String get confirmTransactionContentConfirm => '확인';

  @override
  String get confirmTransactionContentNoActiveAccount => '활성 계정 없음';

  @override
  String get confirmTransactionContentFailedLoadTransfer => '전송 세부 정보 로드 실패';

  @override
  String get confirmTransactionEditGasButtonText => '가스 수정';

  @override
  String get authReason => '인증하세요';

  @override
  String get addChainModalContentWarning => '네트워크 사기 및 보안 위험 주의.';

  @override
  String get addChainModalContentApprove => '승인';

  @override
  String get addChainModalContentDetails => '세부 정보';

  @override
  String get addChainModalContentNetworkName => '네트워크 이름:';

  @override
  String get addChainModalContentCurrencySymbol => '통화 기호:';

  @override
  String get addChainModalContentChainId => '체인 ID:';

  @override
  String get addChainModalContentBlockExplorer => '블록 탐색기:';

  @override
  String get addAddressModalTitle => '연락처 추가';

  @override
  String get addAddressModalDescription => '주소록에 추가할 연락처 이름과 지갑 주소 입력.';

  @override
  String get addAddressModalNameHint => '이름';

  @override
  String get addAddressModalAddressHint => '지갑 주소';

  @override
  String get addAddressModalNameEmptyError => '이름 비울 수 없음';

  @override
  String get addAddressModalAddressEmptyError => '주소 비울 수 없음';

  @override
  String get addAddressModalButton => '연락처 추가';

  @override
  String get tokenSelectModalContentSearchHint => '검색';

  @override
  String get signMessageModalContentAuthReason => '메시지 서명 인증';

  @override
  String signMessageModalContentFailedToSign(Object error) {
    return '서명 실패: $error';
  }

  @override
  String get signMessageModalContentTitle => '메시지 서명';

  @override
  String get signMessageModalContentDescription => '지갑으로 다음 메시지 검토 및 서명.';

  @override
  String get signMessageModalContentDomain => '도메인:';

  @override
  String get signMessageModalContentChainId => '체인 ID:';

  @override
  String get signMessageModalContentContract => '계약:';

  @override
  String get signMessageModalContentType => '유형:';

  @override
  String get signMessageModalContentNoData => '데이터 없음';

  @override
  String get signMessageModalContentPasswordHint => '비밀번호';

  @override
  String get signMessageModalContentProcessing => '처리 중...';

  @override
  String get signMessageModalContentSign => '메시지 서명';

  @override
  String get signMessageModalContentScanning => 'Ledger 기기 스캔 중...';

  @override
  String get signMessageModalContentNoLedgerDevices => 'Ledger 기기 없음';

  @override
  String get signMessageModalContentWalletNotSelected => '지갑 선택 안 함';

  @override
  String get signMessageModalContentLedgerNotSelected => 'Ledger 기기 선택 안 함';

  @override
  String signMessageModalContentFailedToScanLedger(Object error) {
    return 'Ledger 기기 스캔 실패: $error';
  }

  @override
  String signMessageModalContentFailedToSignMessage(Object error) {
    return '메시지 서명 실패: $error';
  }

  @override
  String get signMessageModalContentBluetoothOff => 'Bluetooth 꺼짐. Ledger 기기 스캔을 위해 활성화하세요.';

  @override
  String get deleteWalletModalTitle => '지갑 삭제';

  @override
  String get deleteWalletModalWarning => '경고: 이 작업 취소 불가. 비밀 구문으로만 지갑 복구 가능. 액세스 없으면 계정 관련 모든 자금 영구 손실.';

  @override
  String get deleteWalletModalSecretPhraseWarning => '진행 전에 비밀 구문 액세스 확인하세요.';

  @override
  String get deleteWalletModalPasswordHint => '비밀번호 입력';

  @override
  String get deleteWalletModalSubmit => '파괴';

  @override
  String get addressSelectModalContentTitle => '주소 선택';

  @override
  String get addressSelectModalContentSearchHint => '검색 / 주소 / ENS';

  @override
  String get addressSelectModalContentUnknown => '알 수 없음';

  @override
  String get addressSelectModalContentMyAccounts => '내 계정';

  @override
  String get addressSelectModalContentAddressBook => '주소록';

  @override
  String get addressSelectModalContentHistory => '기록';

  @override
  String get addressSelectModalContentSender => '발신자';

  @override
  String get changePasswordModalTitle => '비밀번호 변경';

  @override
  String get changePasswordModalDescription => '현재 비밀번호 입력 후 새 비밀번호 선택하여 지갑 보안 업데이트.';

  @override
  String get changePasswordModalCurrentPasswordHint => '현재 비밀번호';

  @override
  String get changePasswordModalNewPasswordHint => '새 비밀번호';

  @override
  String get changePasswordModalConfirmPasswordHint => '새 비밀번호 확인';

  @override
  String get changePasswordModalCurrentPasswordEmptyError => '현재 비밀번호 비울 수 없음';

  @override
  String get changePasswordModalPasswordLengthError => '비밀번호 최소 6자';

  @override
  String get changePasswordModalPasswordsMismatchError => '비밀번호 불일치';

  @override
  String get changePasswordModalButton => '비밀번호 변경';

  @override
  String get confirmPasswordModalTitle => '비밀번호 확인';

  @override
  String get confirmPasswordModalDescription => '계속하려면 비밀번호 입력.';

  @override
  String get confirmPasswordModalHint => '비밀번호';

  @override
  String get confirmPasswordModalEmptyError => '비밀번호 비울 수 없음';

  @override
  String get confirmPasswordModalGenericError => '오류:';

  @override
  String get confirmPasswordModalButton => '확인';

  @override
  String get qrScannerModalContentTitle => '스캔';

  @override
  String get qrScannerModalContentCameraInitError => '카메라 초기화 오류:';

  @override
  String get qrScannerModalContentTorchError => '토치 토글 실패:';

  @override
  String get qrScannerModalContentOpenSettings => '설정 열기';

  @override
  String get chainInfoModalContentTokenTitle => '네트워크 토큰';

  @override
  String get chainInfoModalContentNetworkInfoTitle => '네트워크 정보';

  @override
  String get chainInfoModalContentChainLabel => '체인';

  @override
  String get chainInfoModalContentShortNameLabel => '짧은 이름';

  @override
  String get chainInfoModalContentChainIdLabel => '체인 ID';

  @override
  String get chainInfoModalContentSlip44Label => 'Slip44';

  @override
  String get chainInfoModalContentChainIdsLabel => '체인 ID';

  @override
  String get chainInfoModalContentTestnetLabel => '테스트넷';

  @override
  String get chainInfoModalContentYes => '예';

  @override
  String get chainInfoModalContentNo => '아니오';

  @override
  String get chainInfoModalContentDiffBlockTimeLabel => 'Diff 블록 시간';

  @override
  String get chainInfoModalContentFallbackEnabledLabel => '폴백 활성화';

  @override
  String get chainInfoModalContentDecimalsLabel => '소수점';

  @override
  String get chainInfoModalContentRpcNodesTitle => 'RPC 노드';

  @override
  String get chainInfoModalContentExplorersTitle => '탐색기';

  @override
  String get chainInfoModalContentDeleteProviderTitle => '네트워크 삭제';

  @override
  String get chainInfoModalContentSwipeToDelete => '네트워크 삭제';

  @override
  String get switchChainNetworkContentTitle => '네트워크 선택';

  @override
  String get switchChainNetworkContentButton => '네트워크 전환';

  @override
  String get switchChainNetworkContentTestnetLabel => '테스트넷';

  @override
  String get switchChainNetworkContentIdLabel => 'ID:';

  @override
  String get watchAssetModalContentTitle => '제안 토큰 추가';

  @override
  String get watchAssetModalContentDescription => '앱에서 제안된 다음 토큰 검토 및 추가.';

  @override
  String get watchAssetModalContentTokenLabel => '토큰';

  @override
  String get watchAssetModalContentBalanceLabel => '잔액';

  @override
  String get watchAssetModalContentLoadingButton => '잔액...';

  @override
  String get watchAssetModalContentAddButton => '추가';

  @override
  String get connectedDappsModalSearchHint => 'DApps 검색';

  @override
  String get connectedDappsModalNoDapps => '연결된 DApps 없음';

  @override
  String dappListItemConnected(Object time) {
    return '$time 연결됨';
  }

  @override
  String get dappListItemJustNow => '방금';

  @override
  String get secretRecoveryModalRevealPhraseTitle => '비밀 복구 구문 공개';

  @override
  String get secretRecoveryModalRevealPhraseDescription => '브라우저 변경 또는 컴퓨터 이동 시 계정 액세스에 이 비밀 복구 구문 필요. 안전한 곳에 비밀스럽게 저장하세요.';

  @override
  String get secretRecoveryModalRevealPhraseButton => '공개';

  @override
  String get secretRecoveryModalShowKeysTitle => '개인 키 표시';

  @override
  String get secretRecoveryModalShowKeysDescription => '경고: 이 키 공개 금지. 개인 키 소유자는 계정 자산 도난 가능.';

  @override
  String get secretRecoveryModalShowKeysButton => '내보내기';

  @override
  String get secretRecoveryModalKeystoreBackupTitle => '키스토어 백업';

  @override
  String get secretRecoveryModalKeystoreBackupDescription => '비밀번호 보호 암호화 키스토어 파일에 개인 키 저장. 지갑 보안 추가 계층 제공.';

  @override
  String get secretRecoveryModalKeystoreBackupButton => '키스토어 백업 생성';

  @override
  String get backupConfirmationContentTitle => '백업 확인';

  @override
  String get backupConfirmationWarning => '경고: 정확한 순서의 시드 구문 분실 또는 잊음 시 자금 영구 손실. 시드 구문 공유 금지. 복구 시 단어 오류 시 자금 손실.';

  @override
  String get backupConfirmationContentWrittenDown => '모두 적음';

  @override
  String get backupConfirmationContentSafelyStored => '백업 안전 저장';

  @override
  String get backupConfirmationContentWontLose => '백업 분실 안 함 확신';

  @override
  String get backupConfirmationContentNotShare => '이 단어 공유 안 함 이해';

  @override
  String get counterMaxValueError => '최대값 도달';

  @override
  String get counterMinValueError => '최소값 도달';

  @override
  String get biometricSwitchFaceId => 'Face ID 활성화';

  @override
  String get biometricSwitchFingerprint => '지문 활성화';

  @override
  String get biometricSwitchBiometric => '생체 로그인 활성화';

  @override
  String get biometricSwitchPinCode => '기기 PIN 활성화';

  @override
  String get gasFeeOptionLow => '낮음';

  @override
  String get gasFeeOptionMarket => '시장';

  @override
  String get gasFeeOptionAggressive => '공격적';

  @override
  String get gasDetailsEstimatedGas => '예상 가스:';

  @override
  String get gasDetailsGasPrice => '가스 가격:';

  @override
  String get gasDetailsBaseFee => '기본 수수료:';

  @override
  String get gasDetailsPriorityFee => '우선 수수료:';

  @override
  String get gasDetailsMaxFee => '최대 수수료:';

  @override
  String get tokenTransferAmountUnknown => '알 수 없음';

  @override
  String get transactionDetailsModal_transaction => '거래';

  @override
  String get transactionDetailsModal_hash => '해시';

  @override
  String get transactionDetailsModal_sig => '서명';

  @override
  String get transactionDetailsModal_timestamp => '타임스탬프';

  @override
  String get transactionDetailsModal_blockNumber => '블록 번호';

  @override
  String get transactionDetailsModal_nonce => '논스';

  @override
  String get transactionDetailsModal_addresses => '주소';

  @override
  String get transactionDetailsModal_sender => '발신자';

  @override
  String get transactionDetailsModal_recipient => '수신자';

  @override
  String get transactionDetailsModal_contractAddress => '계약 주소';

  @override
  String get transactionDetailsModal_network => '네트워크';

  @override
  String get transactionDetailsModal_chainType => '체인 유형';

  @override
  String get transactionDetailsModal_networkName => '네트워크';

  @override
  String get transactionDetailsModal_gasFees => '가스 및 수수료';

  @override
  String get transactionDetailsModal_fee => '수수료';

  @override
  String get transactionDetailsModal_gasUsed => '사용 가스';

  @override
  String get transactionDetailsModal_gasLimit => '가스 제한';

  @override
  String get transactionDetailsModal_gasPrice => '가스 가격';

  @override
  String get transactionDetailsModal_effectiveGasPrice => '효과 가스 가격';

  @override
  String get transactionDetailsModal_blobGasUsed => 'Blob 가스 사용';

  @override
  String get transactionDetailsModal_blobGasPrice => 'Blob 가스 가격';

  @override
  String get transactionDetailsModal_error => '오류';

  @override
  String get transactionDetailsModal_errorMessage => '오류 메시지';

  @override
  String get amountSection_transfer => '전송';

  @override
  String get amountSection_pending => '대기 중';

  @override
  String get amountSection_confirmed => '확인됨';

  @override
  String get amountSection_rejected => '거부됨';

  @override
  String get appConnectModalContent_swipeToConnect => '스와이프 연결';

  @override
  String get appConnectModalContent_noAccounts => '사용 가능한 계정 없음';

  @override
  String get browserActionMenuShare => '공유';

  @override
  String get browserActionMenuCopyLink => '링크 복사';

  @override
  String get browserActionMenuClose => '닫기';

  @override
  String get browserActionMenuRefresh => '새로고침';

  @override
  String get keystoreBackupTitle => '키스토어 백업';

  @override
  String get keystoreBackupWarningTitle => '키스토어 파일 보호';

  @override
  String get keystoreBackupWarningMessage => '키스토어 파일에 암호화된 개인 키 포함. 안전한 위치에 보관하고 공유 금지. 파일 복호화에 생성 비밀번호 필요.';

  @override
  String get keystoreBackupConfirmPasswordHint => '비밀번호 확인';

  @override
  String get keystoreBackupCreateButton => '백업 생성';

  @override
  String get keystoreBackupError => '백업 생성 오류:';

  @override
  String get keystoreBackupShareButton => '키스토어 파일 공유';

  @override
  String get keystoreBackupDoneButton => '완료';

  @override
  String get keystoreBackupSuccessTitle => '백업 생성 성공';

  @override
  String get keystoreBackupSuccessMessage => '키스토어 파일 생성. 파일과 비밀번호 모두 안전 보관.';

  @override
  String get keystoreBackupSaveAsButton => '파일로 저장';

  @override
  String get keystoreBackupSaveDialogTitle => '키스토어 파일 저장';

  @override
  String get keystoreBackupSavedSuccess => '키스토어 파일 저장 성공';

  @override
  String get keystoreBackupSaveFailed => '키스토어 파일 저장 실패';

  @override
  String get keystoreBackupPasswordTooShort => '비밀번호 최소 8자';

  @override
  String get keystoreBackupTempLocation => '임시 파일 위치';

  @override
  String get keystorePasswordHint => '키스토어 비밀번호 입력';

  @override
  String get keystoreRestoreButton => '지갑 복원';

  @override
  String get keystoreRestoreExtError => '유효한 .zp 파일 선택';

  @override
  String get keystoreRestoreNoFile => '키스토어 파일 없음';

  @override
  String get keystoreRestoreFilesTitle => '키스토어 파일';

  @override
  String get editGasDialogTitle => '가스 매개변수 수정';

  @override
  String get editGasDialogGasPrice => '가스 가격';

  @override
  String get editGasDialogMaxPriorityFee => '최대 우선 수수료';

  @override
  String get editGasDialogGasLimit => '가스 제한';

  @override
  String get editGasDialogCancel => '취소';

  @override
  String get editGasDialogSave => '저장';

  @override
  String get editGasDialogInvalidGasValues => '잘못된 가스 값. 입력 확인.';

  @override
  String get addLedgerAccountPageAppBarTitle => 'Ledger 계정 추가';

  @override
  String get addLedgerAccountPageGetAccountsButton => '계정 가져오기';

  @override
  String get addLedgerAccountPageCreateButton => '생성';

  @override
  String get addLedgerAccountPageAddButton => '업데이트';

  @override
  String get addLedgerAccountPageScanningMessage => 'Ledger 기기 스캔 중...';

  @override
  String get addLedgerAccountPageNoDevicesMessage => 'Ledger 기기 없음';

  @override
  String get addLedgerAccountPageBluetoothOffError => 'Bluetooth 꺼짐. Ledger 기기 스캔을 위해 활성화하세요.';

  @override
  String get addLedgerAccountPageEmptyWalletNameError => '지갑 이름 비울 수 없음';

  @override
  String get addLedgerAccountPageWalletNameTooLongError => '지갑 이름 너무 길음 (최대 24자)';

  @override
  String addLedgerAccountPageFailedToScanError(Object error) {
    return 'Ledger 기기 스캔 실패: $error';
  }

  @override
  String get addLedgerAccountPageNetworkOrLedgerMissingError => '네트워크 또는 Ledger 데이터 없음';

  @override
  String get addLedgerAccountPageNoAccountsSelectedError => '선택된 계정 없음';

  @override
  String get addLedgerAccountPageNoWalletSelectedError => '선택된 지갑 없음';

  @override
  String get transactionHistoryTitle => '거래 내역';

  @override
  String get transactionHistoryDescription => '주소록에 거래 내역 주소 표시.';

  @override
  String get zilStakePageTitle => 'Zilliqa 스테이킹';

  @override
  String get noStakingPoolsFound => '스테이킹 풀 없음';

  @override
  String get aprSort => 'APR';

  @override
  String get commissionSort => '수수료';

  @override
  String get tvlSort => 'TVL';

  @override
  String get claimButton => '청구';

  @override
  String get stakeButton => '스테이크';

  @override
  String get unstakeButton => '언스테이크';

  @override
  String get reinvest => '재투자';

  @override
  String get aprLabel => 'APR';

  @override
  String get commissionLabel => '수수료';

  @override
  String get tvlLabel => 'TVL';

  @override
  String get lpStakingBadge => 'LP 스테이킹';

  @override
  String get stakedAmount => '스테이크됨';

  @override
  String get rewardsAvailable => '보상';

  @override
  String get pendingWithdrawals => '대기 인출';

  @override
  String get amount => '금액';

  @override
  String get claimableIn => '청구 가능 시간';

  @override
  String get blocks => '블록';

  @override
  String get unbondingPeriod => '언본딩 기간';

  @override
  String get currentBlock => '현재 블록';

  @override
  String get version => '버전';

  @override
  String get rewardsProgressTitle => '보상 진행';

  @override
  String get ledgerConnectPageTitle => 'Ledger 연결';

  @override
  String get ledgerConnectPageInitializing => '초기화 중...';

  @override
  String get ledgerConnectPageReadyToScan => '스캔 준비. 새로고침 버튼 누르세요.';

  @override
  String ledgerConnectPageInitializationError(String error) {
    return 'Ledger 초기화 오류: $error';
  }

  @override
  String get ledgerConnectPageInitErrorTitle => '초기화 오류';

  @override
  String ledgerConnectPageInitErrorContent(String error) {
    return 'Ledger 인터페이스 초기화 실패: $error';
  }

  @override
  String get ledgerConnectPageBluetoothOffStatus => 'Bluetooth 꺼짐. 기기에서 Bluetooth 활성화하세요.';

  @override
  String get ledgerConnectPageBluetoothOffTitle => 'Bluetooth 꺼짐';

  @override
  String get ledgerConnectPageBluetoothOffContent => '기기 설정에서 Bluetooth 켜고 다시 시도하세요.';

  @override
  String get ledgerConnectPagePermissionDeniedStatus => 'Bluetooth 권한 거부. 설정에서 활성화하세요.';

  @override
  String get ledgerConnectPagePermissionRequiredTitle => '권한 필요';

  @override
  String get ledgerConnectPagePermissionDeniedTitle => '권한 거부';

  @override
  String get ledgerConnectPagePermissionDeniedContent => 'Ledger 기기 스캔에 Bluetooth 권한 필요. 설정에서 권한 부여하세요.';

  @override
  String get ledgerConnectPagePermissionDeniedContentIOS => 'Ledger 기기 스캔에 Bluetooth 권한 필요. 기기 설정에서 Bluetooth 권한 활성화하세요.';

  @override
  String get ledgerConnectPageUnsupportedStatus => '이 기기에서 Bluetooth LE 지원 안 함.';

  @override
  String get ledgerConnectPageUnsupportedTitle => '지원되지 않는 기기';

  @override
  String get ledgerConnectPageUnsupportedContent => 'Ledger 기기 무선 연결에 필요한 Bluetooth Low Energy 지원 안 됨.';

  @override
  String get ledgerConnectPageScanningStatus => 'Ledger 기기 스캔 중...';

  @override
  String ledgerConnectPageFoundDevicesStatus(int count) {
    return '$count 기기 발견...';
  }

  @override
  String ledgerConnectPageScanErrorStatus(String error) {
    return '스캔 오류: $error';
  }

  @override
  String get ledgerConnectPageScanErrorTitle => '스캔 오류';

  @override
  String get ledgerConnectPageScanFinishedNoDevices => '스캔 완료. 기기 없음.';

  @override
  String ledgerConnectPageScanFinishedWithDevices(int count) {
    return '스캔 완료. $count 기기 발견. 연결할 하나 선택.';
  }

  @override
  String ledgerConnectPageFailedToStartScan(String error) {
    return '스캔 시작 실패: $error';
  }

  @override
  String get ledgerConnectPageScanStopped => '스캔 중지.';

  @override
  String ledgerConnectPageScanStoppedWithDevices(int count) {
    return '스캔 중지. $count 기기 발견.';
  }

  @override
  String ledgerConnectPageConnectingStatus(String deviceName, String connectionType) {
    return '$deviceName ($connectionType) 연결 중...';
  }

  @override
  String ledgerConnectPageConnectionTimeoutError(int seconds) {
    return '$seconds초 후 연결 시간 초과';
  }

  @override
  String get ledgerConnectPageInterfaceUnavailableError => '적절한 Ledger 인터페이스 사용 불가.';

  @override
  String ledgerConnectPageConnectionSuccessStatus(String deviceName) {
    return '$deviceName 연결 성공!';
  }

  @override
  String ledgerConnectPageConnectionFailedTimeoutStatus(int count) {
    return '연결 실패: $count 시도 후 시간 초과';
  }

  @override
  String get ledgerConnectPageConnectionFailedTitle => '연결 실패';

  @override
  String ledgerConnectPageConnectionFailedTimeoutContent(int count) {
    return '$count 시도 후 연결 시간 초과. 기기 잠금 해제 확인 후 다시 시도하세요.';
  }

  @override
  String ledgerConnectPageConnectionFailedErrorStatus(String error) {
    return '연결 실패: $error';
  }

  @override
  String ledgerConnectPageConnectionFailedLedgerErrorContent(String error) {
    return 'Ledger 오류: $error';
  }

  @override
  String ledgerConnectPageConnectionFailedGenericContent(String deviceName, String error) {
    return '$deviceName 연결 불가.\n오류: $error';
  }

  @override
  String get ledgerConnectPageDeviceDisconnected => '기기 연결 해제.';

  @override
  String get ledgerConnectPageListenerStopped => '리스너 중지.';

  @override
  String get ledgerConnectPageFailedToMonitorDisconnects => '연결 해제 모니터링 실패.';

  @override
  String ledgerConnectPageDisconnectingStatus(String deviceName) {
    return '$deviceName 연결 해제 중...';
  }

  @override
  String ledgerConnectPageDisconnectedStatus(String deviceName) {
    return '$deviceName 연결 해제.';
  }

  @override
  String ledgerConnectPageDisconnectErrorStatus(String deviceName) {
    return '$deviceName 연결 해제 오류.';
  }

  @override
  String get ledgerConnectPageGoToSettings => '설정으로 이동';

  @override
  String get ledgerConnectPageNoDevicesFound => '기기 없음. Ledger 전원 켜기, 잠금 해제, Bluetooth/USB 활성화 확인.\n아래로 끌기 또는 새로고침 아이콘으로 다시 스캔.';

  @override
  String ledgerConnectPageDisconnectButton(String deviceName) {
    return '$deviceName 연결 해제';
  }

  @override
  String get unknownDevice => '알 수 없음';

  @override
  String get durationDay => '일';

  @override
  String get durationHour => '시간';

  @override
  String get durationMinute => '분';

  @override
  String get durationLessThanAMinute => '< 1분';

  @override
  String get durationNotAvailable => 'N/A';

  @override
  String get nodes => '노드';

  @override
  String get manageTokensPageTitle => '토큰';

  @override
  String get manageTokensSearchHint => '토큰 검색 또는 주소 붙여넣기';

  @override
  String get manageTokensFoundToken => '찾은 토큰';

  @override
  String get manageTokensDeletedTokens => '삭제된 토큰';

  @override
  String get manageTokensSuggestedTokens => '추천 토큰';

  @override
  String get manageTokensFetchError => '토큰 가져오기 실패';

  @override
  String get manageTokensWrongChain => '토큰이 다른 체인에 속함';

  @override
  String get manageTokensClear => '지우기';
}
