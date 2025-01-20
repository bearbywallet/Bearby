import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/addr.dart';
import 'package:zilpay/mixins/colors.dart';
import 'package:zilpay/modals/qr_scanner_modal.dart';
import 'package:zilpay/src/rust/api/methods.dart';
import 'package:zilpay/src/rust/api/qrcode.dart';
import 'package:zilpay/src/rust/models/qrcode.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/app_theme.dart' as theme;

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
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddressSelectModalContent(
          onAddressSelected: onAddressSelected,
        ),
      );
    },
  );
}

class _AddressSelectModalContent extends StatefulWidget {
  final Function(QRcodeScanResultInfo, String) onAddressSelected;

  const _AddressSelectModalContent({
    required this.onAddressSelected,
  });

  @override
  State<_AddressSelectModalContent> createState() =>
      _AddressSelectModalContentState();
}

class _AddressSelectModalContentState
    extends State<_AddressSelectModalContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final appState = Provider.of<AppState>(context);

    final double headerHeight = 84.0;
    final double searchBarHeight = 80.0;
    final double sectionHeaderHeight = 40.0;
    final double addressItemHeight = 72.0;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // Calculate total height based on all sections
    final double totalContentHeight = headerHeight +
        searchBarHeight +
        (sectionHeaderHeight * 3) + // 3 section headers
        (addressItemHeight *
            (_getFilteredMyAccounts(appState).length +
                _getFilteredAddressBook(appState).length +
                _getFilteredHistory(appState).length)) +
        bottomPadding;

    final double maxHeight = MediaQuery.of(context).size.height * 0.8;
    final double containerHeight = totalContentHeight.clamp(0.0, maxHeight);

    return Container(
      height: containerHeight,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.textSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Select Address',
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SmartInput(
              controller: _searchController,
              hint: 'Search / Address / ENS',
              leftIconPath: 'assets/icons/qrcode.svg',
              onChanged: (value) async {
                bool isAddress = await isCryptoAddress(addr: value);

                if (isAddress) {
                  QRcodeScanResultInfo params =
                      QRcodeScanResultInfo(recipient: value);
                  widget.onAddressSelected(params, "Unknown");
                  Navigator.pop(context);
                } else {
                  setState(() => _searchQuery = value);
                }
              },
              onLeftIconTap: () async {
                showQRScannerModal(
                  context: context,
                  onScanned: _parseQrcodRes,
                );
              },
              borderColor: theme.textPrimary,
              focusedBorderColor: theme.primaryPurple,
              height: 48,
              fontSize: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildSection(
                  theme,
                  'My Accounts',
                  _getFilteredMyAccounts(appState),
                ),
                _buildSection(
                  theme,
                  'Address Book',
                  _getFilteredAddressBook(appState),
                ),
                _buildSection(
                  theme,
                  'History',
                  _getFilteredHistory(appState),
                ),
              ],
            ),
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildSection(
    theme.AppTheme theme,
    String title,
    List<AddressItem> items,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              _buildAddressItem(theme, item),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.textSecondary.withOpacity(0.1),
                  endIndent: 16,
                ),
            ],
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAddressItem(theme.AppTheme theme, AddressItem item) {
    return InkWell(
      onTap: () {
        QRcodeScanResultInfo params =
            QRcodeScanResultInfo(recipient: item.address);
        widget.onAddressSelected(params, item.name);
        Navigator.pop(context);
      },
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: Blockies(
                  seed: item.address,
                  color: getWalletColor(0),
                  bgColor: theme.primaryPurple,
                  spotColor: theme.background,
                  size: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    shortenAddress(item.address),
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 14,
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

  void _parseQrcodRes(String data) async {
    try {
      QRcodeScanResultInfo parsed = await parseQrcodeStr(data: data);

      widget.onAddressSelected(parsed, "Unknown");
    } catch (e) {
      debugPrint("error parse qrcode: $e");
    }
  }

  List<AddressItem> _getFilteredMyAccounts(AppState appState) {
    if (appState.wallet == null) {
      return [];
    }

    final accounts = appState.wallet!.accounts;

    return accounts
        .where((account) =>
            account.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            account.addr.toLowerCase().contains(_searchQuery.toLowerCase()))
        .map((account) => AddressItem(
              name: account.name,
              address: account.addr,
            ))
        .toList();
  }

  List<AddressItem> _getFilteredAddressBook(AppState appState) {
    return appState.book
        .where((account) =>
            account.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            account.addr.toLowerCase().contains(_searchQuery.toLowerCase()))
        .map((account) => AddressItem(
              name: account.name,
              address: account.addr,
            ))
        .toList();
  }

  List<AddressItem> _getFilteredHistory(AppState appState) {
    // Implement filtering logic for history
    return []; // Return filtered list of historical addresses
  }
}

class AddressItem {
  final String name;
  final String address;

  AddressItem({
    required this.name,
    required this.address,
  });
}
