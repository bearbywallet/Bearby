import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/addr.dart';
import 'package:zilpay/modals/add_contect.dart';
import 'package:zilpay/src/rust/api/book.dart';
import 'package:zilpay/src/rust/models/book.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/app_theme.dart';
import '../components/custom_app_bar.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class AddressBookPage extends StatefulWidget {
  const AddressBookPage({super.key});

  @override
  State<AddressBookPage> createState() => _AddressBookPageState();
}

class _AddressBookPageState extends State<AddressBookPage> {
  Future<void> _showDeleteConfirmationDialog(BuildContext context,
      AppState state, AddressBookEntryInfo address) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = state.currentTheme;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.background,
          title: Text(
            l10n.addressBookPageDeleteConfirmationTitle,
            style: TextStyle(color: theme.textPrimary),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  l10n.addressBookPageDeleteConfirmationMessage(address.name),
                  style: TextStyle(color: theme.textSecondary),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                l10n.cancel,
                style: TextStyle(color: theme.textSecondary),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(
                l10n.delete,
                style: TextStyle(color: theme.danger),
              ),
              onPressed: () async {
                try {
                  await removeFromAddressBook(addr: address.addr);
                  await state.syncData();
                } catch (_) {
                } finally {}
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = state.currentTheme;
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomAppBar(
                    title: l10n.addressBookPageTitle,
                    onBackPressed: () => Navigator.pop(context),
                    actionIcon: SvgPicture.asset(
                      'assets/icons/plus.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        theme.textPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                    onActionPressed: () => showAddContactModal(
                      context: context,
                      state: state,
                    ),
                  ),
                ),
                Expanded(
                  child: state.book.isEmpty
                      ? _buildEmptyState(theme, l10n)
                      : _buildAddressList(state, theme, l10n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppTheme theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/book.svg',
              width: 120,
              height: 120,
              colorFilter: ColorFilter.mode(
                theme.textSecondary.withValues(alpha: 0.4),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.addressBookPageEmptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList(
      AppState state, AppTheme theme, AppLocalizations l10n) {
    return ListView.builder(
      itemCount: state.book.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final address = state.book[index];
        final isLastItem = index == state.book.length - 1;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // print('Tapped on ${address.name}');
          },
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              border: !isLastItem
                  ? Border(
                      bottom: BorderSide(
                        color: theme.textSecondary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Blockies(
                      seed: address.addr.toLowerCase(),
                      size: 8,
                      color: theme.primaryPurple,
                      bgColor: theme.background,
                      spotColor: theme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.name,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shortenAddress(address.addr,
                            leftSize: 12, rightSize: 12),
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: double.infinity,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 24,
                    icon: SvgPicture.asset(
                      'assets/icons/close.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        theme.danger,
                        BlendMode.srcIn,
                      ),
                    ),
                    tooltip: l10n.addressBookPageDeleteTooltip(address.name),
                    onPressed: () {
                      _showDeleteConfirmationDialog(context, state, address);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
