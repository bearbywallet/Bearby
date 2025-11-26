import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/jazzicon.dart';
import 'package:zilpay/modals/qr_scanner_modal.dart';
import 'package:zilpay/src/rust/api/book.dart';
import 'package:zilpay/src/rust/api/methods.dart';
import 'package:zilpay/src/rust/api/qrcode.dart';
import 'package:zilpay/src/rust/models/qrcode.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';
import 'package:zilpay/theme/app_theme.dart';

void showAddressSelectModal({
  required BuildContext context,
  required Function(QRcodeScanResultInfo, String) onAddressSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    enableDrag: true,
    isDismissible: true,
    useSafeArea: true,
    barrierColor: Colors.black54,
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _AddressSelectModalContent(onAddressSelected: onAddressSelected),
    ),
  );
}

class _AddressSelectModalContent extends StatefulWidget {
  final Function(QRcodeScanResultInfo, String) onAddressSelected;

  const _AddressSelectModalContent({required this.onAddressSelected});

  @override
  State<_AddressSelectModalContent> createState() =>
      _AddressSelectModalContentState();
}

class _AddressSelectModalContentState
    extends State<_AddressSelectModalContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      final categories = await getCombineSortAddresses(
        walletIndex: BigInt.from(appState.selectedWallet),
        history: appState.showAddressesThroughTransactionHistory,
      );

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading addresses: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: theme.modalBorder, width: 2),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: theme.modalBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.addressSelectModalContentTitle,
                style: theme.titleMedium.copyWith(color: theme.textPrimary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SmartInput(
                controller: _searchController,
                hint: l10n.addressSelectModalContentSearchHint,
                leftIconPath: 'assets/icons/qrcode.svg',
                onChanged: (value) async {
                  try {
                    bool isAddress = await isCryptoAddress(addr: value);
                    if (isAddress && mounted) {
                      QRcodeScanResultInfo params =
                          QRcodeScanResultInfo(recipient: value);
                      widget.onAddressSelected(
                        params,
                        l10n.addressSelectModalContentUnknown,
                      );
                    } else {
                      setState(() => _searchQuery = value.toLowerCase());
                    }
                  } catch (_) {
                    //
                  }
                },
                onLeftIconTap: () => showQRScannerModal(
                    context: context, onScanned: _parseQrcodRes),
                borderColor: theme.textPrimary,
                focusedBorderColor: theme.primaryPurple,
                height: 48,
                fontSize: 16,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: theme.primaryPurple,
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildCategoryWidgets(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryWidgets() {
    return _categories.map((category) {
      final filteredEntries = _getFilteredEntries(category.entries);
      if (filteredEntries.isEmpty) return const SizedBox.shrink();

      return _buildCategorySection(category.name, filteredEntries);
    }).toList();
  }

  Widget _buildCategorySection(String categoryName, List<Entry> entries) {
    final appState = Provider.of<AppState>(context, listen: false);
    final theme = appState.currentTheme;
    final l10n = AppLocalizations.of(context)!;

    final categoryInfo = _getCategoryInfo(categoryName, l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (categoryInfo.iconPath != null) ...[
                SvgPicture.asset(
                  categoryInfo.iconPath!,
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    theme.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                categoryInfo.displayName,
                style: theme.bodyText2.copyWith(
                  color: theme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(entries.length, (index) {
            final entry = entries[index];
            return Column(
              children: [
                _buildAddressItem(appState, entry),
                if (index < entries.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.textSecondary.withValues(alpha: 0.1),
                    endIndent: 16,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAddressItem(AppState appState, Entry entry) {
    final l10n = AppLocalizations.of(context)!;
    final theme = appState.currentTheme;

    final currentAccount = appState.wallet?.selectedAccount.toInt() ?? 0;
    final currentAccountData = appState.wallet?.accounts[currentAccount];
    final isCurrentAccount = currentAccountData?.addr == entry.address;

    return InkWell(
      onTap: () {
        QRcodeScanResultInfo params =
            QRcodeScanResultInfo(recipient: entry.address);
        widget.onAddressSelected(params, entry.name);
      },
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Stack(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: _getAvatarWidget(entry, theme),
                  ),
                ),
                if (_shouldShowNetworkIcon(appState, entry))
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.background,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: theme.cardBackground, width: 1),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(2),
                        child: Center(
                          child: SvgPicture.asset(
                            _getNetworkIconPath(entry),
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              theme.textSecondary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.name.isNotEmpty
                              ? entry.name
                              : l10n.addressSelectModalContentUnknown,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ..._buildTags(entry, isCurrentAccount, theme, l10n),
                    ],
                  ),
                  Text(
                    shortenAddress(entry.address),
                    style: theme.bodyText2.copyWith(color: theme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTags(Entry entry, bool isCurrentAccount, AppTheme theme,
      AppLocalizations l10n) {
    List<Widget> tags = [];

    if (isCurrentAccount) {
      tags.add(_buildTag(
        l10n.addressSelectModalContentSender,
        theme.primaryPurple,
        theme,
      ));
    }

    if (entry.tag != null) {
      tags.add(_buildTag(
        _getTagDisplayName(entry.tag!, l10n),
        _getTagColor(entry.tag!, theme),
        theme,
      ));
    }

    return tags;
  }

  bool _shouldShowNetworkIcon(AppState appState, Entry entry) {
    return _isZilliqaNetwork(appState);
  }

  bool _isZilliqaNetwork(AppState appState) {
    return appState.account?.slip44 == 313;
  }

  String _getNetworkIconPath(Entry entry) {
    final isEvm = entry.tag == "evm" || _isEvmAddress(entry.address);
    return isEvm ? 'assets/icons/solidity.svg' : 'assets/icons/scilla.svg';
  }

  Widget _getAvatarWidget(Entry entry, AppTheme theme) {
    return Jazzicon(
      diameter: 30,
      seed: entry.address,
      shapeCount: 4,
    );
  }

  Widget _buildTag(String text, Color color, AppTheme theme) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  CategoryInfo _getCategoryInfo(String categoryName, AppLocalizations l10n) {
    switch (categoryName) {
      case "my_accounts":
        return CategoryInfo(
          displayName: l10n.addressSelectModalContentMyAccounts,
          iconPath: "assets/icons/wallet.svg",
        );
      case "book":
        return CategoryInfo(
          displayName: l10n.addressSelectModalContentAddressBook,
          iconPath: "assets/icons/book.svg",
        );
      case "history":
        return CategoryInfo(
          displayName: l10n.addressSelectModalContentHistory,
          iconPath: "assets/icons/history.svg",
        );
      default:
        return CategoryInfo(
          displayName: categoryName,
          iconPath: "assets/icons/wallet.svg",
        );
    }
  }

  String _getTagDisplayName(String tag, AppLocalizations l10n) {
    switch (tag) {
      case "legacy":
        return "Legacy";
      case "evm":
        return "EVM";
      case "book":
        return l10n.addressSelectModalContentAddressBook;
      default:
        return tag;
    }
  }

  Color _getTagColor(String tag, AppTheme theme) {
    switch (tag) {
      case "legacy":
        return theme.primaryPurple;
      case "evm":
        return theme.primaryPurple;
      case "book":
        return theme.secondaryPurple;
      default:
        return theme.textSecondary;
    }
  }

  bool _isEvmAddress(String address) {
    return address.toLowerCase().startsWith('0x');
  }

  String shortenAddress(String address) {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 6)}';
  }

  Future<void> _parseQrcodRes(String data) async {
    try {
      QRcodeScanResultInfo parsed = await parseQrcodeStr(data: data);
      if (mounted) {
        widget.onAddressSelected(parsed,
            AppLocalizations.of(context)!.addressSelectModalContentUnknown);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("error parse qrcode: $e");
    }
  }

  List<Entry> _getFilteredEntries(List<Entry> entries) {
    if (_searchQuery.isEmpty) return entries;

    return entries
        .where((entry) =>
            entry.name.toLowerCase().contains(_searchQuery) ||
            entry.address.toLowerCase().contains(_searchQuery))
        .toList();
  }
}

class CategoryInfo {
  final String displayName;
  final String? iconPath;

  CategoryInfo({
    required this.displayName,
    this.iconPath,
  });
}
