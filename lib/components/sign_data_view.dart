import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bearby/components/app_icon.dart';
import 'package:bearby/mixins/addr.dart';
import 'package:bearby/mixins/eip712.dart';
import 'package:bearby/theme/app_theme.dart';

/// Parsed "Sign-In with Ethereum" (EIP-4361) message.
class SiweMessage {
  final String domain;
  final String? statement;
  final Map<String, dynamic> fields;

  const SiweMessage(
      {required this.domain, this.statement, required this.fields});

  static final _kv = RegExp(
    r'^(URI|Version|Chain ID|Nonce|Issued At|Expiration Time|Not Before|Request ID|Resources):\s*(.*)$',
  );

  static SiweMessage? tryParse(String? raw) {
    if (raw == null) return null;
    final lines = raw.replaceAll('\r\n', '\n').split('\n');
    if (lines.length < 3) return null;
    const marker = ' wants you to sign in with your ';
    final i = lines.first.indexOf(marker);
    if (i <= 0) return null;

    final domain = lines.first.substring(0, i).trim();
    final fields = <String, dynamic>{'Account': lines[1].trim()};
    final statement = <String>[];
    var idx = 2;
    while (idx < lines.length && !_kv.hasMatch(lines[idx].trim())) {
      statement.add(lines[idx]);
      idx++;
    }
    List<String>? resources;
    for (; idx < lines.length; idx++) {
      final line = lines[idx].trim();
      final m = _kv.firstMatch(line);
      if (m != null) {
        if (m.group(1) == 'Resources') {
          resources = <String>[];
          fields['Resources'] = resources;
        } else {
          fields[m.group(1)!] = m.group(2)!.trim();
        }
      } else if (line.startsWith('- ') && resources != null) {
        resources.add(line.substring(2));
      }
    }
    final st = statement.join('\n').trim();
    return SiweMessage(
        domain: domain, statement: st.isEmpty ? null : st, fields: fields);
  }
}

/// What kind of payload the user is about to sign.
enum SignPayloadKind { typedData, siwe, json, hex, text }

class SignPayload {
  final SignPayloadKind kind;
  final TypedDataEip712? typedData;
  final SiweMessage? siwe;
  final Map<String, dynamic>? fields;

  /// Human readable form (decoded text for hex payloads).
  final String readable;

  /// Exactly what the dApp sent.
  final String raw;

  const SignPayload._({
    required this.kind,
    required this.readable,
    required this.raw,
    this.typedData,
    this.siwe,
    this.fields,
  });

  factory SignPayload.from({String? message, TypedDataEip712? typedData}) {
    if (typedData != null) {
      final raw =
          const JsonEncoder.withIndent('  ').convert(typedData.toJson());
      return SignPayload._(
        kind: SignPayloadKind.typedData,
        typedData: typedData,
        fields: typedData.message,
        readable: raw,
        raw: raw,
      );
    }

    final raw = message ?? '';
    final decoded = _tryDecodeHexUtf8(raw);
    final text = decoded ?? raw;

    final siwe = SiweMessage.tryParse(text);
    if (siwe != null) {
      return SignPayload._(
        kind: SignPayloadKind.siwe,
        siwe: siwe,
        fields: siwe.fields,
        readable: text,
        raw: raw,
      );
    }

    final json = _tryJsonMap(text);
    if (json != null) {
      return SignPayload._(
        kind: SignPayloadKind.json,
        fields: json,
        readable: const JsonEncoder.withIndent('  ').convert(json),
        raw: raw,
      );
    }

    final isHex = decoded == null && SignValue.isHex(raw);
    return SignPayload._(
      kind: isHex ? SignPayloadKind.hex : SignPayloadKind.text,
      readable: text,
      raw: raw,
    );
  }

  bool get hasTree => fields != null && fields!.isNotEmpty;

  /// Raw differs from what we show by default -> offer a toggle.
  bool get hasRawView => hasTree || readable != raw;

