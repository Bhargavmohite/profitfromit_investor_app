import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/provider/authentication/user_provider.dart';
import 'package:profit_from_it_investors/provider/client_switch/client_switch_provider.dart';
import 'package:profit_from_it_investors/model/holdings_detail_response.dart';
import 'package:profit_from_it_investors/provider/holdings/holdings_provider.dart';
import 'package:profit_from_it_investors/ui/holdings_screen/holding_sort_type.dart';
import 'package:profit_from_it_investors/ui/holdings_screen/holdings_sort_bottom_sheet.dart';
import 'package:profit_from_it_investors/ui/authentication/profile_screen/profile_screen.dart';
import 'package:profit_from_it_investors/ui/support_messages/support_messages_screen.dart';
import 'package:profit_from_it_investors/ui/stock_detail_screen/stock_detail_screen.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:provider/provider.dart';

class HoldingsScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  final VoidCallback? onOpenAnalytics;
  final VoidCallback? onOpenTaxometer;
  final VoidCallback? onOpenMovers;

  const HoldingsScreen({
    super.key,
    this.onGoHome,
    this.onOpenAnalytics,
    this.onOpenTaxometer,
    this.onOpenMovers,
  });

  @override
  State<HoldingsScreen> createState() => _HoldingsScreenState();
}

