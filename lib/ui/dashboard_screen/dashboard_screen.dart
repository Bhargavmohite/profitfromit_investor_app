import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/provider/authentication/profile_provider.dart';
import 'package:profit_from_it_investors/provider/authentication/user_provider.dart';
import 'package:profit_from_it_investors/provider/client_switch/client_switch_provider.dart';
import 'package:profit_from_it_investors/ui/analytics_screen/analytics_screen.dart';
import 'package:profit_from_it_investors/ui/authentication/profile_screen/profile_screen.dart';
import 'package:profit_from_it_investors/ui/holdings_screen/holdings_screen.dart';
import 'package:profit_from_it_investors/ui/home/home_screen.dart';
import 'package:profit_from_it_investors/ui/support_messages/support_messages_screen.dart';
import 'package:profit_from_it_investors/ui/taxometer_screen/taxometer_screen.dart';
import 'package:profit_from_it_investors/ui/watchlist_screen/watchlist_screen.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/notification_service.dart';
import 'package:profit_from_it_investors/utility/style.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget> _pages;
  final PageController _pageController = PageController();
  int _index = 0;

  static const List<_NavDestination> _destinations = [
    _NavDestination(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavDestination(
      label: 'Analytics',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
    ),
    _NavDestination(
      label: 'Taxometer',
      icon: Icons.speed_outlined,
      activeIcon: Icons.speed_rounded,
    ),
    _NavDestination(
      label: 'Movers',
      icon: Icons.trending_up_outlined,
      activeIcon: Icons.trending_up_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pages = [
      HomeScreen(
        onOpenMenu: _openMenu,
        onGoHome: () => _selectTab(0),
        onViewAllHoldings: _openHoldings,
        onOpenAnalytics: () => _selectTab(1),
        onOpenTaxometer: () => _selectTab(2),
        onOpenMovers: () => _selectTab(3),
        onOpenProfile: _openProfile,
        onOpenSupportMessages: () =>
            _openSupportMessages(nominationRequest: true),
      ),
      AnalyticsScreen(onOpenMenu: _openMenu),
      TaxometerScreen(onOpenMenu: _openMenu),
      WatchlistScreen(onOpenMenu: _openMenu),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.openPendingSupportTicketIfPossible();
    });
  }

  void _openMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _selectTab(int value) {
    if (!mounted || value < 0 || value >= _pages.length) return;

    if (_index == value) return;

    // Keep bottom navigation, drawer navigation and swipe navigation in sync.
    // animateToPage gives a smooth transition when a tab is selected by tap.
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        value,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      setState(() => _index = value);
    }
  }

  void _onPageChanged(int value) {
    if (!mounted || _index == value) return;
    setState(() => _index = value);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openHoldings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HoldingsScreen(
          onGoHome: () => _selectTab(0),
          onOpenAnalytics: () => _selectTab(1),
          onOpenTaxometer: () => _selectTab(2),
          onOpenMovers: () => _selectTab(3),
        ),
      ),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  Future<void> _openSupportMessages({bool nominationRequest = false}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SupportMessagesScreen(nominationRequest: nominationRequest),
      ),
    );
  }

  void _closeDrawerThen(VoidCallback action) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_index != 0) {
          _selectTab(0);
          return;
        }

        final shouldExit = await _showExitDialog();
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLogoutLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColor.primary),
              ),
            );
          }

          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColor.background,
            drawer: _buildDrawer(context),
            drawerScrimColor: const Color(0xFF0F172A).withValues(alpha: .34),

            // Keep the floating navigation inside the page Stack instead of
            // Scaffold.bottomNavigationBar. This removes the extra outer
            // bottom-bar container completely while preserving the existing
            // curved white navigation pill exactly as it is.
            body: Stack(
              children: [
                Positioned.fill(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const PageScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: _pages,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildFloatingBottomNavigation(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingBottomNavigation() {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        // Keep the existing curved white navigation pill. The area outside
        // this container is now the page itself, not a bottom-bar wrapper.
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFE7ECF3), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0F172A),
              blurRadius: 18,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_destinations.length, (i) {
            final item = _destinations[i];
            final selected = _index == i;

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _selectTab(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColor.primary.withValues(alpha: .09)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: selected ? 31 : 28,
                        height: 28,
                        alignment: Alignment.center,
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          size: selected ? 22 : 21,
                          color: selected
                              ? AppColor.primary
                              : AppColor.inactiveBottomMenu,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          height: 1.1,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected
                              ? AppColor.primary
                              : AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = context.watch<UserProvider>();
    final clientSwitchProvider = context.watch<ClientSwitchProvider>();
    final selectedClient = clientSwitchProvider.selectedClient;

    // Keep the drawer identity in sync with Switch User immediately.
    // ClientSwitchProvider changes as soon as a client is selected and also
    // rolls back if the destination dashboard request fails. This means the
    // sidebar no longer waits for the Profile page to refresh UserProvider.
    final selectedName = (selectedClient?.name ?? '').trim();
    final selectedCode = (selectedClient?.ccode ?? '').trim();

    final name = selectedName.isNotEmpty
        ? selectedName
        : (user.name.trim().isEmpty ? 'Investor' : user.name.trim());
    final code = selectedCode.isNotEmpty ? selectedCode : user.code.trim();
    final email = selectedClient == null ? user.email.trim() : '';

    return Drawer(
      width: MediaQuery.sizeOf(context).width * .82,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => _closeDrawerThen(_openProfile),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF082D59), Color(0xFF0D3CCF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.primary.withValues(alpha: .18),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .32),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 11),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        code.isNotEmpty
                            ? 'Client Code: $code'
                            : (email.isNotEmpty ? email : 'View Profile'),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: .78),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'View Profile',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'NAVIGATION',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    color: AppColor.textLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                children: [
                  _drawerItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: _index == 0,
                    onTap: () => _closeDrawerThen(() => _selectTab(0)),
                  ),
                  _drawerItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Holdings',
                    onTap: () => _closeDrawerThen(_openHoldings),
                  ),
                  _drawerItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Analytics',
                    selected: _index == 1,
                    onTap: () => _closeDrawerThen(() => _selectTab(1)),
                  ),
                  _drawerItem(
                    icon: Icons.speed_rounded,
                    label: 'Taxometer',
                    selected: _index == 2,
                    onTap: () => _closeDrawerThen(() => _selectTab(2)),
                  ),
                  _drawerItem(
                    icon: Icons.trending_up_rounded,
                    label: 'Movers',
                    selected: _index == 3,
                    onTap: () => _closeDrawerThen(() => _selectTab(3)),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Divider(height: 1, color: AppColor.divider),
                  ),
                  _drawerItem(
                    icon: Icons.support_agent_rounded,
                    label: 'Support Messages',
                    onTap: () => _closeDrawerThen(_openSupportMessages),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColor.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Profit From It Investor App',
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: AppColor.textSecondary,
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

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? AppColor.primary.withValues(alpha: .08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColor.primary.withValues(alpha: .12)
                      : const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? AppColor.primary : const Color(0xFF526176),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? AppColor.primary : AppColor.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: selected ? AppColor.primary : AppColor.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitDialog() async {
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Exit App',
          style: largeBold.copyWith(color: AppColor.black),
        ),
        content: Text(
          'Are you sure you want to exit the app?',
          style: medium.copyWith(color: AppColor.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: medium.copyWith(color: AppColor.black),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Exit', style: medium.copyWith(color: AppColor.black)),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }
}

class _NavDestination {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