  static String? _tryDecodeHexUtf8(String value) {
    final v = value.trim();
    if (!SignValue.isHex(v) || v.length.isOdd) return null;
    try {
      final bytes = <int>[
        for (var i = 2; i < v.length; i += 2)
          int.parse(v.substring(i, i + 2), radix: 16),
      ];
      final text = utf8.decode(bytes);
      final printable = text.runes
          .every((r) => r >= 0x20 || r == 0x0a || r == 0x0d || r == 0x09);
      return printable && text.trim().isNotEmpty ? text : null;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _tryJsonMap(String value) {
    final v = value.trim();
    if (!v.startsWith('{')) return null;
    try {
      final d = jsonDecode(v);
      return d is Map ? d.cast<String, dynamic>() : null;
    } catch (_) {
      return null;
    }
  }
}

/// Value classification helpers.
abstract final class SignValue {
  static final _evm = RegExp(r'^0x[a-fA-F0-9]{40}$');
  static final _tron = RegExp(r'^T[1-9A-HJ-NP-Za-km-z]{33}$');
  static final _bech32 = RegExp(r'^[a-z]{2,6}1[0-9a-z]{38,58}$');
  static final _hex = RegExp(r'^0x[a-fA-F0-9]+$');

  static const _maxUints = {
    '115792089237316195423570985008687907853269984665640564039457584007913129639935', // uint256
    '1461501637330902918203684832716283019655932542975', // uint160
    '340282366920938463463374607431768211455', // uint128
    '281474976710655', // uint48
  };

  static bool isAddress(String v) =>
      _evm.hasMatch(v) || _tron.hasMatch(v) || _bech32.hasMatch(v);
  static bool isHex(String v) => v.length > 2 && _hex.hasMatch(v);
  static bool isMax(String v) =>
      _maxUints.contains(v) ||
      (v.length >= 14 && RegExp(r'^0x[fF]+$').hasMatch(v));

  static const _timeKeys = [
    'deadline',
    'expir',
    'validto',
    'validafter',
    'validbefore',
    'timestamp',
    'issued',
    'notbefore',
    'sigdeadline',
  ];

  /// "2025-03-01 14:00 · in 29d" for epoch-like values under time-ish keys.
  static String? time(String key, String value) {
    final k = key.toLowerCase().replaceAll(' ', '');
    if (!_timeKeys.any(k.contains)) return null;
    DateTime? dt;
    final n = int.tryParse(value);
    if (n != null) {
      if (n > 1e9 && n < 5e9) {
        dt = DateTime.fromMillisecondsSinceEpoch(n * 1000);
      } else if (n > 1e12 && n < 5e12) {
        dt = DateTime.fromMillisecondsSinceEpoch(n);
      }
    } else {
      dt = DateTime.tryParse(value)?.toLocal();
    }
    if (dt == null) return null;

    String two(int x) => x.toString().padLeft(2, '0');
    final date =
        '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
    final diff = dt.difference(DateTime.now());
    final abs = diff.abs();
    final span = abs.inDays > 0
        ? '${abs.inDays}d'
        : abs.inHours > 0
            ? '${abs.inHours}h'
            : '${abs.inMinutes}m';
    return '$date · ${diff.isNegative ? '$span ago' : 'in $span'}';
  }
}

/// One-line strip with the EIP-712 domain: name vX · #chain · contract.
class SignDomainStrip extends StatelessWidget {
  final Map<String, dynamic> domain;
  final AppTheme theme;
  final Color accent;

  const SignDomainStrip(
      {super.key,
      required this.domain,
      required this.theme,
      required this.accent});

  @override
  Widget build(BuildContext context) {
    final name = domain['name']?.toString() ?? '';
    final version = domain['version']?.toString() ?? '';
    final chainId = domain['chainId']?.toString() ?? '';
    final contract = domain['verifyingContract']?.toString() ?? '';

    return Row(
      children: [
        AppIconView(icon: AppIcon.shield, size: 14, color: accent),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            [
              if (name.isNotEmpty) name,
              if (version.isNotEmpty) 'v$version',
              if (chainId.isNotEmpty) '#$chainId'
            ].join(' · '),
            style: theme.caption.copyWith(
                color: theme.textSecondary, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (contract.isNotEmpty) ...[
          const SizedBox(width: 8),
          SignCopyPill(value: contract, theme: theme),
        ],
      ],
    );
  }
}

/// Bordered panel: header (title, count, Tree/Raw, copy) + scrollable body.
class SignDataPanel extends StatefulWidget {
  final SignPayload payload;
  final String title;
  final AppTheme theme;
  final Color accent;
  final Color textColor;
  final double maxHeight;

  const SignDataPanel({
    super.key,
    required this.payload,
    required this.title,
    required this.theme,
    required this.accent,
    required this.textColor,
    required this.maxHeight,
  });

  @override
  State<SignDataPanel> createState() => _SignDataPanelState();
}

class _SignDataPanelState extends State<SignDataPanel> {
  bool _raw = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final p = widget.payload;
    final mono =
        _raw || p.kind == SignPayloadKind.hex || p.kind == SignPayloadKind.json;

    final Widget body = (!_raw && p.hasTree)
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (p.siwe?.statement != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                      border: Border(
                          left: BorderSide(color: widget.accent, width: 2))),
                  child: Text(p.siwe!.statement!,
                      style: theme.bodyText2.copyWith(color: widget.textColor)),
                ),
              _FieldList(
                  map: p.fields!,
                  depth: 0,
                  theme: theme,
                  accent: widget.accent,
                  textColor: widget.textColor),
            ],
          )
        : SelectableText(
            _raw ? p.raw : p.readable,
            style: theme.bodyText2.copyWith(
              color: widget.textColor,
              fontFamily: mono ? 'monospace' : null,
              fontSize: mono ? 12 : null,
              height: 1.4,
            ),
          );

