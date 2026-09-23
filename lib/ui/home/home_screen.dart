import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/model/dashboard_response.dart';
import 'package:profit_from_it_investors/provider/authentication/user_provider.dart';
import 'package:profit_from_it_investors/provider/client_switch/client_switch_provider.dart';
import 'package:profit_from_it_investors/provider/family/family_provider.dart';
import 'package:profit_from_it_investors/provider/home/home_provider.dart';
import 'package:profit_from_it_investors/ui/stock_detail_screen/stock_detail_screen.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/app_images.dart';
import 'package:profit_from_it_investors/utility/client_selection_bottom_sheet.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/family_selection_bottom_sheet.dart';
import 'package:profit_from_it_investors/ui/home/widgets/net_contribution_tile.dart';
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
    final dashboardData = homeProvider.dashboardData;

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

                          // Family selector always has priority.
                          // Switch User is visible only when there is no Family
                          // selector and the authenticated Client is readonly admin.
                          final showClientSwitch =
                              !hasFamily &&
                              dashboardData?.isReadonlyAdmin == 1 &&
                              dashboardData?.canSwitchClients == true &&
                              clientSwitchProvider.canShowSwitchUser;

                          return Container(
                            color: Colors.white,
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hello, ${name.isNotEmpty ? name : "User"}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.textPrimary,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        'Welcome back to Profit From It',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColor.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (hasFamily)
                                  InkWell(
                                    borderRadius: BorderRadius.circular(30),

                                    onTap: () {
                                      _showFamilySelection(context);
                                    },

                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),

                                      decoration: BoxDecoration(
                                        color: AppColor.primary.withValues(
                                          alpha: .08,
                                        ),

                                        borderRadius: BorderRadius.circular(25),

                                        border: Border.all(
                                          color: AppColor.primary.withValues(
                                            alpha: .15,
                                          ),
                                        ),
                                      ),

                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,

                                        children: [
                                          CircleAvatar(
                                            radius: 14,

                                            backgroundColor: AppColor.primary,

                                            child: Text(
                                              _getSafeInitial(
                                                familyProvider
                                                        .selectedFamily
                                                        ?.name ??
                                                    name,
                                              ),

                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 4),

                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 90,
                                            ),

                                            child: Text(
                                              "Family Members",

                                              maxLines: 1,

                                              overflow: TextOverflow.ellipsis,

                                              style: GoogleFonts.poppins(
                                                fontSize: 10,

                                                fontWeight: FontWeight.w600,

                                                color: AppColor.textPrimary,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 4),

                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,

                                            size: 20,

                                            color: AppColor.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                if (showClientSwitch)
                                  InkWell(
                                    borderRadius: BorderRadius.circular(30),
                                    onTap: () {
                                      _showClientSelection(context);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColor.primary.withValues(
                                          alpha: .08,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: AppColor.primary.withValues(
                                            alpha: .15,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: AppColor.primary,
                                            child: Text(
                                              _getSafeInitial(
                                                clientSwitchProvider
                                                        .selectedClient
                                                        ?.name ??
                                                    name,
                                              ),
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 90,
                                            ),
                                            child: Text(
                                              "Switch User",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppColor.textPrimary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 20,
                                            color: AppColor.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _PortfolioCard(),
                            const SizedBox(height: 16),
                            // realised / unrealised / dividend
                            Card(
                              color: AppColor.white,
                              elevation: 2,
                              child: Column(
                                children: [
                                  // realized
                                  Container(
                                    height: 56,
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColor.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color:
                                                      AmountUtils.isPositive(
                                                        homeProvider
                                                            .dashboardData
                                                            ?.realised,
                                                      )
                                                      ? AppColor.green
                                                            .withValues(
                                                              alpha: 0.12,
                                                            )
                                                      : AppColor.red.withValues(
                                                          alpha: 0.12,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Center(
                                                  child: Image.asset(
                                                    AmountUtils.isPositive(
                                                          homeProvider
                                                              .dashboardData
                                                              ?.realised,
                                                        )
                                                        ? AppImages.realised
                                                        : AppImages.unRealised,
                                                    color:
                                                        AmountUtils.isPositive(
                                                          homeProvider
                                                              .dashboardData
                                                              ?.realised,
                                                        )
                                                        ? AppColor.green
                                                        : AppColor.red,
                                                    width: 25,
                                                    height: 25,
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Realised P&L',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppColor
                                                                .textPrimary,
                                                          ),
                                                    ),

                                                    Text(
                                                      'Total booked profit / loss',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 10,
                                                            color: AppColor
                                                                .textSecondary,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 8),

                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 125,
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              homeProvider
                                                      .dashboardData
                                                      ?.realised ??
                                                  "-",
                                              maxLines: 1,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    AmountUtils.isPositive(
                                                      homeProvider
                                                          .dashboardData
                                                          ?.realised,
                                                    )
                                                    ? AppColor.green
                                                    : AppColor.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // un realized
                                  Divider(height: 0.3, color: AppColor.divider),
                                  Container(
                                    height: 56,
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColor.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color:
                                                      AmountUtils.isPositive(
                                                        homeProvider
                                                            .dashboardData
                                                            ?.unrealised,
                                                      )
                                                      ? AppColor.green
                                                            .withValues(
                                                              alpha: 0.12,
                                                            )
                                                      : AppColor.red.withValues(
                                                          alpha: 0.12,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Center(
                                                  child: Image.asset(
                                                    AmountUtils.isPositive(
                                                          homeProvider
                                                              .dashboardData
                                                              ?.unrealised,
                                                        )
                                                        ? AppImages.realised
                                                        : AppImages.unRealised,
                                                    color:
                                                        AmountUtils.isPositive(
                                                          homeProvider
                                                              .dashboardData
                                                              ?.unrealised,
                                                        )
                                                        ? AppColor.green
                                                        : AppColor.red,
                                                    width: 25,
                                                    height: 25,
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Un-Realised P&L',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppColor
                                                                .textPrimary,
                                                          ),
                                                    ),

                                                    Text(
                                                      'Current market profit / loss',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 10,
                                                            color: AppColor
                                                                .textSecondary,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 8),

                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 125,
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              homeProvider
                                                      .dashboardData
                                                      ?.unrealised ??
                                                  "-",
                                              maxLines: 1,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    AmountUtils.isPositive(
                                                      homeProvider
                                                          .dashboardData
                                                          ?.unrealised,
                                                    )
                                                    ? AppColor.green
                                                    : AppColor.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // dividend
                                  Divider(height: 0.3, color: AppColor.divider),

                                  Container(
                                    height: 56,
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColor.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: AppColor.primary
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Center(
                                                  child: Image.asset(
                                                    AppImages.dividend,
                                                    color: AppColor.primary,
                                                    width: 25,
                                                    height: 25,
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(width: 8),

                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Dividend Income',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppColor
                                                                .textPrimary,
                                                          ),
                                                    ),

                                                    Text(
                                                      'Total dividend earned',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 10,
                                                            color: AppColor
                                                                .textSecondary,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 8),

                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 125,
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              homeProvider
                                                      .dashboardData
                                                      ?.dividend ??
                                                  "-",
                                              maxLines: 1,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF082EAF),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  NetContributionTile(
                                    value:
                                        homeProvider
                                            .dashboardData
                                            ?.netContribution ??
                                        "₹0.00",
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // holding / Gainers / Losers
                            Card(
                              color: AppColor.white,
                              elevation: 2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      8,
                                      8,
                                      0,
                                    ),
                                    child: Text(
                                      'Portfolio Summary',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      // holdings
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          height: 56,
                                          padding: EdgeInsets.fromLTRB(
                                            8,
                                            8,
                                            8,
                                            8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColor.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(
                                                      color: AppColor.primary
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            50,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Image.asset(
                                                        AppImages.holdings,
                                                        color: AppColor.primary,
                                                        width: 20,
                                                        height: 20,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 6),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        homeProvider
                                                                .dashboardData
                                                                ?.totalHolding ??
                                                            "-",
                                                        textAlign:
                                                            TextAlign.left,
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: AppColor
                                                                  .textPrimary,
                                                            ),
                                                      ),
                                                      Text(
                                                        'Holdings',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 10,
                                                              color: AppColor
                                                                  .textSecondary,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // gainers
                                      Container(
                                        width: 1,
                                        height: 35, // Same as your item height
                                        color: Colors.grey.shade300,
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          height: 56,
                                          padding: EdgeInsets.fromLTRB(
                                            8,
                                            8,
                                            8,
                                            8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColor.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(
                                                      color: AppColor.green
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            50,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Image.asset(
                                                        AppImages.realised,
                                                        color: AppColor.green,
                                                        width: 20,
                                                        height: 20,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        homeProvider
                                                                .dashboardData
                                                                ?.totalGainer ??
                                                            "-",
                                                        textAlign:
                                                            TextAlign.left,
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: AppColor
                                                                  .textPrimary,
                                                            ),
                                                      ),
                                                      Text(
                                                        'Gainers',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 10,
                                                              color: AppColor
                                                                  .textSecondary,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // losers
                                      Container(
                                        width: 1,
                                        height: 35, // Same as your item height
                                        color: Colors.grey.shade300,
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          height: 56,
                                          padding: EdgeInsets.fromLTRB(
                                            8,
                                            8,
                                            8,
                                            8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColor.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(
                                                      color: AppColor.red
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            50,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Image.asset(
                                                        AppImages.unRealised,
                                                        color: AppColor.red,
                                                        width: 20,
                                                        height: 20,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        homeProvider
                                                                .dashboardData
                                                                ?.totalLoser ??
                                                            "-",
                                                        textAlign:
                                                            TextAlign.left,
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: AppColor
                                                                  .textPrimary,
                                                            ),
                                                      ),
                                                      Text(
                                                        'Losers',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 10,
                                                              color: AppColor
                                                                  .textSecondary,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Top Holdings',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.textPrimary,
                                  ),
                                ),
                                if (homeProvider.topHoldings.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      widget.onViewAllHoldings?.call();
                                    },
                                    child: Text(
                                      'View All',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppColor.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
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

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Transform.translate(
        offset: index == 0
            ? const Offset(14, 0)
            : index == total - 1
            ? const Offset(-10, 0)
            : Offset.zero,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
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

        return Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Portfolio",
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(width: 8),

                  if ((dashboard?.oldestVoucherDate ?? '').isNotEmpty)
                    Expanded(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 18,
                                    color: Colors.white,
                                  ),

                                  const SizedBox(width: 4),

                                  Text(
                                    "Inception Date :",
                                    maxLines: 1,
                                    softWrap: false,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              dashboard?.oldestVoucherDate ?? '',
                              maxLines: 1,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Portfolio Value + XIRR
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Portfolio Value",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            dashboard?.portfolioValue ?? "0",
                            maxLines: 1,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "XIRR",
                          maxLines: 1,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            "${dashboard?.xirr ?? 0}%",
                            maxLines: 1,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Today's Gain/Loss + Total Gain/Loss
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Gain/Loss",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "${dashboard?.todaysGainLoss ?? "0"} "
                            "(${(dashboard?.todaysGainLossPercentage ?? 0) >= 0 ? '+' : ''}"
                            "${(dashboard?.todaysGainLossPercentage ?? 0).toStringAsFixed(2)}%)",
                            maxLines: 1,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: (dashboard?.todaysGainLoss).toAmount() < 0
                                  ? Colors.red
                                  : const Color(0xFF69FF8C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Total Gain/Loss",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            dashboard?.totalGainLoss ?? "0",
                            maxLines: 1,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: (dashboard?.totalGainLoss).toAmount() < 0
                                  ? Colors.red
                                  : const Color(0xFF69FF8C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // NAV (Time-Weighted) / Absolute Value selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .18),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(7),
                        onTap: () {
                          if (_chartDisplayMode == 'nav') return;
                          setState(() {
                            _chartDisplayMode = 'nav';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: _chartDisplayMode == 'nav'
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "NAV (Time-Weighted)",
                              maxLines: 1,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _chartDisplayMode == 'nav'
                                    ? AppColor.primary
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(7),
                        onTap: () async {
                          if (_chartDisplayMode == 'absolute') return;

                          setState(() {
                            _chartDisplayMode = 'absolute';
                          });

                          // Absolute Value continues to use the existing
                          // portfolio-chart API for the selected period.
                          await provider.getPortfolioChart(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: _chartDisplayMode == 'absolute'
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Absolute Value",
                              maxLines: 1,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _chartDisplayMode == 'absolute'
                                    ? AppColor.primary
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: _periods.map((period) {
                  final selected = provider.chartType == period;

                  return GestureDetector(
                    onTap: () {
                      if (provider.chartType == period) return;

                      if (_isNavMode) {
                        // NAV history is already returned by Dashboard API.
                        // Only change the local period filter.
                        provider.updateChartTypeLocally(period);
                      } else {
                        // Absolute Value keeps using the existing API.
                        provider.updateChartType(context, period);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        period == 'MAX' ? 'ALL' : period,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColor.primary : Colors.white,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 220,
                child: (!_isNavMode && provider.portfolioChartLoading)
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
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
                                color: Colors.white12,
                                strokeWidth: 1,
                              );
                            },
                          ),
                          extraLinesData: ExtraLinesData(
                            horizontalLines: _isNavMode
                                ? [
                                    HorizontalLine(
                                      y: 100,
                                      color: Colors.white54,
                                      strokeWidth: 1,
                                      dashArray: [6, 4],
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

                                reservedSize: 32,

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
                                  // final amount = spot.y.toStringAsFixed(0);
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
                                  FlLine(color: Colors.white30, strokeWidth: 1),
                                  FlDotData(
                                    getDotPainter: (spot, percent, bar, index) {
                                      return FlDotCirclePainter(
                                        radius: 5,
                                        color: Colors.white,
                                        strokeWidth: 2,
                                        strokeColor: AppColor.primary,
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
                              curveSmoothness: .35,
                              color: Colors.white,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                checkToShowDot: (spot, barData) {
                                  return spot.x == 0 ||
                                      spot.x == spots.length - 1;
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: .35),
                                    Colors.white.withValues(alpha: .18),
                                    Colors.white.withValues(alpha: .05),
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

    final gainColor = isGain ? AppColor.gainText : AppColor.lossText;

    final todayPercent = holding.todaysPercentage ?? 0;

    final isTodayGain = todayPercent >= 0;

    final todayColor = isTodayGain ? AppColor.gainText : AppColor.lossText;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              /// Left Indicator
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: gainColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    bottomLeft: Radius.circular(25),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 6,
                    top: 8,
                    bottom: 8,
                  ),
                  child: Row(
                    children: [
                      /// Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: gainColor.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          getInitials(holding.assetName ?? ''),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: gainColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      /// Left Section
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              holding.assetName ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColor.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Today's Gain",
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColor.textSecondary,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if ((holding.todays ?? "").isNotEmpty)
                                  _gainChip(
                                    value: holding.todays!,
                                    color: todayColor,
                                  ),

                                if (holding.todaysPercentage != 0.0)
                                  _gainChip(
                                    value:
                                        "${todayPercent.toStringAsFixed(2)}%",
                                    color: todayColor,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        color: Colors.grey.shade300,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      const SizedBox(width: 8),

                      /// Right Values
                      SizedBox(
                        width: 65,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Invested",
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: AppColor.textSecondary,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              holding.investedValue ?? "",
                              style: GoogleFonts.poppins(
                                color: AppColor.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Current",
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                color: AppColor.textSecondary,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              holding.currentValue ?? "",
                              style: GoogleFonts.poppins(
                                color: AppColor.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      /// Percentage
                      SizedBox(
                        width: 48,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isGain
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              color: gainColor,
                              size: 20,
                            ),

                            Text(
                              "${gainPercent.abs().toStringAsFixed(2)}%",
                              style: GoogleFonts.poppins(
                                color: gainColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gainChip({required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
