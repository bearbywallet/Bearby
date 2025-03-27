import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/smart_input.dart';
import 'package:zilpay/mixins/addr.dart';
import 'package:zilpay/mixins/jazzicon.dart';
import 'package:zilpay/modals/qr_scanner_modal.dart';
import 'package:zilpay/src/rust/api/methods.dart';
import 'package:zilpay/src/rust/api/qrcode.dart';
import 'package:zilpay/src/rust/api/wallet.dart';
import 'package:zilpay/src/rust/models/qrcode.dart';
import 'package:zilpay/state/app_state.dart';
import 'package:zilpay/l10n/app_localizations.dart';

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
  List<AddressItem> _evmAddresses = [];
  List<AddressItem> _scillaAddresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final appState = Provider.of<AppState>(context, listen: false);

    if (appState.wallet != null) {
      try {
        final List<AddressItem> evmItems = [];
        final List<AddressItem> scillaItems = [];

        for (var i = 0; i < appState.wallet!.accounts.length; i++) {
          final account = appState.wallet!.accounts[i];
          final name = account.name;

          if (account.slip44 == 313) {
            final addresses = await getZilEthChecksumAddresses(
              walletIndex: BigInt.from(appState.selectedWallet),
            );

            if (i < addresses.length) {
              evmItems.add(AddressItem(
                name: name,
                address: addresses[i],
                addrType: 1,
                accountIndex: i,
              ));
            }

            final (bech32, base16) = await zilliqaGetBech32Base16Address(
              walletIndex: BigInt.from(appState.selectedWallet),
              accountIndex: BigInt.from(i),
            );

            scillaItems.add(AddressItem(
              name: name,
              address: bech32,
              addrType: 0,
              accountIndex: i,
            ));
          } else if (account.addrType == 1) {
            evmItems.add(AddressItem(
              name: name,
              address: account.addr,
              addrType: 1,
              accountIndex: i,
            ));
          } else {
            scillaItems.add(AddressItem(
              name: name,
              address: account.addr,
              addrType: 0,
              accountIndex: i,
            ));
          }
        }

        if (mounted) {
          setState(() {
            _evmAddresses = evmItems;
            _scillaAddresses = scillaItems;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint("Error loading addresses: $e");
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
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
    final appState = Provider.of<AppState>(context);
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
                    children: [
                      _buildSection(
                          appState,
                          '${appState.chain?.name} EVM',
                          _getFilteredAddresses(_evmAddresses),
                          'assets/icons/solidity.svg'),
                      _buildSection(
                          appState,
                          '${appState.chain?.name} Scilla',
                          _getFilteredAddresses(_scillaAddresses),
                          'assets/icons/scilla.svg'),
                      _buildSection(
                          appState,
                          l10n.addressSelectModalContentAddressBook,
                          _getFilteredAddressBook(appState),
                          null),
                      _buildSection(
                          appState,
                          l10n.addressSelectModalContentHistory,
                          _getFilteredHistory(appState),
                          null),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      AppState state, String title, List<AddressItem> items, String? iconPath) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = state.currentTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (iconPath != null) ...[
                SvgPicture.asset(
                  iconPath,
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
                title,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
    final l10n = AppLocalizations.of(context)!;
    final theme = state.currentTheme;
    final selectedAccountIndex = state.wallet?.selectedAccount.toInt() ?? 0;

    // Get current account's address type
    final selectedAccount = state.wallet?.accounts[selectedAccountIndex];
    final selectedAddrType = selectedAccount?.addrType ?? -1;

    // Only show sender tag if both index and type match
    final isSender = item.accountIndex == selectedAccountIndex &&
        item.addrType == selectedAddrType;

    return InkWell(
      onTap: () {
        QRcodeScanResultInfo params =
            QRcodeScanResultInfo(recipient: item.address);
        widget.onAddressSelected(params, item.name);
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSender)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.primaryPurple.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.addressSelectModalContentSender,
                            style: TextStyle(
                              color: theme.primaryPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
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
      if (mounted) {
        widget.onAddressSelected(parsed,
            AppLocalizations.of(context)!.addressSelectModalContentUnknown);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("error parse qrcode: $e");
    }
  }

  List<AddressItem> _getFilteredAddresses(List<AddressItem> addresses) {
    if (_searchQuery.isEmpty) return addresses;

    return addresses
        .where((item) =>
            item.name.toLowerCase().contains(_searchQuery) ||
            item.address.toLowerCase().contains(_searchQuery))
        .toList();
  }

  List<AddressItem> _getFilteredAddressBook(AppState appState) {
    final slip44 = appState.chain?.slip44 ?? 0;

    return appState.book
        .where((account) =>
            account.slip44 == slip44 &&
            (account.name.toLowerCase().contains(_searchQuery) ||
                account.addr.toLowerCase().contains(_searchQuery)))
        .map((account) => AddressItem(
              name: account.name,
              address: account.addr,
              addrType: -1,
              accountIndex: -1,
            ))
        .toList();
  }

  List<AddressItem> _getFilteredHistory(AppState appState) {
    return [];
  }
}

class AddressItem {
  final String name;
  final String address;
  final int addrType;
  final int accountIndex;

  AddressItem({
    required this.name,
    required this.address,
    required this.addrType,
    required this.accountIndex,
  });
}
