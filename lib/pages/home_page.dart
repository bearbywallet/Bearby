import 'package:blockies/blockies.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zilpay/components/hoverd_svg.dart';
import 'package:zilpay/components/tile_button.dart';
import '../theme/theme_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 2));
    print('Data refreshed');
  }

  Color _getWalletColor(int index) {
    final colors = [
      const Color(0xFF55A2F2),
      const Color(0xFFFFB347),
      const Color(0xFF4ECFB0),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.primaryPurple.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Blockies(
                          seed: "dasdsadsadsa",
                          color: _getWalletColor(0),
                          bgColor: theme.primaryPurple,
                          spotColor: theme.background,
                          size: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Main wallet',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                HoverSvgIcon(
                  assetName: 'assets/icons/gear.svg',
                  width: 30,
                  height: 30,
                  onTap: () {
                    print('Settings tapped');
                  },
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                TileButton(
                  title: 'Send',
                  icon: SvgPicture.asset(
                    "assets/icons/send.svg",
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      theme.primaryPurple,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () {},
                  backgroundColor: theme.cardBackground,
                  textColor: theme.primaryPurple,
                ),
                const SizedBox(width: 12),
                TileButton(
                  title: 'Receive',
                  icon: SvgPicture.asset(
                    "assets/icons/receive.svg",
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      theme.primaryPurple,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () {},
                  backgroundColor: theme.cardBackground,
                  textColor: theme.primaryPurple,
                ),
                const SizedBox(width: 12),
                TileButton(
                  title: 'Swap',
                  icon: SvgPicture.asset(
                    "assets/icons/swap.svg",
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      theme.primaryPurple,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () {},
                  backgroundColor: theme.cardBackground,
                  textColor: theme.primaryPurple,
                ),
                const SizedBox(width: 12),
                TileButton(
                  title: 'Buy',
                  icon: SvgPicture.asset(
                    "assets/icons/buy.svg",
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      theme.primaryPurple,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () {},
                  backgroundColor: theme.cardBackground,
                  textColor: theme.primaryPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
