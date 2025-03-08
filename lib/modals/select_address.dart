import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/addr.dart';
import 'package:zilpay/mixins/jazzicon.dart';
import 'package:zilpay/modals/qr_scanner_modal.dart';
import 'package:zilpay/src/rust/api/methods.dart';
import 'package:zilpay/src/rust/api/qrcode.dart';
import 'package:zilpay/src/rust/models/qrcode.dart';
import 'package:zilpay/state/app_state.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<AppState>(context).currentTheme;
    final appState = Provider.of<AppState>(context);

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
                  try {
                    bool isAddress = await isCryptoAddress(addr: value);
                    if (isAddress && mounted) {
                      QRcodeScanResultInfo params =
                          QRcodeScanResultInfo(recipient: value);
                      widget.onAddressSelected(params, "Unknown");
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
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
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(appState, 'My Accounts',
                        _getFilteredMyAccounts(appState)),
                    _buildSection(appState, 'Address Book',
                        _getFilteredAddressBook(appState)),
                    _buildSection(
                        appState, 'History', _getFilteredHistory(appState)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(AppState state, String title, List<AddressItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = state.currentTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Column(
              children: [
                _buildAddressItem(state, item),
                if (index < items.length - 1)
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

  Widget _buildAddressItem(AppState state, AddressItem item) {
    final theme = state.currentTheme;

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
                child: Jazzicon(
                  diameter: 30,
                  seed: item.address,
                  theme: theme,
                  shapeCount: 4,
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

  Future<void> _parseQrcodRes(String data) async {
    try {
      QRcodeScanResultInfo parsed = await parseQrcodeStr(data: data);
      if (mounted) widget.onAddressSelected(parsed, "Unknown");
    } catch (e) {
      debugPrint("error parse qrcode: $e");
    }
  }

  List<AddressItem> _getFilteredMyAccounts(AppState appState) {
    return appState.wallet?.accounts
            .where((account) =>
                account.name.toLowerCase().contains(_searchQuery) ||
                account.addr.toLowerCase().contains(_searchQuery))
            .map((account) =>
                AddressItem(name: account.name, address: account.addr))
            .toList() ??
        [];
  }

  List<AddressItem> _getFilteredAddressBook(AppState appState) {
    return appState.book
        .where((account) =>
            account.name.toLowerCase().contains(_searchQuery) ||
            account.addr.toLowerCase().contains(_searchQuery))
        .map(
            (account) => AddressItem(name: account.name, address: account.addr))
        .toList();
  }

  List<AddressItem> _getFilteredHistory(AppState appState) {
    return [];
  }
}

class AddressItem {
  final String name;
  final String address;

  AddressItem({required this.name, required this.address});
}
