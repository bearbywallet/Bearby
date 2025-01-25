import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/modals/add_contect.dart';
import 'package:zilpay/state/app_state.dart';
import '../theme/app_theme.dart';
import '../components/custom_app_bar.dart';

class AddressBookPage extends StatefulWidget {
  const AddressBookPage({super.key});

  @override
  State<AddressBookPage> createState() => _AddressBookPageState();
}

class _AddressBookPageState extends State<AddressBookPage> {
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final theme = state.currentTheme;

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
                    title: 'Address Book',
                    onBackPressed: () => Navigator.pop(context),
                    actionWidget: SvgPicture.asset(
                      'assets/icons/plus.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        theme.textPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                    onActionPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: theme.cardBackground,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) => AddAddressModal(
                          theme: theme,
                          state: state,
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: state.book.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildAddressList(state),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppTheme theme) {
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
              'Your contacts and their wallet address will\nappear here.',
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

  Widget _buildAddressList(AppState state) {
    final theme = state.currentTheme;

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
            // Handle address selection
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
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Netowrk ${address.net}",
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.asset(
                    'assets/icons/chevron_right.svg',
                    colorFilter: ColorFilter.mode(
                      theme.textSecondary,
                      BlendMode.srcIn,
                    ),
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
