import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/components/jazzicon.dart';
import 'package:zilpay/config/web3_constants.dart';
import 'package:zilpay/modals/qr_scanner_modal.dart';
import 'package:zilpay/src/rust/api/book.dart';
import 'package:zilpay/src/rust/api/qrcode.dart';
import 'package:zilpay/src/rust/api/utils.dart';
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

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.cardBackground.withValues(alpha: 0.85),
                theme.cardBackground.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: theme.textSecondary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryPurple.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHandle(theme),
                _buildTitle(l10n, theme),
                _buildSearchBar(l10n, theme),
                if (_isLoading)
                  _buildLoadingIndicator(theme)
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
        ),
      ),
    );
  }

  Widget _buildHandle(AppTheme theme) {
    return Container(
      width: 48,
      height: 5,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.textSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildTitle(AppLocalizations l10n, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        l10n.addressSelectModalContentTitle,
        style: theme.titleMedium.copyWith(
          color: theme.textPrimary,
          shadows: [
            Shadow(
              color: theme.primaryPurple.withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SmartInput(
        controller: _searchController,
        hint: l10n.addressSelectModalContentSearchHint,
        leftIconPath: 'assets/icons/qrcode.svg',
        onChanged: (value) async {
          try {
            bool isAddress = await isValidAddress(addr: value);
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
          } catch (_) {}
        },
        onLeftIconTap: () =>
            showQRScannerModal(context: context, onScanned: _parseQrcodRes),
        borderColor: theme.textPrimary,
        focusedBorderColor: theme.primaryPurple,
        height: 48,
        fontSize: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildLoadingIndicator(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: CircularProgressIndicator(
        color: theme.primaryPurple,
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
          _buildCategoryHeader(categoryInfo, theme),
          const SizedBox(height: 8),
          ...List.generate(entries.length, (index) {
            final entry = entries[index];
            return Column(
              children: [
                _buildAddressItem(appState, entry),
                if (index < entries.length - 1) _buildDivider(theme),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(CategoryInfo categoryInfo, AppTheme theme) {
    return Row(
      children: [
        if (categoryInfo.iconPath != null) ...[
          SvgPicture.asset(
            categoryInfo.iconPath!,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              theme.primaryPurple.withValues(alpha: 0.7),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          categoryInfo.displayName,
          style: theme.bodyText2.copyWith(
            color: theme.textPrimary,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: theme.primaryPurple.withValues(alpha: 0.2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(AppTheme theme) {
    return Divider(
      height: 1,
      thickness: 1,
      color: theme.primaryPurple.withValues(alpha: 0.15),
      endIndent: 16,
    );
  }

  Widget _buildAddressItem(AppState appState, Entry entry) {
    final l10n = AppLocalizations.of(context)!;
    final theme = appState.currentTheme;
    final currentAccount = appState.wallet?.selectedAccount.toInt() ?? 0;
    final currentAccountData = currentAccount >= 0
        ? appState.wallet?.accounts.elementAtOrNull(currentAccount)
        : null;
    final isCurrentAccount = currentAccountData?.addr == entry.address;

    return InkWell(
      onTap: () {
        QRcodeScanResultInfo params =
            QRcodeScanResultInfo(recipient: entry.address);
        widget.onAddressSelected(params, entry.name);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              theme.primaryPurple.withValues(alpha: 0.03),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatarWithNetworkIcon(appState, entry, theme),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 4),
                  Text(
                    shortenAddress(entry.address),
                    style: theme.bodyText2.copyWith(
                      color: theme.textSecondary.withValues(alpha: 0.8),
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

  Widget _buildAvatarWithNetworkIcon(
      AppState appState, Entry entry, AppTheme theme) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        children: [
          ClipOval(
            child: SizedBox(
              width: 40,
              height: 40,
              child: _getAvatarWidget(entry, theme),
            ),
          ),
          if (_shouldShowNetworkIcon(appState, entry))
            _buildNetworkIconBadge(entry, theme),
        ],
      ),
    );
  }

  Widget _buildNetworkIconBadge(Entry entry, AppTheme theme) {
    return Positioned(
      right: -2,
      bottom: -2,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: theme.cardBackground,
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.primaryPurple.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primaryPurple.withValues(alpha: 0.3),
              blurRadius: 4,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Center(
            child: SvgPicture.asset(
              _getNetworkIconPath(entry),
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                theme.primaryPurple.withValues(alpha: 0.8),
                BlendMode.srcIn,
              ),
            ),
          ),
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
    return appState.account?.slip44 == kZilliqaSlip44;
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
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
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
