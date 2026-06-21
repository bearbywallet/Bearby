import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bearby/state/app_state.dart';

enum AppIcon {
  // Intentional semantic aliases: check/ok, alert/warning, gear/manage/settings,
  // server/ipfs, chevronRight/arrowRight, lock/lockWallet share one glyph each.
  add, alert, anchor, anchorSimple, appearance,
  arrowDown, arrowLeft, arrowRight,
  backspace, barcodeScan, bell,
  bincode, biometric, bluetooth,
  book, browser, cache,
  check, chevronRight, close,
  compass, cookie, copy, currency,

  data, disconnect, document,
  dots, edit, email, exchange,
  faceId, file, fingerprint,
  gear, globe, graph,
  history, importWallet, incognito,
  info, ipfs, key,
  language, ledger, lines,
  lock, lockWallet, logout,
  looking, manage, menu,
  minus, nav,
  ok, openEye, closeEye,
  pin, plus, puzzle,
  scan, receive, reload,
  search, send, server,
  setAmount, settings, share, shield,
  swap, theme, time,
  tiles, trophy, usb,
  wallet, bitcoinAmount, bitcoinAddress,
  warning, zil,
  // Social / brand
  github, telegram, twitter,
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

  const AppIconView({
    super.key,
    required this.icon,
    this.size = 24,
    this.color,
  });

  // Self-hosted Phosphor Regular font. All codepoints from phosphor_flutter 2.1.0.
  static const _f = 'PhosphorRegular';

