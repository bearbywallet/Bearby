import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../components/custom_app_bar.dart';

class AddressBookPage extends StatefulWidget {
  const AddressBookPage({super.key});

  @override
  State<AddressBookPage> createState() => _AddressBookPageState();
}

class _AddressBookPageState extends State<AddressBookPage> {
  final List<Address> addresses = [
    // Address("test"),
    // Address("Wallet"),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      body: Column(
        children: [
          CustomAppBar(
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
              // Handle add address
            },
          ),
          Expanded(
            child: addresses.isEmpty
                ? _buildEmptyState(theme)
                : _buildAddressList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/icons/book.svg',
            width: 120,
            height: 120,
            colorFilter: ColorFilter.mode(
              theme.textSecondary.withOpacity(0.4),
              BlendMode.srcIn,
            ),
          ),
          SizedBox(height: 16),
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
    );
  }

  Widget _buildAddressList(AppTheme theme) {
    return ListView.builder(
      itemCount: addresses.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final address = addresses[index];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Handle address selection
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/book.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    theme.textSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    address.name,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SvgPicture.asset(
                  'assets/icons/chevron-right.svg',
                  colorFilter: ColorFilter.mode(
                    theme.textSecondary,
                    BlendMode.srcIn,
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

class Address {
  final String name;

  Address(this.name);
}
