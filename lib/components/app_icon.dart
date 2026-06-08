import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

import 'package:bearby/state/app_state.dart';

enum AppIcon {
  // Intentional semantic aliases: check/ok, alert/warning, gear/manage/settings,
  // server/ipfs, chevronRight/arrowRight share one HugeIcons glyph each.
  add,
  alert,
  anchor,
  appearance,
  arrowDown,
  arrowLeft,
  arrowRight,
  backspace,
  barcodeScan,
  bell,
  bincode,
  biometric,
  bluetooth,
  book,
  browser,
  cache,
  check,
  chevronRight,
  close,
  cookie,
  copy,
  currency,
  data,
  disconnect,
  document,
  dots,
  edit,
  exchange,
  faceId,
  file,
  fingerprint,
  gear,
  globe,
  graph,
  history,
  importWallet,
  incognito,
  info,
  ipfs,
  key,
  language,
  ledger,
  lines,
  lock,
  lockWallet,
  logout,
  looking,
  manage,
  menu,
  minus,
  nav,
  ok,
  openEye,
  closeEye,
  pin,
  plus,
  puzzle,
  qrCode,
  receive,
  reload,
  search,
  send,
  server,
  settings,
  share,
  shield,
  swap,
  time,
  tiles,
  trophy,
  usb,
  wallet,
  bitcoinAmount,
  bitcoinAddress,
  warning,
  zil,
}

abstract final class AppIconState {
  const AppIconState._();

  static AppIcon passwordVisibility({required bool obscured}) =>
      obscured ? AppIcon.closeEye : AppIcon.openEye;

  static AppIcon balanceVisibility({required bool hidden}) =>
      hidden ? AppIcon.closeEye : AppIcon.openEye;

  static AppIcon tokenLayout({required bool isTileView}) =>
      isTileView ? AppIcon.tiles : AppIcon.lines;

  static AppIcon? loading({required bool isLoading}) =>
      isLoading ? AppIcon.reload : null;
}

class AppIconView extends StatelessWidget {
  final AppIcon icon;
  final double size;
  final Color? color;
  final double? strokeWidth;

  const AppIconView({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
    this.strokeWidth,
  });