  static IconData _glyphFor(AppIcon icon) => switch (icon) {
        AppIcon.add           => const IconData(0xe3d4, fontFamily: _f),
        AppIcon.alert         => const IconData(0xe4e0, fontFamily: _f),
        AppIcon.anchor        => const IconData(0xe514, fontFamily: _f),
        AppIcon.anchorSimple  => const IconData(0xe5d8, fontFamily: _f),
        AppIcon.appearance    => const IconData(0xe6c8, fontFamily: _f),
        AppIcon.arrowDown     => const IconData(0xe03e, fontFamily: _f),
        AppIcon.arrowLeft     => const IconData(0xe058, fontFamily: _f),
        AppIcon.arrowRight    => const IconData(0xe06c, fontFamily: _f),
        AppIcon.backspace     => const IconData(0xe0ae, fontFamily: _f),
        AppIcon.barcodeScan   => const IconData(0xe0b8, fontFamily: _f),
        AppIcon.bell          => const IconData(0xe0d0, fontFamily: _f),
        AppIcon.bincode       => const IconData(0xee60, fontFamily: _f),
        AppIcon.biometric     => const IconData(0xe23e, fontFamily: _f),
        AppIcon.bluetooth     => const IconData(0xe0da, fontFamily: _f),
        AppIcon.book          => const IconData(0xe0e6, fontFamily: _f),
        AppIcon.browser       => const IconData(0xe0f4, fontFamily: _f),
        AppIcon.cache         => const IconData(0xe096, fontFamily: _f),
        AppIcon.check         => const IconData(0xe184, fontFamily: _f),
        AppIcon.chevronRight  => const IconData(0xe13a, fontFamily: _f),
        AppIcon.close         => const IconData(0xe4f6, fontFamily: _f),
        AppIcon.compass       => const IconData(0xe1c8, fontFamily: _f),
        AppIcon.cookie        => const IconData(0xe6ca, fontFamily: _f),
        AppIcon.copy          => const IconData(0xe1ca, fontFamily: _f),
        AppIcon.currency      => const IconData(0xe54c, fontFamily: _f),
        AppIcon.data          => const IconData(0xe1de, fontFamily: _f),
        AppIcon.disconnect    => const IconData(0xe2e4, fontFamily: _f),
        AppIcon.document      => const IconData(0xe23a, fontFamily: _f),
        AppIcon.dots          => const IconData(0xe1fe, fontFamily: _f),
        AppIcon.edit          => const IconData(0xe3b4, fontFamily: _f),
        AppIcon.email         => const IconData(0xe0ac, fontFamily: _f),
        AppIcon.exchange      => const IconData(0xe0a0, fontFamily: _f),
        AppIcon.faceId        => const IconData(0xebb4, fontFamily: _f),
        AppIcon.file          => const IconData(0xe230, fontFamily: _f),
        AppIcon.fingerprint   => const IconData(0xe23e, fontFamily: _f),
        AppIcon.gear          => const IconData(0xe270, fontFamily: _f),
        AppIcon.globe         => const IconData(0xe288, fontFamily: _f),
        AppIcon.graph         => const IconData(0xe154, fontFamily: _f),
        AppIcon.history       => const IconData(0xe1a0, fontFamily: _f),
        AppIcon.importWallet  => const IconData(0xe232, fontFamily: _f),
        AppIcon.incognito     => const IconData(0xe224, fontFamily: _f),
        AppIcon.info          => const IconData(0xe2ce, fontFamily: _f),
        AppIcon.ipfs          => const IconData(0xe2a0, fontFamily: _f),
        AppIcon.key           => const IconData(0xe2d6, fontFamily: _f),
        AppIcon.language      => const IconData(0xe4a2, fontFamily: _f),
        AppIcon.ledger        => const IconData(0xe956, fontFamily: _f),
        AppIcon.lines         => const IconData(0xe2f0, fontFamily: _f),
        AppIcon.lock          => const IconData(0xe2fa, fontFamily: _f),
        AppIcon.lockWallet    => const IconData(0xe2fa, fontFamily: _f),
        AppIcon.logout        => const IconData(0xe42a, fontFamily: _f),
        AppIcon.looking       => const IconData(0xe310, fontFamily: _f),
        AppIcon.manage        => const IconData(0xe228, fontFamily: _f),
        AppIcon.menu          => const IconData(0xe2f0, fontFamily: _f),
        AppIcon.minus         => const IconData(0xe32a, fontFamily: _f),
        AppIcon.nav           => const IconData(0xe1c6, fontFamily: _f),
        AppIcon.ok            => const IconData(0xe184, fontFamily: _f),
        AppIcon.openEye       => const IconData(0xe220, fontFamily: _f),
        AppIcon.closeEye      => const IconData(0xe224, fontFamily: _f),
        AppIcon.pin           => const IconData(0xe2fa, fontFamily: _f),
        AppIcon.plus          => const IconData(0xe3d4, fontFamily: _f),
        AppIcon.puzzle        => const IconData(0xe596, fontFamily: _f),
        AppIcon.scan          => const IconData(0xebb6, fontFamily: _f),
        AppIcon.receive       => const IconData(0xe040, fontFamily: _f),
        AppIcon.reload        => const IconData(0xe036, fontFamily: _f),
        AppIcon.search        => const IconData(0xe30c, fontFamily: _f),
        AppIcon.send          => const IconData(0xe092, fontFamily: _f),
        AppIcon.server        => const IconData(0xe2a0, fontFamily: _f),
        AppIcon.setAmount     => const IconData(0xe64a, fontFamily: _f),
        AppIcon.settings      => const IconData(0xe434, fontFamily: _f),
        AppIcon.share         => const IconData(0xe408, fontFamily: _f),
        AppIcon.shield        => const IconData(0xe40c, fontFamily: _f),
        AppIcon.swap          => const IconData(0xe094, fontFamily: _f),
        AppIcon.theme         => const IconData(0xe472, fontFamily: _f),
        AppIcon.time          => const IconData(0xe492, fontFamily: _f),
        AppIcon.tiles         => const IconData(0xe464, fontFamily: _f),
        AppIcon.trophy        => const IconData(0xe67e, fontFamily: _f),
        AppIcon.usb           => const IconData(0xe956, fontFamily: _f),
        AppIcon.wallet        => const IconData(0xe68a, fontFamily: _f),
        AppIcon.bitcoinAmount => const IconData(0xe618, fontFamily: _f),
        AppIcon.bitcoinAddress => const IconData(0xe0a0, fontFamily: _f),
        AppIcon.warning       => const IconData(0xe4e0, fontFamily: _f),
        AppIcon.zil           => const IconData(0xe60e, fontFamily: _f),
        AppIcon.github        => const IconData(0xe576, fontFamily: _f),
        AppIcon.telegram      => const IconData(0xe5bc, fontFamily: _f),
        AppIcon.twitter       => const IconData(0xe4bc, fontFamily: _f),
      };

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ??
        Provider.of<AppState>(context, listen: false).currentTheme.textPrimary;

    return Icon(
      _glyphFor(icon),
      size: size,
      color: resolvedColor,
    );
  }
}
