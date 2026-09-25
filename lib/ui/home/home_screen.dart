import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/model/dashboard_response.dart';
import 'package:profit_from_it_investors/provider/authentication/user_provider.dart';
import 'package:profit_from_it_investors/provider/client_switch/client_switch_provider.dart';
import 'package:profit_from_it_investors/provider/family/family_provider.dart';
import 'package:profit_from_it_investors/provider/home/home_provider.dart';
import 'package:profit_from_it_investors/provider/holdings/holdings_provider.dart';
import 'package:profit_from_it_investors/ui/stock_detail_screen/stock_detail_screen.dart';
import 'package:profit_from_it_investors/ui/net_contribution/net_contribution_screen.dart';
import 'package:profit_from_it_investors/ui/dividend/dividend_screen.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/client_selection_bottom_sheet.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/family_selection_bottom_sheet.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onViewAllHoldings;

  const HomeScreen({super.key, this.onViewAllHoldings});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _getSafeInitial(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) {
      return '?';
    }

    return text[0].toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeProvider = context.read<HomeProvider>();

      await homeProvider.getDashboard(context);

      if (mounted) {
        await homeProvider.getPortfolioChart(context);
      }

      if (mounted) {
        // Load the complete holdings list so Home-screen Gainers/Losers
        // are calculated only from active holdings (net_quantity > 0).
        await context.read<HoldingsProvider>().getHoldings();
      }

      if (mounted) {
        final familyProvider = context.read<FamilyProvider>();
        // await familyProvider.setFamilyList(homeProvider.dashboardData?.familyList ?? []);
        familyProvider.setFamilyList(
          homeProvider.dashboardData?.familyList ?? [],
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final holdingsProvider = context.watch<HoldingsProvider>();
    final dashboardData = homeProvider.dashboardData;

    // HOME SUMMARY COUNT RULE:
    // 1) Ignore holdings where net_quantity <= 0.
    // 2) Gainer = active holding with gain_percent > 0.
    // 3) Loser  = active holding with gain_percent < 0.
    // 4) gain_percent == 0 is counted in neither group.
    final activeHoldings = holdingsProvider.holdings
        .where((holding) => (holding.netQuantity ?? 0) > 0)
        .toList();

    final activeGainers = activeHoldings
        .where((holding) => (holding.gainPercent ?? 0) > 0)
        .length;

    final activeLosers = activeHoldings
        .where((holding) => (holding.gainPercent ?? 0) < 0)
        .length;

    final hasHoldingsData = holdingsProvider.holdingsResponse != null;

    return Scaffold(
      backgroundColor: AppColor.background,
      body: homeProvider.dashboardLoading /*&& dashboardData == null*/
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Consumer3<UserProvider, FamilyProvider, ClientSwitchProvider>(
                    builder:
                        (
                          context,
                          userProvider,
                          familyProvider,
                          clientSwitchProvider,
                          _,
                        ) {
                          final name = dashboardData?.name ?? userProvider.name;

                          // Family selector rule:
                          // - Master (is_family_master = 1) + family_id => SHOW
                          // - Non-master / no family_id => HIDE
                          //
                          // Do not depend on family_list length here. The family
                          // list is loaded by the dashboard API and displayed in
                          // the bottom sheet after the selector is opened.
                          final hasFamily =
                              dashboardData?.familyId != null &&
                              (dashboardData?.isFamilyMaster == 1 ||
                                  dashboardData?.canSelectFamily == true);

                          // Family selector keeps its existing priority.
                          //
                          // Supported client-switch modes:
                          //
                          // 1) Readonly Admin Client
                          //    ctype = Client + is_readonly_admin = 1
                          //    -> show "Switch User"
                          //
                          // 2) Partner
                          //    ctype = Partner
                          //    -> show "Switch Member"
                          //
                          // 3) Normal Client
                          //    -> no switching option
                          final accountCtype = (dashboardData?.ctype ?? '')
                              .trim()
                              .toLowerCase();

                          final isPartner = accountCtype == 'partner';

                          final isReadonlyAdminClient =
                              accountCtype == 'client' &&
                              dashboardData?.isReadonlyAdmin == 1;

                          // Switching permissions are independent from Family
                          // Master permission. If an account is both Family
                          // Master and Partner/Readonly Admin, show BOTH controls.
                          final showPartnerSwitch =
                              isPartner &&
                              dashboardData?.canSwitchClients == true &&
                              clientSwitchProvider.canShowSwitchMember;

                          final showReadonlyAdminSwitch =
                              isReadonlyAdminClient &&
                              dashboardData?.canSwitchClients == true &&
                              clientSwitchProvider.canShowSwitchUser;

                          final showClientSwitch =
                              showPartnerSwitch || showReadonlyAdminSwitch;

                          final clientSwitchLabel = showPartnerSwitch
                              ? 'Switch Member'
                              : 'Switch User';

                          // Time-based greeting using device local time.
                          final currentHour = DateTime.now().hour;

                          final String greeting;
                          if (currentHour >= 6 && currentHour < 12) {
                            greeting = 'Good Morning';
                          } else if (currentHour >= 12 && currentHour < 17) {
                            greeting = 'Good Afternoon';
                          } else if (currentHour >= 17 && currentHour < 19) {
                            greeting = 'Good Evening';
                          } else {
                            greeting = 'Hello';
                          }

                          return Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFFF0F2F6),
                                  width: 1,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$greeting, ${name.isNotEmpty ? name : "User"}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.textPrimary,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Welcome to Profit From It',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColor.textSecondary,
                                  ),
                                ),

                                if (hasFamily || showClientSwitch) ...[
                                  const SizedBox(height: 14),

                                  // Family and client switching stay on one line.
                                  Row(
                                    children: [
                                      if (hasFamily)
                                        Expanded(
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () {
                                              _showFamilySelection(context);
                                            },
                                            child: Container(
                                              height: 46,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 9,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF6F8FC),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFDDE4EF,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 28,
                                                    height: 28,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Color(
                                                            0xFF0D4CC9,
                                                          ),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      _getSafeInitial(
                                                        familyProvider
                                                                .selectedFamily
                                                                ?.name ??
                                                            name,
                                                      ),
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 7),
                                                  Expanded(
                                                    child: Text(
                                                      'Family Members',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 10.5,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppColor
                                                                .textPrimary,
                                                          ),
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons
                                                        .keyboard_arrow_down_rounded,
                                                    size: 18,
                                                    color: Color(0xFF66758B),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                      if (hasFamily && showClientSwitch)
                                        const SizedBox(width: 8),

                                      if (showClientSwitch)
                                        Expanded(
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () {
                                              _showClientSelection(context);
                                            },
                                            child: Container(
                                              height: 46,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 9,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF6F8FC),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFDDE4EF,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 28,
                                                    height: 28,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Color(
                                                            0xFF082D59,
                                                          ),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      _getSafeInitial(
                                                        clientSwitchProvider
                                                                .selectedClient
                                                                ?.name ??
                                                            name,
                                                      ),
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 7),
                                                  Expanded(
                                                    child: Text(
                                                      clientSwitchLabel,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 10.5,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppColor
                                                                .textPrimary,
                                                          ),
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons
                                                        .keyboard_arrow_down_rounded,
                                                    size: 18,
                                                    color: Color(0xFF66758B),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                  ),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await homeProvider.refreshDashboard(
                          context,
                          isRefresh: true,
                        );
                        if (context.mounted) {
                          await context.read<HoldingsProvider>().getHoldings(
                            isRefresh: true,
                          );
                        }
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PortfolioCard(),
                            const SizedBox(height: 16),
                            // ================================
                            // BELOW-CHART PORTFOLIO SUMMARY ONLY
                            // ================================

                            // Row 1: Realised / Un-Realised
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 120,
                                    ),
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      color:
                                          AmountUtils.isPositive(
                                            homeProvider
                                                .dashboardData
                                                ?.realised,
                                          )
                                          ? const Color(0xFFEFFFF8)
                                          : const Color(0xFFFFF1F1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            AmountUtils.isPositive(
                                              homeProvider
                                                  .dashboardData
                                                  ?.realised,
                                            )
                                            ? const Color(0xFFA7EBCF)
                                            : const Color(0xFFFFC5C5),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color:
                                                AmountUtils.isPositive(
                                                  homeProvider
                                                      .dashboardData
                                                      ?.realised,
                                                )
                                                ? const Color(
                                                    0xFF009B72,
                                                  ).withValues(alpha: .10)
                                                : const Color(
                                                    0xFFE53935,
                                                  ).withValues(alpha: .10),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Icon(
                                            AmountUtils.isPositive(
                                                  homeProvider
                                                      .dashboardData
                                                      ?.realised,
                                                )
                                                ? Icons.trending_up_rounded
                                                : Icons.trending_down_rounded,
                                            size: 18,
                                            color:
                                                AmountUtils.isPositive(
                                                  homeProvider
                                                      .dashboardData
                                                      ?.realised,
                                                )
                                                ? const Color(0xFF009B72)
                                                : const Color(0xFFE53935),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Realised P&L',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: AppColor.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            homeProvider
                                                    .dashboardData
                                                    ?.realised ??
                                                '-',
                                            maxLines: 1,
                                            style: GoogleFonts.poppins(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  AmountUtils.isPositive(
                                                    homeProvider
                                                        .dashboardData
                                                        ?.realised,
                                                  )
                                                  ? const Color(0xFF009B72)
                                                  : const Color(0xFFE53935),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Booked profit / loss',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            color: AppColor.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 120,
                                    ),
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      color:
                                          AmountUtils.isPositive(
                                            homeProvider
                                                .dashboardData
                                                ?.unrealised,
                                          )
                                          ? const Color(0xFFEFFFF8)
                                          : const Color(0xFFFFF1F1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            AmountUtils.isPositive(
                                              homeProvider
                                                  .dashboardData
                                                  ?.unrealised,
                                            )
                                            ? const Color(0xFFA7EBCF)
                                            : const Color(0xFFFFC5C5),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color:
                                                AmountUtils.isPositive(
                                                  homeProvider
                                                      .dashboardData
                                                      ?.unrealised,
                                                )
                                                ? const Color(
                                                    0xFF009B72,
                                                  ).withValues(alpha: .10)
                                                : const Color(
                                                    0xFFE53935,
                                                  ).withValues(alpha: .10),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Icon(
                                            AmountUtils.isPositive(
                                                  homeProvider
                                                      .dashboardData
                                                      ?.unrealised,
                                                )
                                                ? Icons.trending_up_rounded
                                                : Icons.trending_down_rounded,
                                            size: 18,
                                            color:
                                                AmountUtils.isPositive(
                                                  homeProvider
                                                      .dashboardData
                                                      ?.unrealised,
                                                )
                                                ? const Color(0xFF009B72)
                                                : const Color(0xFFE53935),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Un-Realised P&L',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: AppColor.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            homeProvider
                                                    .dashboardData
                                                    ?.unrealised ??
                                                '-',
                                            maxLines: 1,
                                            style: GoogleFonts.poppins(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  AmountUtils.isPositive(
                                                    homeProvider
                                                        .dashboardData
                                                        ?.unrealised,
                                                  )
                                                  ? const Color(0xFF009B72)
                                                  : const Color(0xFFE53935),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Current market profit / loss',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            color: AppColor.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Row 2: Dividend / Net Contribution
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const DividendScreen(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minHeight: 120,
                                      ),
                                      padding: const EdgeInsets.all(13),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF9E8),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFFFD98A),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFB66A00,
                                              ).withValues(alpha: .10),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.currency_rupee_rounded,
                                              size: 18,
                                              color: Color(0xFFB66A00),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Dividend Income',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: AppColor.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              homeProvider
                                                      .dashboardData
                                                      ?.dividend ??
                                                  '-',
                                              maxLines: 1,
                                              style: GoogleFonts.poppins(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF9C5200),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Dividend received',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 9,
                                                    color:
                                                        AppColor.textSecondary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 10,
                                                color: Color(0xFF9C5200),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const NetContributionScreen(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minHeight: 120,
                                      ),
                                      padding: const EdgeInsets.all(13),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F6FF),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFBDD6FF),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: AppColor.primary
                                                  .withValues(alpha: .10),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons
                                                  .account_balance_wallet_outlined,
                                              size: 18,
                                              color: AppColor.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Net Contribution',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: AppColor.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              homeProvider
                                                      .dashboardData
                                                      ?.netContribution ??
                                                  '-',
                                              maxLines: 1,
                                              style: GoogleFonts.poppins(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: AppColor.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Net capital contribution',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 9,
                                                    color:
                                                        AppColor.textSecondary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: 10,
                                                color: AppColor.primary,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Holdings / Gainers / Losers strip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: AppColor.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: .06),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .04),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF244A7C,
                                            ).withValues(alpha: .08),
                                            borderRadius: BorderRadius.circular(
                                              9,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.layers_outlined,
                                            size: 17,
                                            color: Color(0xFF244A7C),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          homeProvider
                                                  .dashboardData
                                                  ?.totalHolding ??
                                              '-',
                                          maxLines: 1,
                                          style: GoogleFonts.poppins(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: AppColor.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Holdings',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF244A7C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 50,
                                    color: Colors.black.withValues(alpha: .06),
                                  ),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF009B72,
                                            ).withValues(alpha: .08),
                                            borderRadius: BorderRadius.circular(
                                              9,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.trending_up_rounded,
                                            size: 17,
                                            color: Color(0xFF009B72),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          hasHoldingsData
                                              ? activeGainers.toString()
                                              : (homeProvider
                                                        .dashboardData
                                                        ?.totalGainer ??
                                                    '-'),
                                          maxLines: 1,
                                          style: GoogleFonts.poppins(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: AppColor.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Gainers',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF009B72),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 50,
                                    color: Colors.black.withValues(alpha: .06),
                                  ),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFE53935,
                                            ).withValues(alpha: .08),
                                            borderRadius: BorderRadius.circular(
                                              9,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.trending_down_rounded,
                                            size: 17,
                                            color: Color(0xFFE53935),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          hasHoldingsData
                                              ? activeLosers.toString()
                                              : (homeProvider
                                                        .dashboardData
                                                        ?.totalLoser ??
                                                    '-'),
                                          maxLines: 1,
                                          style: GoogleFonts.poppins(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: AppColor.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Losers',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFFE53935),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Top Holdings',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColor.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'By Current Value',
                                    style: GoogleFonts.poppins(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w500,
                                      color: AppColor.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (homeProvider.topHoldings.isNotEmpty)
                                    InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () {
                                        widget.onViewAllHoldings?.call();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColor.primary.withValues(
                                            alpha: .07,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'View All (${homeProvider.dashboardData?.totalHolding ?? homeProvider.topHoldings.length})',
                                              style: GoogleFonts.poppins(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color: AppColor.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 13,
                                              color: AppColor.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            if (homeProvider.topHoldings.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    "No holdings available",
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              ),

                            ...homeProvider.topHoldings.map(
                              (stock) => _HoldingTile(
                                holding: stock,
                                onTap: () {
                                  nextRoute(
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return StockDetailScreen(
                                          stockId: stock.id.toString(),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _showFamilySelection(BuildContext context) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const FamilySelectionBottomSheet(),
    );

    if (changed == true && context.mounted) {
      await context.read<HomeProvider>().refreshDashboard(
        context,
        isRefresh: false,
      );
      if (context.mounted) {
        await context.read<HoldingsProvider>().getHoldings(isRefresh: true);
      }
    }
  }

  Future<void> _showClientSelection(BuildContext context) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ClientSelectionBottomSheet(),
    );

    if (changed == true && context.mounted) {
      await context.read<HomeProvider>().refreshDashboard(
        context,
        isRefresh: false,
      );
      if (context.mounted) {
        await context.read<HoldingsProvider>().getHoldings(isRefresh: true);
      }
    }
  }
}

class _PortfolioCard extends StatefulWidget {
  const _PortfolioCard();

  @override
  State<_PortfolioCard> createState() => _PortfolioCardState();
}

class _PortfolioCardState extends State<_PortfolioCard> {
  static const List<String> _periods = ['1M', '3M', '1Y', 'MAX'];

  // Chart display selector.
  // NAV is shown by default. Absolute Value keeps using the existing chart API.
  String _chartDisplayMode = 'nav';

  bool get _isNavMode => _chartDisplayMode == 'nav';

  List<int> _getFilteredNavIndexes(HomeProvider provider) {
    final curve = provider.dashboardData?.portfolioCurve;

    if (curve == null || curve.dates.isEmpty || curve.navValues.isEmpty) {
      return [];
    }

    final length = curve.dates.length < curve.navValues.length
        ? curve.dates.length
        : curve.navValues.length;

    final parsedDates = <DateTime>[];
    final originalIndexes = <int>[];

    for (var i = 0; i < length; i++) {
      final date = DateTime.tryParse(curve.dates[i]);
      if (date == null) continue;

      parsedDates.add(date);
      originalIndexes.add(i);
    }

    if (parsedDates.isEmpty) {
      return [];
    }

    if (provider.chartType == 'MAX') {
      return originalIndexes;
    }

    final lastDate = parsedDates.last;
    DateTime cutoff;

    switch (provider.chartType) {
      case '1M':
        cutoff = DateTime(lastDate.year, lastDate.month - 1, lastDate.day);
        break;
      case '3M':
        cutoff = DateTime(lastDate.year, lastDate.month - 3, lastDate.day);
        break;
      case '1Y':
        cutoff = DateTime(lastDate.year - 1, lastDate.month, lastDate.day);
        break;
      default:
        return originalIndexes;
    }

    final filtered = <int>[];

    for (var i = 0; i < parsedDates.length; i++) {
      if (!parsedDates[i].isBefore(cutoff)) {
        filtered.add(originalIndexes[i]);
      }
    }

    return filtered;
  }

  List<double> _getChartValues(HomeProvider provider) {
    if (_isNavMode) {
      final curve = provider.dashboardData?.portfolioCurve;
      if (curve == null) return [];

      final indexes = _getFilteredNavIndexes(provider);

      return indexes
          .where((index) => index >= 0 && index < curve.navValues.length)
          .map((index) => curve.navValues[index])
          .toList();
    }

    return provider.portfolioChartResponse?.data?.chart?.portfolioValues ?? [];
  }

  List<FlSpot> _getChartSpots(HomeProvider provider) {
    final values = _getChartValues(provider);

    if (values.isEmpty) {
      return [];
    }

    return List.generate(
      values.length,
      (index) => FlSpot(index.toDouble(), values[index]),
    );
  }

  List<DateTime> _getDates(HomeProvider provider) {
    if (_isNavMode) {
      final curve = provider.dashboardData?.portfolioCurve;
      if (curve == null) return [];

      final indexes = _getFilteredNavIndexes(provider);
      final dates = <DateTime>[];

      for (final index in indexes) {
        if (index < 0 || index >= curve.dates.length) continue;

        final date = DateTime.tryParse(curve.dates[index]);
        if (date != null) {
          dates.add(date);
        }
      }

      return dates;
    }

    return provider.portfolioChartResponse?.data?.chart?.dates ?? [];
  }

  double _getMinY(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;

    double min = spots.first.y;

    for (final spot in spots) {
      if (spot.y < min) {
        min = spot.y;
      }
    }

    // In NAV mode always keep the Base-100 reference inside the visible range.
    if (_isNavMode && min > 100) {
      min = 100;
    }

    final padding = (min * .05).abs();

    return min - padding;
  }

  double _getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;

    double max = spots.first.y;

    for (final spot in spots) {
      if (spot.y > max) {
        max = spot.y;
      }
    }

    // In NAV mode always keep the Base-100 reference inside the visible range.
    if (_isNavMode && max < 100) {
      max = 100;
    }

    final padding = (max * .05).abs();

    return max + padding;
  }

  String _formatAmount(double value) {
    final absValue = value.abs();

    if (absValue >= 10000000) {
      final amount = value / 10000000;

      return amount == amount.roundToDouble()
          ? "${amount.toStringAsFixed(0)}Cr"
          : "${amount.toStringAsFixed(1)}Cr";
    }

    if (absValue >= 100000) {
      final amount = value / 100000;

      return amount == amount.roundToDouble()
          ? "${amount.toStringAsFixed(0)}L"
          : "${amount.toStringAsFixed(1)}L";
    }

    if (absValue >= 1000) {
      final amount = value / 1000;

      return amount == amount.roundToDouble()
          ? "${amount.toStringAsFixed(0)}K"
          : "${amount.toStringAsFixed(1)}K";
    }

    return value.toStringAsFixed(0);
  }

  Widget _leftTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      space: 0,
      child: SizedBox(
        width: 30,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            _isNavMode ? value.toStringAsFixed(0) : _formatAmount(value),
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomTitles(double value, TitleMeta meta, HomeProvider provider) {
    final dates = _getDates(provider);

    final index = value.toInt();

    if (index >= dates.length || index < 0) {
      return const SizedBox();
    }

    final total = dates.length;

    bool show = false;

    switch (provider.chartType) {
      case '1M':
        show = index == 0 || index == total ~/ 2 || index == total - 1;
        break;

      case '3M':
        show =
            index == 0 ||
            index == total ~/ 3 ||
            index == (total * 2) ~/ 3 ||
            index == total - 1;
        break;

      case '1Y':
        show =
            index == 0 ||
            index == total ~/ 4 ||
            index == total ~/ 2 ||
            index == (total * 3) ~/ 4 ||
            index == total - 1;
        break;

      default:
        // MAX / ALL: keep the axis readable even when NAV has daily points.
        show =
            index == 0 ||
            index == total ~/ 4 ||
            index == total ~/ 2 ||
            index == (total * 3) ~/ 4 ||
            index == total - 1;
    }

    if (!show) {
      return const SizedBox();
    }

    final date = dates[index];

    String text;

    switch (provider.chartType) {
      case '1M':
        text = "${date.day} ${_month(date.month)}";
        break;

      case '3M':
        text = "${date.day} ${_month(date.month)}";
        break;

      case '1Y':
        text = _month(date.month);
        break;

      default:
        text = "${_month(date.month)} ${date.year}";
    }

    final isLatestPoint = index == total - 1;
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    if (isLatestPoint && isToday) {
      text = "$text (Today)";
    }

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Transform.translate(
        offset: index == 0
            ? const Offset(12, 0)
            : index == total - 1
            ? const Offset(-14, 0)
            : Offset.zero,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: GoogleFonts.poppins(
            color: isLatestPoint
                ? const Color(0xFF55F2B0)
                : const Color(0xFFAAC0D6),
            fontSize: 9.5,
            fontWeight: isLatestPoint ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _month(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  String _formatInceptionDate(String? rawDate) {
    final value = (rawDate ?? '').trim();

    if (value.isEmpty) {
      return '';
    }

    final parts = value.split('-');

    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day != null &&
          month != null &&
          month >= 1 &&
          month <= 12 &&
          year != null) {
        return "$day ${_month(month)} $year";
      }
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final dashboard = provider.dashboardData;
        final spots = _getChartSpots(provider);
        final dates = _getDates(provider);

        if (spots.isEmpty) {
          return Container(
            height: 220,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D3CCF), Color(0xFF082EAF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColor.primary.withValues(alpha: .35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                "No chart data available",
                style: GoogleFonts.poppins(color: AppColor.white, fontSize: 14),
              ),
            ),
          );
        }

        final interval = ((_getMaxY(spots) - _getMinY(spots)) / 4).abs();

        const mint = Color(0xFF55F2B0);
        const lossRed = Color(0xFFFF5C64);
        const cardTop = Color(0xFF071D3E);
        const cardBottom = Color(0xFF123C8E);
        const softText = Color(0xFFAAC0D6);

        final todayAmount = dashboard?.todaysGainLoss ?? "0";
        final totalAmount = dashboard?.totalGainLoss ?? "0";
        final isTodayGain = todayAmount.toAmount() >= 0;
        final isTotalGain = totalAmount.toAmount() >= 0;
        final inceptionDate = _formatInceptionDate(
          dashboard?.oldestVoucherDate,
        );

        Widget gainPanel({
          required String title,
          required String amount,
          required bool isGain,
          String? percentage,
        }) {
          final valueColor = isGain ? mint : lossRed;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .075),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: .12),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: softText,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      isGain
                          ? Icons.arrow_drop_up_rounded
                          : Icons.arrow_drop_down_rounded,
                      size: 18,
                      color: valueColor,
                    ),
                    const SizedBox(width: 1),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          amount,
                          maxLines: 1,
                          style: GoogleFonts.poppins(
                            color: valueColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if ((percentage ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 19),
                    child: Text(
                      percentage!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: valueColor.withValues(alpha: .92),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        Widget chartModeButton({required String value, required String label}) {
          final selected = _chartDisplayMode == value;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                if (selected) return;

                setState(() {
                  _chartDisplayMode = value;
                });

                if (value == 'absolute') {
                  await provider.getPortfolioChart(context);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      color: selected ? const Color(0xFF1745C8) : softText,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [cardTop, cardBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: .08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF071D3E).withValues(alpha: .28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact header, inspired by the supplied reference.
              Row(
                children: [
                  Text(
                    "PORTFOLIO VALUE",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFD6E4F1),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .35,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: Color(0xFFAAC0D6),
                  ),
                  const Spacer(),
                  if (inceptionDate.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .095),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 12,
                            color: softText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Since $inceptionDate",
                            style: GoogleFonts.poppins(
                              color: softText,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // Portfolio value + XIRR chip.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        dashboard?.portfolioValue ?? "₹0",
                        maxLines: 1,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: mint.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: mint.withValues(alpha: .30)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up_rounded,
                          size: 15,
                          color: mint,
                        ),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "XIRR",
                              style: GoogleFonts.poppins(
                                color: mint,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${dashboard?.xirr ?? 0}%",
                              style: GoogleFonts.poppins(
                                color: mint,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Today's Gain/Loss and Total Gain/Loss are intentionally
              // placed directly above the chart-mode toggle.
              Row(
                children: [
                  Expanded(
                    child: gainPanel(
                      title: "Today's Gain/Loss",
                      amount: todayAmount,
                      isGain: isTodayGain,
                      percentage:
                          "${(dashboard?.todaysGainLossPercentage ?? 0) >= 0 ? '+' : ''}"
                          "${(dashboard?.todaysGainLossPercentage ?? 0).toStringAsFixed(2)}%",
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: gainPanel(
                      title: "Total Gain/Loss",
                      amount: totalAmount,
                      isGain: isTotalGain,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // NAV / Absolute Value toggle from the supplied reference.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0F6).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .08),
                  ),
                ),
                child: Row(
                  children: [
                    chartModeButton(value: 'nav', label: "NAV (Time-Weighted)"),
                    const SizedBox(width: 3),
                    chartModeButton(value: 'absolute', label: "Absolute Value"),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Performance track + compact period selector.
              Row(
                children: [
                  Text(
                    "Performance Track",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFD6E4F1),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _periods.map((period) {
                        final selected = provider.chartType == period;

                        return GestureDetector(
                          onTap: () {
                            if (selected) return;

                            if (_isNavMode) {
                              provider.updateChartTypeLocally(period);
                            } else {
                              provider.updateChartType(context, period);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              period,
                              style: GoogleFonts.poppins(
                                color: selected
                                    ? const Color(0xFF1745C8)
                                    : softText,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Existing real chart data/behavior retained; only visual styling
              // is updated to match the dark navy + mint reference.
              SizedBox(
                height: 205,
                child: (!_isNavMode && provider.portfolioChartLoading)
                    ? const Center(
                        child: CircularProgressIndicator(color: mint),
                      )
                    : LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: (spots.length - 1).toDouble(),
                          minY: _getMinY(spots),
                          maxY: _getMaxY(spots),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: interval == 0 ? 1 : interval,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.white.withValues(alpha: .10),
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              );
                            },
                          ),
                          extraLinesData: ExtraLinesData(
                            horizontalLines: _isNavMode
                                ? [
                                    HorizontalLine(
                                      y: 100,
                                      color: softText.withValues(alpha: .45),
                                      strokeWidth: 1,
                                      dashArray: [5, 5],
                                    ),
                                  ]
                                : const [],
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 34,
                                interval: interval == 0 ? 1 : interval,
                                minIncluded: false,
                                getTitlesWidget: _leftTitles,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) =>
                                    _bottomTitles(value, meta, provider),
                              ),
                            ),
                          ),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            handleBuiltInTouches: true,
                            touchTooltipData: LineTouchTooltipData(
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              getTooltipItems: (spots) {
                                return spots.map((spot) {
                                  final index = spot.x.toInt();

                                  if (index >= dates.length) {
                                    return LineTooltipItem(
                                      _isNavMode
                                          ? "NAV: ${spot.y.toStringAsFixed(2)}"
                                          : "₹${spot.y.toStringAsFixed(0)}",
                                      GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  }

                                  final date = dates[index];

                                  return LineTooltipItem(
                                    "${date.day} ${_month(date.month)} ${date.year}\n"
                                    "${_isNavMode ? 'NAV: ${spot.y.toStringAsFixed(2)}' : '₹${spot.y.toStringAsFixed(0)}'}",
                                    GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                            getTouchedSpotIndicator: (barData, indexes) {
                              return indexes.map((index) {
                                return TouchedSpotIndicatorData(
                                  FlLine(
                                    color: mint.withValues(alpha: .25),
                                    strokeWidth: 1,
                                  ),
                                  FlDotData(
                                    getDotPainter: (spot, percent, bar, index) {
                                      return FlDotCirclePainter(
                                        radius: 5,
                                        color: Colors.white,
                                        strokeWidth: 2,
                                        strokeColor: mint,
                                      );
                                    },
                                  ),
                                );
                              }).toList();
                            },
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              curveSmoothness: .32,
                              color: mint,
                              barWidth: 2.6,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                checkToShowDot: (spot, barData) {
                                  return spot.x == spots.length - 1;
                                },
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: Colors.white,
                                    strokeWidth: 2,
                                    strokeColor: mint,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    mint.withValues(alpha: .22),
                                    mint.withValues(alpha: .08),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HoldingTile extends StatelessWidget {
  final TopHolding holding;
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
        margin: const EdgeInsets.only(bottom: 10),
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
            // Company name + total gain percentage
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

            Divider(height: 1, thickness: 1, color: const Color(0xFFF0F2F6)),

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
