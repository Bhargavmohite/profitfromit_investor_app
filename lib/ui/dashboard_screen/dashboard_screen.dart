import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:profit_from_it_investors/provider/authentication/profile_provider.dart';
import 'package:profit_from_it_investors/ui/analytics_screen/analytics_screen.dart';
import 'package:profit_from_it_investors/ui/authentication/profile_screen/profile_screen.dart';
import 'package:profit_from_it_investors/ui/holdings_screen/holdings_screen.dart';
import 'package:profit_from_it_investors/ui/home/home_screen.dart';
import 'package:profit_from_it_investors/ui/taxometer_screen/taxometer_screen.dart';
import 'package:profit_from_it_investors/ui/watchlist_screen/watchlist_screen.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/style.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const List<BottomNavigationBarItem> items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined, color: AppColor.inactiveBottomMenu),
      activeIcon: Icon(Icons.home, color: AppColor.primary),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_wallet_outlined, color: AppColor.inactiveBottomMenu),
      activeIcon: Icon(Icons.account_balance_wallet, color: AppColor.primary),
      label: 'Holdings',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart_outlined, color: AppColor.inactiveBottomMenu),
      activeIcon: Icon(Icons.bar_chart, color: AppColor.primary),
      label: 'Analytics',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.speed_outlined, color: AppColor.inactiveBottomMenu),
      activeIcon: Icon(Icons.speed_rounded, color: AppColor.primary),
      label: 'Taxometer',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bookmark_border, color: AppColor.inactiveBottomMenu),
      activeIcon: Icon(Icons.bookmark, color: AppColor.primary),
      label: 'Movers',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline, color: AppColor.inactiveBottomMenu),
      activeIcon: Icon(Icons.person, color: AppColor.primary),
      label: 'Profile',
    ),
  ];

  late final List<Widget> pages;

  //List<Widget> pages = [HomeScreen(), HoldingsScreen(), AnalyticsScreen(), WatchlistScreen(), ProfileScreen()];

  int index = 0;

  @override
  void initState() {
    index = 0;
    super.initState();
    pages = [
      HomeScreen(
        onViewAllHoldings: () {
          setState(() {
            index = 1;
          });
        },
      ),
      HoldingsScreen(),
      AnalyticsScreen(),
      TaxometerScreen(),
      WatchlistScreen(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await _showExitDialog();
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLogoutLoading) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator(color: AppColor.primary)),
            );
          } else {
            return Scaffold(
              body: pages[index],
              bottomNavigationBar: BottomNavigationBar(
                items: items,
                currentIndex: index,
                onTap: (int value) {
                  setState(() {
                    index = value;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                iconSize: 22,
                selectedFontSize: 10,
                unselectedFontSize: 10,
                showUnselectedLabels: true,
                selectedItemColor: AppColor.primary,
                unselectedItemColor: AppColor.textLight,
              ),
            );
          }
        },
      ),
    );
  }

  Future<bool> _showExitDialog() async {
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Exit App", style: largeBold.copyWith(color: AppColor.black)),
        content: Text("Are you sure you want to exit the app?", style: medium.copyWith(color: AppColor.black)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel", style: medium.copyWith(color: AppColor.black)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Exit", style: medium.copyWith(color: AppColor.black)),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }
}
