import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bearby/components/async_qrcode.dart';
import 'package:bearby/mixins/preprocess_url.dart';
import 'package:bearby/src/rust/api/qrcode.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/src/rust/models/qrcode.dart';
import 'package:bearby/state/app_state.dart';

/// First explorer's name + URL for the chain, or null when none configured.
/// Safe — wraps `getChain` (which uses `firstWhere` without `orElse`) in try/catch.
({String name, String url})? firstExplorer(
  AppState appState,
  BigInt chainHash,
  String txHash,
) {
  try {
    final NetworkConfigInfo? chain = appState.getChain(chainHash);
    final List<ExplorerInfo> explorers =
        chain?.explorers ?? const <ExplorerInfo>[];
    if (explorers.isEmpty) return null;
    final ExplorerInfo e = explorers.first;
    return (name: e.name, url: formExplorerUrl(e, txHash));
  } catch (err) {
    debugPrint('firstExplorer failed: $err');
    return null;
  }
}

/// Generates a QR PNG for [url], writes it to a temp file, opens the system
/// share sheet with the PNG as the attachment and a labeled comment as the
/// text body, then deletes the temp file. Matches the pattern used by
/// `lib/pages/receive.dart` `handleShare`.
///
/// Returns `true` if the share sheet was dismissed normally (including cancel);
/// returns `false` only when an unexpected error was caught.
Future<bool> shareTransactionQr({
  required String url,
  required String explorerName,
  required Color color,
}) async {
  try {
    final QrConfigInfo config = QrConfigInfo(
      size: 600,
      gapless: false,
      color: color.toARGB32(),
      eyeShape: EyeShape.circle.value,
      dataModuleShape: DataModuleShape.circle.value,
    );
    final Uint8List pngBytes = await genPngQrcode(data: url, config: config);
    final Directory tempDir = await getTemporaryDirectory();
    final File tempFile = File('${tempDir.path}/qrcode.png');
    await tempFile.writeAsBytes(pngBytes);
    final XFile xFile = XFile(tempFile.path, mimeType: 'image/png');
    final StringBuffer text = StringBuffer()
      ..writeln('View on $explorerName')
      ..write(url);
    await SharePlus.instance.share(
      ShareParams(files: <XFile>[xFile], text: text.toString()),
    );
    await tempFile.delete();
    return true;
  } catch (e) {
    debugPrint('shareTransactionQr failed: $e');
    return false;
  }
}
