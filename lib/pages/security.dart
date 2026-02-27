import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/src/rust/api/settings.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import '../components/custom_app_bar.dart';
import 'package:bearby/l10n/app_localizations.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> with StatusBarMixin {
  final TextEditingController _ipfsController = TextEditingController(text: '');
  final Set<String> _loading = {};

  @override
  void dispose() {
    _ipfsController.dispose();
    super.dispose();
  }

  void _setLoading(String operation, bool isLoading) {
    setState(() {
      if (isLoading) {
        _loading.add(operation);
      } else {
        _loading.remove(operation);
      }
    });
  }

  Future<void> _clearImageCache(AppState appState) async {
    final String operation = 'imageCache';
    try {
      _setLoading(operation, true);
      final cacheDir = Directory(appState.cahceDir);

      if (!await cacheDir.exists()) {
        return;
      }

      final entries = cacheDir.listSync();

      for (final entry in entries) {
        if (entry is File) {
          await entry.delete();
        }
      }

      await appState.syncData();
    } catch (e) {
      debugPrint("Error clearing image cache: $e");
    } finally {
      _setLoading(operation, false);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppState>(context, listen: false);

      if (state.wallet != null && state.wallet!.settings.ipfsNode != null) {
        _ipfsController.text = state.wallet!.settings.ipfsNode!;
      } else {
        _ipfsController.text = "dweb.link";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
        systemOverlayStyle: getSystemUiOverlayStyle(context),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                  child: CustomAppBar(
                    title: l10n.securityPageTitle,
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding:
                            EdgeInsets.symmetric(horizontal: adaptivePadding),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildNetworkSection(appState),
                            const SizedBox(height: 32),
                            _buildClearDataSection(appState),
                            const SizedBox(height: 32),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkSection(AppState state) {
    final theme = state.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Text(
            l10n.securityPageNetworkPrivacy,
            style: theme.bodyLarge.copyWith(
              color: theme.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildPreferenceItem(
                state,
                l10n.securityPageTokensFetcherTitle,
                'assets/icons/globe.svg',
                l10n.securityPageTokensFetcherDescription,
                true,
                state.wallet!.settings.tokensListFetcher,
                (value) async {
                  await setTokensListFetcher(
                    walletIndex: BigInt.from(state.selectedWallet),
                    enabled: value,
                  );
                  await state.syncData();
                },
              ),
              Divider(
                  height: 1, color: theme.textSecondary.withValues(alpha: 0.1)),
              _buildPreferenceItem(
                state,
                l10n.securityPageEnsDomains,
                'assets/icons/graph.svg',
                l10n.securityPageEnsDescription,
                true,
                state.wallet!.settings.ensEnabled,
                (value) async {
                  await setWalletEns(
                    walletIndex: BigInt.from(state.selectedWallet),
                    ensEnabled: value,
                  );
                  await state.syncData();
                },
              ),
              Divider(
                  height: 1, color: theme.textSecondary.withValues(alpha: 0.1)),
              _buildPreferenceItem(
                state,
                l10n.securityPageIpfsGateway,
                'assets/icons/ipfs.svg',
                l10n.securityPageIpfsDescription,
                true,
                state.wallet!.settings.ipfsNode != null,
                (value) async {
                  await setWalletIpfsNode(
                    walletIndex: BigInt.from(state.selectedWallet),
                    node: value ? _ipfsController.text : null,
                  );
                  await state.syncData();
                },
                showInput: true,
                controller: _ipfsController,
              ),
              Divider(
                  height: 1, color: theme.textSecondary.withValues(alpha: 0.1)),
              _buildPreferenceItem(
                state,
                l10n.securityPageNodeRanking,
                'assets/icons/server.svg',
                l10n.securityPageNodeDescription,
                true,
                state.wallet!.settings.nodeRankingEnabled,
                (value) async {
                  await setWalletNodeRanking(
                    walletIndex: BigInt.from(state.selectedWallet),
                    enabled: value,
                  );
                  await state.syncData();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceItem(
    AppState state,
    String title,
    String iconPath,
    String description,
    bool hasSwitch,
    bool value,
    Function(bool)? onChanged, {
    VoidCallback? onTap,
    bool showInput = false,
    TextEditingController? controller,
  }) {
    final theme = state.currentTheme;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    theme.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: theme.bodyLarge.copyWith(
                      color: theme.textPrimary,
                    ),
                  ),
                ),
                if (hasSwitch)
                  Switch(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: theme.primaryPurple,
                  )
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  description,
                  style: theme.bodyText2.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
              ),
            ],
            if (showInput) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: TextField(
                  controller: controller,
                  readOnly: !value,
                  style: theme.bodyText2.copyWith(
                    color: value
                        ? theme.textPrimary
                        : theme.textSecondary.withValues(alpha: 0.5),
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.textSecondary.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: theme.primaryPurple,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClearDataSection(AppState state) {
    final theme = state.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Text(
            l10n.securityPageClearData,
            style: theme.bodyLarge.copyWith(
              color: theme.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _buildClearDataItem(
            theme,
            l10n.securityPageClearImageCache,
            'assets/icons/cache.svg',
            l10n.securityPageClearImageCacheDescription,
            () => _clearImageCache(state),
            _loading.contains('imageCache'),
          ),
        ),
      ],
    );
  }

  Widget _buildClearDataItem(
    AppTheme theme,
    String title,
    String iconPath,
    String description,
    VoidCallback onTap,
    bool isLoading,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  theme.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.bodyLarge.copyWith(
                    color: theme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Text(
              description,
              style: theme.bodyText2.copyWith(
                color: theme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : onTap,
              style: TextButton.styleFrom(
                foregroundColor: theme.primaryPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(theme.primaryPurple),
                      ),
                    )
                  : Text(l10n.browserSettingsClear),
            ),
          ),
        ],
      ),
    );
  }
}
