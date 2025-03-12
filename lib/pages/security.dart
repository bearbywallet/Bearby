import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/adaptive_size.dart';
import 'package:zilpay/mixins/wallet_type.dart';
import 'package:zilpay/src/rust/api/settings.dart';
import 'package:zilpay/state/app_state.dart';
import '../components/custom_app_bar.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final TextEditingController _ipfsController = TextEditingController(text: '');

  @override
  void dispose() {
    _ipfsController.dispose();
    super.dispose();
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
    final appState = Provider.of<AppState>(context);
    final theme = appState.currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.background,
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
                            if (!appState.wallet!.walletType
                                .contains(WalletType.ledger.name)) ...[
                              // const SizedBox(height: 32)
                            ],
                            _buildEncryptionSection(appState),
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
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 16,
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
                l10n.securityPageGasStation,
                'assets/icons/gas.svg',
                l10n.securityPageGasDescription,
                true,
                state.wallet!.settings.gasControlEnabled,
                (value) async {
                  await setWalletGasControl(
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
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (hasSwitch)
                  Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: theme.primaryPurple,
                  )
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  description,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
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
                  style: TextStyle(
                    color: value
                        ? theme.textPrimary
                        : theme.textSecondary.withValues(alpha: 0.5),
                    fontSize: 14,
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

  Widget _buildEncryptionSection(AppState state) {
    final theme = state.currentTheme;
    final algorithms = generateAlgorithms(state.wallet!.settings.cipherOrders);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Text(
            l10n.securityPageEncryptionLevel,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (int i = 0; i < algorithms.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SvgPicture.asset(
                        'assets/icons/chevron_right.svg',
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                          theme.textSecondary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 250,
                    child: _buildEncryptionCard(
                      state,
                      algorithms[i],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEncryptionCard(
    AppState state,
    Algorithm algorithm,
  ) {
    final theme = state.currentTheme;
    final cardWidth = MediaQuery.of(context).size.width > 480
        ? 320.0
        : MediaQuery.of(context).size.width * 0.7;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(
                  algorithm.icon,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    theme.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                algorithm.name,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressBar(
            state,
            l10n.securityPageProtection,
            algorithm.protection,
            theme.primaryPurple,
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            state,
            l10n.securityPageCpuLoad,
            algorithm.cpuLoad,
            theme.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    AppState state,
    String label,
    double value,
    Color color,
  ) {
    final theme = state.currentTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Algorithm> generateAlgorithms(List<int> algorithms) {
    final l10n = AppLocalizations.of(context)!;
    final Map<int, Algorithm> algorithmData = {
      0: Algorithm(
        name: l10n.securityPageAes256,
        protection: 0.60,
        cpuLoad: 0.3,
        icon: 'assets/icons/lock.svg',
      ),
      1: Algorithm(
        name: l10n.securityPageKuznechikGost,
        protection: 0.70,
        cpuLoad: 0.2,
        icon: 'assets/icons/grasshopper.svg',
      ),
      2: Algorithm(
        name: l10n.securityPageNtruPrime,
        protection: 0.92,
        cpuLoad: 0.9,
        icon: 'assets/icons/atom.svg',
      ),
      3: Algorithm(
        name: l10n.securityPageCyber,
        protection: 0.70,
        cpuLoad: 0.5,
        icon: 'assets/icons/atom.svg',
      ),
    };

    return algorithms.map((algo) {
      return algorithmData[algo] ??
          Algorithm(
            name: l10n.securityPageUnknown,
            protection: 0.0,
            cpuLoad: 0.0,
            icon: 'assets/icons/lock.svg',
          );
    }).toList();
  }
}

class Algorithm {
  final String name;
  final double protection;
  final double cpuLoad;
  final String icon;

  const Algorithm({
    required this.name,
    required this.protection,
    required this.cpuLoad,
    required this.icon,
  });
}
