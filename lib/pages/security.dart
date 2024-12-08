import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/adaptive_size.dart';

import '../components/custom_app_bar.dart';
import '../theme/app_theme.dart' as theme;
import '../theme/theme_provider.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool isFaceIdEnabled = false;
  bool isRateFetcherEnabled = true;
  bool isGasStationEnabled = true;
  bool isNodeRankingEnabled = true;
  bool isENSEnabled = true;
  bool isIPFSEnabled = true;

  final TextEditingController _ipfsController =
      TextEditingController(text: 'dweb.link');

  @override
  void dispose() {
    _ipfsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final adaptivePadding = AdaptiveSize.getAdaptivePadding(context, 16);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Security',
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: adaptivePadding),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildNetworkSection(theme),
                        const SizedBox(height: 32),
                        _buildSecuritySection(theme),
                        const SizedBox(height: 32),
                        _buildEncryptionSection(theme),
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
    );
  }

  Widget _buildSecuritySection(theme.AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildPreferenceItem(
                theme,
                'Change wallet password',
                'assets/icons/key.svg',
                'Secure your wallet with a strong password',
                false,
                false,
                null,
                onTap: () {
                  debugPrint("change password");
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkSection(theme.AppTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Text(
            'Network Privacy',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 16,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildPreferenceItem(
                theme,
                'Show balance and token price checker',
                'assets/icons/currency.svg',
                'ZilPay wallet makes requests to fetch current rates of currency',
                true,
                isRateFetcherEnabled,
                (value) => setState(() => isRateFetcherEnabled = value),
              ),
              Divider(height: 1, color: theme.textSecondary.withOpacity(0.1)),
              _buildPreferenceItem(
                theme,
                'Show ENS domains in address bar',
                'assets/icons/graph.svg',
                'Keep in mind that using this feature exposes your IP address to IPFS third-party services.',
                true,
                isENSEnabled,
                (value) => setState(() => isRateFetcherEnabled = value),
              ),
              Divider(height: 1, color: theme.textSecondary.withOpacity(0.1)),
              _buildPreferenceItem(
                theme,
                'IPFS gateway',
                'assets/icons/ipfs.svg',
                'ZIlPay uses third-party services to show images of your NFTs stored on IPFS, display information related to ENS(ZNS) addresses entered in your browser\'s address bar, and fetch icons for different tokens. Your IP address may be exposed to these services when you\'re using them.',
                true,
                isIPFSEnabled,
                (value) => setState(() => isIPFSEnabled = value),
                showInput: true,
                controller: _ipfsController,
              ),
              Divider(height: 1, color: theme.textSecondary.withOpacity(0.1)),
              _buildPreferenceItem(
                theme,
                'Gas station',
                'assets/icons/gas.svg',
                'Use ZilPay server for optimize your gas usage',
                true,
                isGasStationEnabled,
                (value) => setState(() => isGasStationEnabled = value),
              ),
              Divider(height: 1, color: theme.textSecondary.withOpacity(0.1)),
              _buildPreferenceItem(
                theme,
                'Node ranking',
                'assets/icons/server.svg',
                'Make requests to ZilPay server for fetch best node',
                true,
                isNodeRankingEnabled,
                (value) => setState(() => isNodeRankingEnabled = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceItem(
    theme.AppTheme theme,
    String title,
    String iconPath,
    String description,
    bool hasSwitch,
    bool value,
    Function(bool)? onChanged, {
    VoidCallback? onTap,
    bool showInput = false,
    TextEditingController? controller,
    String? hintText,
  }) {
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
                        : theme.textSecondary.withOpacity(0.5),
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
                        color: theme.textSecondary.withOpacity(0.2),
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

  Widget _buildEncryptionSection(theme.AppTheme theme) {
    final algorithms = [
      {
        'name': 'AES256',
        'protection': 0.60,
        'cpuLoad': 0.3,
        'icon': 'assets/icons/lock.svg',
      },
      {
        'name': 'NTRUPrime',
        'protection': 0.92,
        'cpuLoad': 0.9,
        'icon': 'assets/icons/atom.svg',
      },
      {
        'name': 'Cyber',
        'protection': 0.70,
        'cpuLoad': 0.5,
        'icon': 'assets/icons/atom.svg',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 16),
          child: Text(
            'Encryption Level',
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
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: _buildEncryptionCard(
                      theme,
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
    theme.AppTheme theme,
    Map<String, dynamic> algorithm,
  ) {
    return Container(
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
                  algorithm['icon'],
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
                algorithm['name'],
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
            theme,
            'Protection',
            algorithm['protection'],
            theme.primaryPurple,
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            theme,
            'CPU Load',
            algorithm['cpuLoad'],
            theme.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    theme.AppTheme theme,
    String label,
    double value,
    Color color,
  ) {
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
}
