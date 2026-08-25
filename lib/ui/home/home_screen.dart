import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/model/dashboard_response.dart';
import 'package:profit_from_it_investors/provider/authentication/user_provider.dart';
import 'package:profit_from_it_investors/provider/family/family_provider.dart';
import 'package:profit_from_it_investors/provider/home/home_provider.dart';
import 'package:profit_from_it_investors/ui/stock_detail_screen/stock_detail_screen.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/app_images.dart';
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
        familyProvider.setFamilyList(homeProvider.dashboardData?.familyList ?? []);
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
                  Consumer2<UserProvider, FamilyProvider>(
                    builder: (context, userProvider, familyProvider, _) {
                      final name = dashboardData?.name ?? userProvider.name;

                      return Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello, ${name.isNotEmpty ? name : "User"}',
                                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                                  ),

                                  const SizedBox(height: 4),

                                  Text('Welcome back to Profit From It', style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),
                                ],
                              ),
                            ),

                            InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                _showFamilySelection(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColor.primary.withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: AppColor.primary.withValues(alpha: .15)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppColor.primary,
                                      child: Text((familyProvider.selectedFamily?.name ?? name).substring(0, 1).toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                                    ),

                                    const SizedBox(width: 4),

                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 90),
                                      child: Text(
                                        "Family Members",
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                                      ),
                                    ),

                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColor.primary),
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
                        await homeProvider.refreshDashboard(context, isRefresh: true);
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
                                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                                    decoration: BoxDecoration(color: AppColor.white, borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(color: AmountUtils.isPositive(homeProvider.dashboardData?.realised) ? AppColor.green.withValues(alpha: 0.12) : AppColor.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                              child: Center(
                                                child: Image.asset(AmountUtils.isPositive(homeProvider.dashboardData?.realised) ? AppImages.realised : AppImages.unRealised, color: AmountUtils.isPositive(homeProvider.dashboardData?.realised) ? AppColor.green : AppColor.red, width: 25, height: 25),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Realised P&L',
                                                  textAlign: TextAlign.left,
                                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                                                ),
                                                Text('Total booked profit / loss', style: GoogleFonts.poppins(fontSize: 10, color: AppColor.textSecondary)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Text(
                                          homeProvider.dashboardData?.realised ?? "-",
                                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AmountUtils.isPositive(homeProvider.dashboardData?.realised) ? AppColor.green : AppColor.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // un realized
                                  Divider(height: 0.3, color: AppColor.divider),
                                  Container(
                                    height: 56,
                                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                                    decoration: BoxDecoration(color: AppColor.white, borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(color: AmountUtils.isPositive(homeProvider.dashboardData?.unrealised) ? AppColor.green.withValues(alpha: 0.12) : AppColor.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                              child: Center(
                                                child: Image.asset(
                                                  AmountUtils.isPositive(homeProvider.dashboardData?.unrealised) ? AppImages.realised : AppImages.unRealised,
                                                  color: AmountUtils.isPositive(homeProvider.dashboardData?.unrealised) ? AppColor.green : AppColor.red,
                                                  width: 25,
                                                  height: 25,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Un-Realised P&L',
                                                  textAlign: TextAlign.left,
                                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                                                ),
                                                Text('Current market profit / loss', style: GoogleFonts.poppins(fontSize: 10, color: AppColor.textSecondary)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Text(
                                          homeProvider.dashboardData?.unrealised ?? "-",
                                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AmountUtils.isPositive(homeProvider.dashboardData?.unrealised) ? AppColor.green : AppColor.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // dividend
                                  Divider(height: 0.3, color: AppColor.divider),
                                  Container(
                                    height: 56,
                                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                                    decoration: BoxDecoration(color: AppColor.white, borderRadius: BorderRadius.circular(12)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(color: AppColor.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                              child: Center(child: Image.asset(AppImages.dividend, color: AppColor.primary, width: 25, height: 25)),
                                            ),
                                            SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Dividend Income',
                                                  textAlign: TextAlign.left,
                                                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                                                ),
                                                Text('Total dividend earned', style: GoogleFonts.poppins(fontSize: 10, color: AppColor.textSecondary)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Text(
                                          homeProvider.dashboardData?.dividend ?? "-",
                                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF082EAF)),
                                        ),
                                      ],
                                    ),
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
                                    padding: const EdgeInsets.fromLTRB(8,8,8,0),
                                    child: Text(
                                      'Portfolio Summary',
                                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      // holdings
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          height: 56,
                                          padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                                          decoration: BoxDecoration(color: AppColor.white, borderRadius: BorderRadius.circular(12)),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(color: AppColor.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(50)),
                                                    child: Center(child: Image.asset(AppImages.holdings, color: AppColor.primary, width: 20, height: 20)),
                                                  ),
                                                  SizedBox(width: 6),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        homeProvider.dashboardData?.totalHolding ?? "-",
                                                        textAlign: TextAlign.left,
                                                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                                                      ),
                                                      Text('Holdings', style: GoogleFonts.poppins(fontSize: 10, color: AppColor.textSecondary)),
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
                                          padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                                          decoration: BoxDecoration(color: AppColor.white, borderRadius: BorderRadius.circular(12)),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(color: AppColor.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(50)),
                                                    child: Center(child: Image.asset(AppImages.realised, color: AppColor.green, width: 20, height: 20)),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        homeProvider.dashboardData?.totalGainer ?? "-",
                                                        textAlign: TextAlign.left,
                                                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                                                      ),
                                                      Text('Gainers', style: GoogleFonts.poppins(fontSize: 10, color: AppColor.textSecondary)),
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
                                          padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                                          decoration: BoxDecoration(color: AppColor.white, borderRadius: BorderRadius.circular(12)),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(color: AppColor.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(50)),
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
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        homeProvider.dashboardData?.totalLoser ?? "-",
                                                        textAlign: TextAlign.left,
                                                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                                                      ),
                                                      Text('Losers', style: GoogleFonts.poppins(fontSize: 10, color: AppColor.textSecondary)),
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
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                                ),
                                if (homeProvider.topHoldings.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      widget.onViewAllHoldings?.call();
                                    },
                                    child: Text(
                                      'View All',
                                      style: GoogleFonts.poppins(fontSize: 13, color: AppColor.primary, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            if (homeProvider.topHoldings.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text("No holdings available", style: GoogleFonts.poppins()),
                                ),
                              ),

                            ...homeProvider.topHoldings.map(
                              (stock) => _HoldingTile(
                                holding: stock,
                                onTap: () {
                                  nextRoute(
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return StockDetailScreen(stockId: stock.id.toString());
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const FamilySelectionBottomSheet(),
    );

    if (changed == true && context.mounted) {
      await context.read<HomeProvider>().refreshDashboard(context, isRefresh: false);
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

  List<FlSpot> _getChartSpots(HomeProvider provider) {
    final values = provider.portfolioChartResponse?.data?.chart?.portfolioValues ?? [];

    if (values.isEmpty) {
      return [];
    }

    return List.generate(values.length, (index) => FlSpot(index.toDouble(), values[index]));
  }

  List<DateTime> _getDates(HomeProvider provider) {
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

    final padding = (max * .05).abs();

    return max + padding;
  }

  String _formatAmount(double value) {
    if (value >= 10000000) {
      return "${(value / 10000000).toStringAsFixed(1)}Cr";
    }

    if (value >= 100000) {
      return "${(value / 100000).toStringAsFixed(1)}L";
    }

    if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(0)}K";
    }

    return value.toStringAsFixed(0);
  }

  Widget _leftTitles(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      child: Text(
        _formatAmount(value),
        textAlign: TextAlign.right,
        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
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
        show = index == 0 || index == total ~/ 3 || index == (total * 2) ~/ 3 || index == total - 1;
        break;

      case '1Y':
        show = index % 3 == 0 || index == total - 1;
        break;

      default:
        show = index % 12 == 0 || index == total - 1;
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
        text = date.year.toString();
    }

    return SideTitleWidget(
      meta: meta,
      child: Text(text, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10)),
    );
  }

  String _month(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
              gradient: const LinearGradient(colors: [Color(0xFF0D3CCF), Color(0xFF082EAF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: AppColor.primary.withValues(alpha: .35), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Center(
              child: Text("No chart data available", style: GoogleFonts.poppins(color: AppColor.white, fontSize: 14)),
            ),
          );
        }

        final interval = ((_getMaxY(spots) - _getMinY(spots)) / 4).abs();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0D3CCF), Color(0xFF082EAF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: AppColor.primary.withValues(alpha: .35), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Portfolio", style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 4),
              Text(
                dashboard?.portfolioValue ?? "0",
                style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Gain/Loss", style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60)),

                      Text(
                        dashboard?.totalGainLoss ?? "0",
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: (dashboard?.totalGainLoss).toAmount() < 0 ? Colors.red : const Color(0xFF69FF8C)),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("XIRR", style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60)),

                      Text(
                        "${dashboard?.xirr ?? 0}%",
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: _periods.map((period) {
                  final selected = provider.chartType == period;

                  return GestureDetector(
                    onTap: () {
                      if (provider.chartType == period) return;

                      provider.updateChartType(context, period);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: selected ? Colors.white : Colors.white.withValues(alpha: .15), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        period,
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? AppColor.primary : Colors.white),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 220,
                child: provider.portfolioChartLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
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
                              return FlLine(color: Colors.white12, strokeWidth: 1);
                            },
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: _leftTitles)),

                            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: (value, meta) => _bottomTitles(value, meta, provider))),
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
                                    return LineTooltipItem("₹${spot.y.toStringAsFixed(0)}", GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600));
                                  }

                                  final date = dates[index];
                                  // final amount = spot.y.toStringAsFixed(0);
                                  return LineTooltipItem(
                                    "${date.day} ${_month(date.month)} ${date.year}\n"
                                    "₹${spot.y.toStringAsFixed(0)}",
                                    GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
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
                                      return FlDotCirclePainter(radius: 5, color: Colors.white, strokeWidth: 2, strokeColor: AppColor.primary);
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
                                  return spot.x == 0 || spot.x == spots.length - 1;
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withValues(alpha: .35), Colors.white.withValues(alpha: .18), Colors.white.withValues(alpha: .05), Colors.transparent]),
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              /// Left Indicator
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: gainColor,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), bottomLeft: Radius.circular(25)),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 6, top: 8, bottom: 8),
                  child: Row(
                    children: [
                      /// Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: gainColor.withValues(alpha: .10), borderRadius: BorderRadius.circular(14)),
                        alignment: Alignment.center,
                        child: Text(
                          getInitials(holding.assetName ?? ''),
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: gainColor),
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
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                            ),

                            const SizedBox(height: 8),

                            Text("Today's Gain", style: GoogleFonts.poppins(fontSize: 10, color: AppColor.textSecondary)),

                            const SizedBox(height: 6),

                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if ((holding.todays ?? "").isNotEmpty) _gainChip(value: holding.todays!, color: todayColor),

                                if (holding.todaysPercentage != 0.0) _gainChip(value: "${todayPercent.toStringAsFixed(2)}%", color: todayColor),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(vertical: 4)),
                      const SizedBox(width: 8),

                      /// Right Values
                      SizedBox(
                        width: 65,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Invested", style: GoogleFonts.poppins(fontSize: 9, color: AppColor.textSecondary)),

                            const SizedBox(height: 2),

                            Text(
                              holding.investedValue ?? "",
                              style: GoogleFonts.poppins(color: AppColor.black, fontWeight: FontWeight.w600, fontSize: 10),
                            ),

                            const SizedBox(height: 6),

                            Text("Current", style: GoogleFonts.poppins(fontSize: 9, color: AppColor.textSecondary)),

                            const SizedBox(height: 2),

                            Text(
                              holding.currentValue ?? "",
                              style: GoogleFonts.poppins(color: AppColor.black, fontWeight: FontWeight.w600, fontSize: 10),
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
                            Icon(isGain ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: gainColor, size: 20),

                            Text(
                              "${gainPercent.abs().toStringAsFixed(2)}%",
                              style: GoogleFonts.poppins(color: gainColor, fontWeight: FontWeight.w700, fontSize: 10),
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
      decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(6)),
      child: Text(
        value,
        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
