import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/jazzicon.dart';
import 'package:bearby/src/rust/models/account.dart';
import 'package:bearby/state/app_state.dart';

class AvatarAddress extends StatelessWidget {
  final double avatarSize;
  final AccountInfo account;

  const AvatarAddress({
    super.key,
    required this.avatarSize,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.primaryPurple.withAlpha(0x1A),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: account.addrType == 1
            ? Jazzicon(
                diameter: avatarSize,
                seed: account.addr,
                shapeCount: 4,
              )
            : Jazzicon(
                diameter: avatarSize,
                seed: account.addr,
                shapeCount: 4,
              ),
      ),
    );
  }
}