    return Container(
      decoration: BoxDecoration(
        color: theme.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.modalBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.caption.copyWith(
                        color: theme.textSecondary,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (p.hasRawView)
                  _Segmented(
                    labels: [p.hasTree ? 'Fields' : 'Text', 'Raw'],
                    index: _raw ? 1 : 0,
                    theme: theme,
                    accent: widget.accent,
                    onChanged: (i) => setState(() => _raw = i == 1),
                  ),
                _CopyIcon(value: _raw ? p.raw : p.readable, theme: theme),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: theme.modalBorder),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldList extends StatelessWidget {
  final Map<String, dynamic> map;
  final int depth;
  final AppTheme theme;
  final Color accent;
  final Color textColor;

  const _FieldList({
    required this.map,
    required this.depth,
    required this.theme,
    required this.accent,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in map.entries)
          _FieldRow(
              name: e.key,
              value: e.value,
              depth: depth,
              theme: theme,
              accent: accent,
              textColor: textColor),
      ],
    );
  }
}

class _FieldRow extends StatefulWidget {
  final String name;
  final dynamic value;
  final int depth;
  final AppTheme theme;
  final Color accent;
  final Color textColor;

  const _FieldRow({
    required this.name,
    required this.value,
    required this.depth,
    required this.theme,
    required this.accent,
    required this.textColor,
  });

  @override
  State<_FieldRow> createState() => _FieldRowState();
}

class _FieldRowState extends State<_FieldRow> {
  late bool _open = widget.depth < 1;

  @override
  Widget build(BuildContext context) {
    final v = widget.value;
    final Map<String, dynamic>? nested = v is Map
        ? v.cast<String, dynamic>()
        : v is List
            ? {for (var i = 0; i < v.length; i++) '#$i': v[i]}
            : null;

    if (nested != null && nested.isNotEmpty) return _group(nested, v is List);
    return _scalar(
        nested != null ? (v is List ? '[]' : '{}') : '${v ?? 'null'}');
  }