  static List<List<Object?>> _glyphFor(AppIcon icon) => switch (icon) {
        AppIcon.add => HugeIcons.strokeRoundedPlusSign,
        AppIcon.alert => HugeIcons.strokeRoundedAlert02,
        AppIcon.anchor => HugeIcons.strokeRoundedAnchorPoint,
        AppIcon.appearance => HugeIcons.strokeRoundedColorPicker,
        AppIcon.arrowDown => HugeIcons.strokeRoundedArrowDown01,
        AppIcon.arrowLeft => HugeIcons.strokeRoundedArrowLeft01,
        AppIcon.arrowRight => HugeIcons.strokeRoundedArrowRight01,
        AppIcon.backspace => HugeIcons.strokeRoundedTextIndentLess,
        AppIcon.barcodeScan => HugeIcons.strokeRoundedBarcodeScan,
        AppIcon.bell => HugeIcons.strokeRoundedBellDot,
        AppIcon.bincode => HugeIcons.strokeRoundedBinaryCode,
        AppIcon.biometric => HugeIcons.strokeRoundedBiometricAccess,
        AppIcon.bluetooth => HugeIcons.strokeRoundedBluetooth,
        AppIcon.book => HugeIcons.strokeRoundedBookOpen01,
        AppIcon.browser => HugeIcons.strokeRoundedBrowser,
        AppIcon.cache => HugeIcons.strokeRoundedDatabaseSync,
        AppIcon.check => HugeIcons.strokeRoundedCheckmarkCircle01,
        AppIcon.chevronRight => HugeIcons.strokeRoundedArrowRight01,
        AppIcon.close => HugeIcons.strokeRoundedCancel01,
        AppIcon.cookie => HugeIcons.strokeRoundedCookie,
        AppIcon.copy => HugeIcons.strokeRoundedCopy01,
        AppIcon.currency => HugeIcons.strokeRoundedBitcoinEllipse,
        AppIcon.data => HugeIcons.strokeRoundedDatabase,
        AppIcon.disconnect => HugeIcons.strokeRoundedLink03,
        AppIcon.document => HugeIcons.strokeRoundedDocumentAttachment,
        AppIcon.dots => HugeIcons.strokeRoundedMoreHorizontal,
        AppIcon.edit => HugeIcons.strokeRoundedEdit02,
        AppIcon.exchange => HugeIcons.strokeRoundedExchange02,
        AppIcon.faceId => HugeIcons.strokeRoundedFaceId,
        AppIcon.file => HugeIcons.strokeRoundedFile01,
        AppIcon.fingerprint => HugeIcons.strokeRoundedFingerprintScan,
        AppIcon.gear => HugeIcons.strokeRoundedSettings02,
        AppIcon.globe => HugeIcons.strokeRoundedGlobe02,
        AppIcon.graph => HugeIcons.strokeRoundedChart,
        AppIcon.history => HugeIcons.strokeRoundedTransactionHistory,
        AppIcon.importWallet => HugeIcons.strokeRoundedFileImport,
        AppIcon.incognito => HugeIcons.strokeRoundedAnonymous,
        AppIcon.info => HugeIcons.strokeRoundedInformationCircle,
        AppIcon.ipfs => HugeIcons.strokeRoundedServerStack01,
        AppIcon.key => HugeIcons.strokeRoundedKey01,
        AppIcon.language => HugeIcons.strokeRoundedLanguageCircle,
        AppIcon.ledger => HugeIcons.strokeRoundedUsbConnected01,
        AppIcon.lines => HugeIcons.strokeRoundedListView,
        AppIcon.lock => HugeIcons.strokeRoundedAuthorized,
        AppIcon.lockWallet => HugeIcons.strokeRoundedLocked,
        AppIcon.logout => HugeIcons.strokeRoundedLogout01,
        AppIcon.looking => HugeIcons.strokeRoundedUserSearch01,
        AppIcon.manage => HugeIcons.strokeRoundedFilterMail,
        AppIcon.menu => HugeIcons.strokeRoundedMenu01,
        AppIcon.minus => HugeIcons.strokeRoundedMinusSign,
        AppIcon.nav => HugeIcons.strokeRoundedInternet,
        AppIcon.ok => HugeIcons.strokeRoundedCheckmarkCircle01,
        AppIcon.openEye => HugeIcons.strokeRoundedView,
        AppIcon.closeEye => HugeIcons.strokeRoundedViewOff,
        AppIcon.pin => HugeIcons.strokeRoundedPinCode,
        AppIcon.plus => HugeIcons.strokeRoundedPlusSign,
        AppIcon.puzzle => HugeIcons.strokeRoundedPuzzle,
        AppIcon.qrCode => HugeIcons.strokeRoundedQrCode,
        AppIcon.receive => HugeIcons.strokeRoundedBitcoinReceive,
        AppIcon.reload => HugeIcons.strokeRoundedReload,
        AppIcon.search => HugeIcons.strokeRoundedSearch01,
        AppIcon.send => HugeIcons.strokeRoundedBitcoinSend,
        AppIcon.server => HugeIcons.strokeRoundedServerStack01,
        AppIcon.settings => HugeIcons.strokeRoundedPreferenceVertical,
        AppIcon.share => HugeIcons.strokeRoundedShare01,
        AppIcon.shield => HugeIcons.strokeRoundedShield01,
        AppIcon.swap => HugeIcons.strokeRoundedExchange01,
        AppIcon.time => HugeIcons.strokeRoundedTimeHalfPass,
        AppIcon.tiles => HugeIcons.strokeRoundedGridView,
        AppIcon.trophy => HugeIcons.strokeRoundedAward01,
        AppIcon.usb => HugeIcons.strokeRoundedUsb,
        AppIcon.wallet => HugeIcons.strokeRoundedWallet01,
        AppIcon.warning => HugeIcons.strokeRoundedAlert02,
        AppIcon.zil => HugeIcons.strokeRoundedCoinsSwap,
        AppIcon.bitcoinAmount => HugeIcons.strokeRoundedBitcoin01,
        AppIcon.bitcoinAddress => HugeIcons.strokeRoundedBitcoinTransaction,
      };

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ??
        Provider.of<AppState>(context, listen: false).currentTheme.textPrimary;

    return HugeIcon(
      icon: _glyphFor(icon),
      size: size,
      color: resolvedColor,
      strokeWidth: strokeWidth,
    );
  }
}