class _HoldingsScreenState extends State<HoldingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchText = '';

  HoldingSortType? _selectedSort;
  HoldingSortType? _tempSelectedSort;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HoldingsProvider>().getHoldings(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<HoldingsProvider>().getHoldings(isRefresh: true);
  }

  void _openMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Future<void> _openProfile() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  Future<void> _openSupportMessages() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SupportMessagesScreen()));
  }

  void _closeDrawerThen(VoidCallback action) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  void _returnToDashboard(VoidCallback? selectTab) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectTab?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColor.background,
      drawer: _buildDrawer(context),
      drawerScrimColor: const Color(0xFF0F172A).withValues(alpha: .34),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14, top: 6, bottom: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _openMenu,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDE4EF)),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.menu_rounded,
                color: AppColor.textPrimary,
                size: 23,
              ),
            ),
          ),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search holdings...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
              )
            : Text(
                'Holdings',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: AppColor.textPrimary,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchText = '';
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_alt_sharp, color: AppColor.textPrimary),
            onPressed: () => _showSortBottomSheet(context),
          ),
        ],
      ),
      body: Consumer<HoldingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.holdingsResponse == null) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Text(
                        "No data found",
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final holdings = provider.holdings;

          // ==============================================
          // SEARCH QUERY
          // ==============================================

          final searchQuery = _searchText.trim().toLowerCase();

          // ==============================================
          // ACTIVE HOLDINGS
          //
          // Only Qty > 0
          // Used for normal holdings display and count.
          // ==============================================

          final activeHoldings = holdings.where((holding) {
            return (holding.netQuantity ?? 0) > 0;
          }).toList();

          // ==============================================
          // DISPLAY LIST
          //
          // No Search:
          //      Show active holdings only.
          //
          // Search:
          //      Search ALL holdings,
          //      including qty 0 and negative.
          // ==============================================

          final List<Holding> filteredHoldings;

          if (searchQuery.isEmpty) {
            filteredHoldings = List<Holding>.from(activeHoldings);
          } else {
            filteredHoldings = holdings.where((holding) {
              final name = (holding.assetName ?? '').toLowerCase();

              return name.contains(searchQuery);
            }).toList();
          }

          _applySorting(filteredHoldings);

          return Column(
            children: [
              // Total Summary
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Holdings (${activeHoldings.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColor.textSecondary,
                      ),
                    ),
                    Text(
                      provider.totalInvested,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Holdings List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: filteredHoldings.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.55,
                              child: Center(
                                child: Text(
                                  'No holdings found',
                                  style: GoogleFonts.poppins(
                                    color: AppColor.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filteredHoldings.length,
                          itemBuilder: (_, index) {
                            final holding = filteredHoldings[index];

                            return _HoldingTile(
                              holding: holding,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StockDetailScreen(
                                      stockId: holding.id ?? '',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
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
                    onTap: () => _closeDrawerThen(
                      () => _returnToDashboard(widget.onGoHome),
                    ),
                  ),
                  _drawerItem(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Holdings',
                    selected: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _drawerItem(
                    icon: Icons.bar_chart_rounded,
                    label: 'Analytics',
                    onTap: () => _closeDrawerThen(
                      () => _returnToDashboard(widget.onOpenAnalytics),
                    ),
                  ),
                  _drawerItem(
                    icon: Icons.speed_rounded,
                    label: 'Taxometer',
                    onTap: () => _closeDrawerThen(
                      () => _returnToDashboard(widget.onOpenTaxometer),
                    ),
                  ),
                  _drawerItem(
                    icon: Icons.trending_up_rounded,
                    label: 'Movers',
                    onTap: () => _closeDrawerThen(
                      () => _returnToDashboard(widget.onOpenMovers),
                    ),
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

  void _showSortBottomSheet(BuildContext context) {
    _tempSelectedSort = _selectedSort;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return HoldingsSortBottomSheet(
          selectedSort: _selectedSort,
          onSelected: (sort) {
            _tempSelectedSort = sort;
          },
          onDone: () {
            setState(() {
              _selectedSort = _tempSelectedSort;
            });
          },
          onClear: () {
            setState(() {
              _selectedSort = null;
              _tempSelectedSort = null;
            });
          },
        );
      },
    );
  }

  void _applySorting(List<Holding> list) {
    switch (_selectedSort) {
      case HoldingSortType.alphabeticalAsc:
        list.sort(
          (a, b) => (a.assetName?.toLowerCase() ?? '').compareTo(
            b.assetName?.toLowerCase() ?? '',
          ),
        );
        break;

      case HoldingSortType.alphabeticalDesc:
        list.sort(
          (a, b) => (b.assetName?.toLowerCase() ?? '').compareTo(
            a.assetName?.toLowerCase() ?? '',
          ),
        );
        break;

      case HoldingSortType.percentHighToLow:
        // case HoldingSortType.profitPercentHighToLow:
        list.sort((a, b) => (b.gainPercent ?? 0).compareTo(a.gainPercent ?? 0));
        break;

      case HoldingSortType.percentLowToHigh:
        // case HoldingSortType.profitPercentLowToHigh:
        list.sort((a, b) => (a.gainPercent ?? 0).compareTo(b.gainPercent ?? 0));
        break;

      // case HoldingSortType.priceHighToLow:
      //   list.sort((a, b) => b.currentValue.toAmount().compareTo(a.currentValue.toAmount()));
      //   break;
      //
      // case HoldingSortType.priceLowToHigh:
      //   list.sort((a, b) => a.currentValue.toAmount().compareTo(b.currentValue.toAmount()));
      //   break;

      case HoldingSortType.profitHighToLow:
        list.sort((a, b) => _profit(b).compareTo(_profit(a)));
        break;

      case HoldingSortType.profitLowToHigh:
        list.sort((a, b) => _profit(a).compareTo(_profit(b)));
        break;

      case HoldingSortType.investedHighToLow:
        list.sort(
          (a, b) =>
              b.investedValue.toAmount().compareTo(a.investedValue.toAmount()),
        );
        break;

      case HoldingSortType.investedLowToHigh:
        list.sort(
          (a, b) =>
              a.investedValue.toAmount().compareTo(b.investedValue.toAmount()),
        );
        break;
      case null:
        break;
    }
  }

  double _profit(Holding holding) {
    debugPrint("A = ${holding.currentValue}");
    debugPrint("Parsed = ${holding.currentValue.toAmount()}");
    return holding.currentValue.toAmount() - holding.investedValue.toAmount();
  }
}

class _HoldingTile extends StatelessWidget {
  final Holding holding;
  final VoidCallback onTap;

  const _HoldingTile({required this.holding, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gainPercent = holding.gainPercent ?? 0;
    final isGain = gainPercent >= 0;
    final gainColor = isGain
        ? const Color(0xFF009B72)
        : const Color(0xFFE53935);

    final todayPercent = holding.todaysPercentage ?? 0;
    final isTodayGain = todayPercent >= 0;
    final todayColor = isTodayGain
        ? const Color(0xFF009B72)
        : const Color(0xFFE53935);

    final assetName = (holding.assetName ?? '').trim();
    final initials = getInitials(assetName);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6EBF2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .045),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company name + overall gain/loss percentage
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        initials,
                        maxLines: 1,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    assetName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                      height: 1.15,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: gainColor.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${isGain ? '+' : '-'}${gainPercent.abs().toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: gainColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        isGain
                            ? Icons.arrow_drop_up_rounded
                            : Icons.arrow_drop_down_rounded,
                        size: 14,
                        color: gainColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 9),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F6)),

            const SizedBox(height: 9),

            // Today's P&L / Invested / Current Value
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _valueColumn(
                    label: "Today's P&L",
                    value: (holding.todays ?? '').isNotEmpty
                        ? holding.todays!
                        : '-',
                    valueColor: todayColor,
                    subValue:
                        '${todayPercent >= 0 ? '+' : ''}${todayPercent.toStringAsFixed(2)}%',
                    subColor: todayColor,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: _valueColumn(
                    label: 'Invested',
                    value: (holding.investedValue ?? '').isNotEmpty
                        ? holding.investedValue!
                        : '-',
                    valueColor: AppColor.textPrimary,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: _valueColumn(
                    label: 'Current Value',
                    value: (holding.currentValue ?? '').isNotEmpty
                        ? holding.currentValue!
                        : '-',
                    valueColor: AppColor.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _valueColumn({
    required String label,
    required String value,
    required Color valueColor,
    String? subValue,
    Color? subColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 7.5,
            fontWeight: FontWeight.w500,
            color: AppColor.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
        if ((subValue ?? '').isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(
            subValue!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 7.5,
              fontWeight: FontWeight.w500,
              color: subColor ?? AppColor.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
