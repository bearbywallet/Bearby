import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/mixins/addr.dart';
import 'package:bearby/mixins/pressable_animation.dart';
import 'package:bearby/state/app_state.dart';

class CopyContent extends StatefulWidget {
  final String address;
  final bool isShort;

  const CopyContent({
    super.key,
    required this.address,
    this.isShort = true,
  });

  @override
  State<CopyContent> createState() => _CopyContentState();
}

class _CopyContentState extends State<CopyContent>
    with SingleTickerProviderStateMixin, PressableAnimationMixin {
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    initPressAnimation(duration: const Duration(milliseconds: 200), opacityEnd: 0.7);
  }

  @override
  void dispose() {
    disposePressAnimation();
    super.dispose();
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.address));
    if (mounted) {
      setState(() {
        _isCopied = true;
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isCopied = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: buildPressableWithOpacity(
        onTap: _copyToClipboard,
        child: Container(
          decoration: BoxDecoration(
            color: theme.textSecondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              Text(
                widget.isShort
                    ? shortenAddress(widget.address)
                    : widget.address,
                style: theme.bodyText2.copyWith(
                  color: theme.textSecondary,
                ),
              ),
              SvgPicture.asset(
                _isCopied
                    ? 'assets/icons/check.svg'
                    : 'assets/icons/copy.svg',
                width: 14,
                height: 14,
                colorFilter: ColorFilter.mode(
                  _isCopied ? theme.success : theme.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
