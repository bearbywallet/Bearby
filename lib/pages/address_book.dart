import 'package:zilpay/components/jazzicon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/mixins/addr.dart';
import 'package:zilpay/mixins/status_bar.dart';
import 'package:zilpay/modals/add_contect.dart';
import 'package:zilpay/src/rust/api/book.dart';
import 'package:zilpay/src/rust/models/book.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/app_theme.dart';
import '../components/custom_app_bar.dart';
import '../components/switch_setting_item.dart';
import 'package:zilpay/l10n/app_localizations.dart';

class AddressBookPage extends StatefulWidget {
  const AddressBookPage({super.key});

  @override
  State<AddressBookPage> createState() => _AddressBookPageState();
}

class _AddressBookPageState extends State<AddressBookPage>
    with StatusBarMixin {
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
            style: theme.bodyLarge.copyWith(color: theme.textPrimary),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  l10n.addressBookPageDeleteConfirmationMessage(address.name),
                  style: theme.bodyText2.copyWith(color: theme.textSecondary),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                l10n.cancel,
                style: theme.button.copyWith(color: theme.textSecondary),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(
                l10n.delete,
                style: theme.button.copyWith(color: theme.danger),
              ),
              onPressed: () async {
                try {
                  await removeFromAddressBook(addr: address.addr);
                  await state.syncData();
                } catch (_) {
                } finally {}
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleTransactionHistoryChange(bool value) async {
    final stateProvider = Provider.of<AppState>(context, listen: false);
    await stateProvider.setShowAddressesThroughTransactionHistory(value);
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    final theme = state.currentTheme;
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SwitchSettingItem(
                    backgroundColor: theme.cardBackground,
                    iconPath: "assets/icons/history.svg",
                    title: l10n.transactionHistoryTitle,
                    description: l10n.transactionHistoryDescription,
                    value: state.showAddressesThroughTransactionHistory,
                    onChanged: _handleTransactionHistoryChange,
                  ),
                ),
                const SizedBox(height: 16),
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
              style: theme.bodyLarge.copyWith(
                color: theme.textSecondary,
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
                    child: Jazzicon(
                      seed: address.addr.toLowerCase(),
                      diameter: 40,
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
                        style: theme.labelLarge.copyWith(
                          color: theme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shortenAddress(address.addr,
                            leftSize: 12, rightSize: 12),
                        style: theme.bodyText2.copyWith(
                          color: theme.textSecondary,
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