  Widget _group(Map<String, dynamic> nested, bool isList) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _open ? 0.25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: AppIconView(
                      icon: AppIcon.chevronRight,
                      size: 12,
                      color: widget.accent),
                ),
                const SizedBox(width: 4),
                Text(widget.name,
                    style: theme.caption.copyWith(
                        color: theme.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                Text(
                  isList ? '[${nested.length}]' : '{${nested.length}}',
                  style: theme.caption
                      .copyWith(color: widget.accent, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Container(
            margin: const EdgeInsets.only(left: 5),
            padding: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              border: Border(
                  left:
                      BorderSide(color: widget.accent.withValues(alpha: 0.3))),
            ),
            child: _FieldList(
              map: nested,
              depth: widget.depth + 1,
              theme: theme,
              accent: widget.accent,
              textColor: widget.textColor,
            ),
          ),
      ],
    );
  }

  Widget _scalar(String s) {
    final theme = widget.theme;
    final time = SignValue.time(widget.name, s);
    final isMax = SignValue.isMax(s);

    final Widget value;
    if (SignValue.isAddress(s) || (SignValue.isHex(s) && s.length > 42)) {
      value = SignCopyPill(value: s, theme: theme);
    } else if (isMax) {
      value = _Chip(text: 'MAX', color: theme.warning, theme: theme);
    } else if (time != null) {
      value = Text(time,
          textAlign: TextAlign.right,
          style: theme.caption.copyWith(color: widget.textColor));
    } else {
      value = SelectableText(
        s,
        textAlign: s.length > 40 ? TextAlign.left : TextAlign.right,
        style: theme.caption.copyWith(color: widget.textColor, fontSize: 12.5),
      );
    }

    final label = Text(
      widget.name,
      style: theme.caption.copyWith(color: theme.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    // Long free text goes under the label instead of squeezing to the right.
    if (s.length > 40 && value is SelectableText) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [label, const SizedBox(height: 2), value]),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Flexible(flex: 2, child: label),
          const SizedBox(width: 12),
          Expanded(
              flex: 3,
              child: Align(alignment: Alignment.centerRight, child: value)),
        ],
      ),
    );
  }
}

/// Shortened monospace value; tap copies the full one.
class SignCopyPill extends StatefulWidget {
  final String value;
  final AppTheme theme;

  const SignCopyPill({super.key, required this.value, required this.theme});

  @override
  State<SignCopyPill> createState() => _SignCopyPillState();
}

class _SignCopyPillState extends State<SignCopyPill> with _CopyFeedback {
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final color = copied ? theme.success : theme.textPrimary;
    return GestureDetector(
      onTap: () => copy(widget.value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.modalBorder.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              shortenAddress(widget.value, leftSize: 6, rightSize: 4),
              style: theme.caption.copyWith(
                  color: color, fontFamily: 'monospace', fontSize: 11.5),
            ),
            const SizedBox(width: 4),
            AppIconView(
                icon: copied ? AppIcon.check : AppIcon.copy,
                size: 11,
                color: color),
          ],
        ),
      ),
    );
  }
}

class _CopyIcon extends StatefulWidget {
  final String value;
  final AppTheme theme;

  const _CopyIcon({required this.value, required this.theme});

  @override
  State<_CopyIcon> createState() => _CopyIconState();
}

class _CopyIconState extends State<_CopyIcon> with _CopyFeedback {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 28),
      onPressed: () => copy(widget.value),
      icon: AppIconView(
        icon: copied ? AppIcon.check : AppIcon.copy,
        size: 15,
        color: copied ? widget.theme.success : widget.theme.textSecondary,
      ),
    );
  }
}

mixin _CopyFeedback<T extends StatefulWidget> on State<T> {
  bool copied = false;
  Timer? _timer;

  Future<void> copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    setState(() => copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => copied = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class _Segmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final AppTheme theme;
  final Color accent;
  final ValueChanged<int> onChanged;

  const _Segmented({
    required this.labels,
    required this.index,
    required this.theme,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.modalBorder.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: i == index
                      ? accent.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  labels[i],
                  style: theme.caption.copyWith(
                    fontSize: 11,
                    color: i == index ? accent : theme.textSecondary,
                    fontWeight: i == index ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;
  final AppTheme theme;

  const _Chip({required this.text, required this.color, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text,
          style: theme.caption.copyWith(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
