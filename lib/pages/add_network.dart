import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:provider/provider.dart';
import 'package:bearby/components/button.dart';
import 'package:bearby/components/custom_app_bar.dart';
import 'package:bearby/components/smart_input.dart';
import 'package:bearby/config/web3_constants.dart';
import 'package:bearby/mixins/adaptive_size.dart';
import 'package:bearby/mixins/status_bar.dart';
import 'package:bearby/src/rust/api/provider.dart';
import 'package:bearby/src/rust/models/ftoken.dart';
import 'package:bearby/src/rust/models/provider.dart';
import 'package:bearby/state/app_state.dart';
import 'package:bearby/theme/app_theme.dart';
import 'package:bearby/l10n/app_localizations.dart';

class AddNetworkPage extends StatefulWidget {
  const AddNetworkPage({super.key});

  @override
  State<AddNetworkPage> createState() => _AddNetworkPageState();
}

class _AddNetworkPageState extends State<AddNetworkPage> with StatusBarMixin {
  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _chainController = TextEditingController();
  final _rpcController = TextEditingController();
  final _chainIdController = TextEditingController();
  final _explorerUrlController = TextEditingController();
  final _tokenSymbolController = TextEditingController();
  final _decimalsController = TextEditingController(text: '18');
  bool _isTestnet = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _chainController.dispose();
    _rpcController.dispose();
    _chainIdController.dispose();
    _explorerUrlController.dispose();
    _tokenSymbolController.dispose();
    _decimalsController.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty ||
        _shortNameController.text.trim().isEmpty ||
        _chainController.text.trim().isEmpty ||
        _rpcController.text.trim().isEmpty ||
        _chainIdController.text.trim().isEmpty ||
        _tokenSymbolController.text.trim().isEmpty ||
        _decimalsController.text.trim().isEmpty) {
      return false;
    }

    final chainId = int.tryParse(_chainIdController.text.trim());
    if (chainId == null || chainId <= 0) return false;

    final uri = Uri.tryParse(_rpcController.text.trim());
    if (uri == null || (!uri.hasScheme)) return false;

    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) {
      setState(() {
        _errorMessage =
            AppLocalizations.of(context)!.addNetworkPageErrorRequired;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final chainId = int.parse(_chainIdController.text.trim());
      final decimals =
          int.tryParse(_decimalsController.text.trim()) ?? kDefaultEvmDecimals;
      final shortName = _shortNameController.text.trim().toLowerCase();

      final explorers = <ExplorerInfo>[];
      if (_explorerUrlController.text.trim().isNotEmpty) {
        explorers.add(ExplorerInfo(
          name: _nameController.text.trim(),
          url: _explorerUrlController.text.trim(),
          standard: kDefaultExplorerStandard,
        ));
      }

      final config = NetworkConfigInfo(
        name: _nameController.text.trim(),
        logo: '',
        chain: _chainController.text.trim().toUpperCase(),
        shortName: shortName,
        rpc: [_rpcController.text.trim()],
        features: Uint16List.fromList(kDefaultEvmFeatures),
        chainId: BigInt.from(chainId),
        chainIds: Uint64List.fromList([chainId, 0]),
        slip44: kEthereumSlip44,
        diffBlockTime: BigInt.zero,
        chainHash: BigInt.zero,
        explorers: explorers,
        fallbackEnabled: true,
        testnet: _isTestnet,
        ftokens: [
          FTokenInfo(
            name: _nameController.text.trim(),
            symbol: _tokenSymbolController.text.trim().toUpperCase(),
            decimals: decimals,
            addr: '0x0000000000000000000000000000000000000000',
            addrType: kEvmAddressType,
            balances: {},
            rate: 0.0,
            default_: true,
            native: true,
            chainHash: BigInt.zero,
          ),
        ],
      );

      final appState = Provider.of<AppState>(context, listen: false);
      await addProvider(providerConfig: config);
      await appState.syncData();

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
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
                    title: l10n.addNetworkPageTitle,
                    onBackPressed: () => Navigator.pop(context),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: adaptivePadding,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        _buildField(
                          controller: _nameController,
                          hint: l10n.addNetworkFieldName,
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _shortNameController,
                          hint: l10n.addNetworkFieldShortName,
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _chainController,
                          hint: l10n.addNetworkFieldChain,
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _rpcController,
                          hint: l10n.addNetworkFieldRpc,
                          theme: theme,
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _chainIdController,
                          hint: l10n.addNetworkFieldChainId,
                          theme: theme,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _explorerUrlController,
                          hint: l10n.addNetworkFieldExplorerUrl,
                          theme: theme,
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: _tokenSymbolController,
                                hint: l10n.addNetworkFieldTokenSymbol,
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 100,
                              child: _buildField(
                                controller: _decimalsController,
                                hint: l10n.addNetworkFieldTokenDecimals,
                                theme: theme,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTestnetToggle(theme, l10n),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style:
                                theme.bodyText2.copyWith(color: theme.danger),
                          ),
                        ],
                        const SizedBox(height: 24),
                        CustomButton(
                          text: l10n.addNetworkPageButton,
                          textColor: theme.buttonText,
                          backgroundColor: theme.primaryPurple,
                          onPressed: _isLoading ? null : _submit,
                          borderRadius: 30,
                          height: 56,
                          disabled: _isLoading,
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required AppTheme theme,
    TextInputType? keyboardType,
  }) {
    return SmartInput(
      controller: controller,
      hint: hint,
      borderColor: theme.modalBorder,
      focusedBorderColor: theme.primaryPurple,
      height: 52,
      fontSize: 15,
      keyboardType: keyboardType ?? TextInputType.text,
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildTestnetToggle(AppTheme theme, AppLocalizations l10n) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.modalBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.addNetworkFieldTestnet,
              style: theme.bodyText1.copyWith(color: theme.textPrimary),
            ),
            Switch(
              value: _isTestnet,
              onChanged: (value) => setState(() => _isTestnet = value),
              activeThumbColor: theme.primaryPurple,
              activeTrackColor: theme.primaryPurple.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
