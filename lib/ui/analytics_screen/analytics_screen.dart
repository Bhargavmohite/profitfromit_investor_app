import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/model/analytics_response.dart';
import 'package:profit_from_it_investors/provider/analytics_provider/analytics_provider.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:provider/provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _filterIndex = 0;
  int _touchedPie = -1;
  final List<Color> chartColors = [AppColor.primary, AppColor.accent, AppColor.green, AppColor.danger, AppColor.success, AppColor.warning];

  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().getAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
        ),
        centerTitle: false,
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.analyticsResponse == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.analyticsResponse == null) {
            return Center(child: Text('No data found', style: GoogleFonts.poppins()));
          }

          final List<Map<String, dynamic>> filters = [
            {"title": "By Sector", "data": provider.sectors},
            {"title": "By Market Cap", "data": provider.marketCaps},
          ];

          final selectedFilter = filters[_filterIndex];

          final List<MarketCap> chartData = selectedFilter["data"];

          return SafeArea(
            child: RefreshIndicator(
              color: AppColor.primary,
              onRefresh: () async {
                await provider.getAnalytics(isRefresh: false);
              },

              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FILTERS
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                      ),

                      child: Row(
                        children: List.generate(filters.length, (i) {
                          final bool selected = i == _filterIndex;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _filterIndex = i;
                                  _touchedPie = -1;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selected ? AppColor.primary.withValues(alpha: 0.1) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: selected ? Border.all(color: AppColor.primary.withValues(alpha: 0.3)) : null,
                                ),

                                child: Text(
                                  filters[i]["title"],
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColor.primary : AppColor.textSecondary),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // CHART CARD
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                      ),
                      child: chartData.isEmpty
                          ? SizedBox(
                              height: 220,
                              child: Center(
                                child: Text('No analytics data found', style: GoogleFonts.poppins(color: AppColor.textSecondary)),
                              ),
                            )
                          : Row(
                              children: [
                                // PIE CHART
                                SizedBox(
                                  height: 160,
                                  width: 160,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      PieChart(
                                        PieChartData(
                                          pieTouchData: PieTouchData(
                                            touchCallback: (event, response) {
                                              setState(() {
                                                _touchedPie = response?.touchedSection?.touchedSectionIndex ?? -1;
                                              });
                                            },
                                          ),
                                          sections: List.generate(chartData.length, (i) {
                                            final data = chartData[i];
                                            final bool touched = i == _touchedPie;
                                            return PieChartSectionData(color: chartColors[i % chartColors.length], value: data.percent ?? 0, title: '', radius: touched ? 60 : 52);
                                          }),
                                          centerSpaceRadius: 36,
                                          sectionsSpace: 2,
                                        ),
                                      ),

                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Total', style: GoogleFonts.poppins(fontSize: 10, color: AppColor.textSecondary)),
                                          Text(
                                            provider.totalValue,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
                                          ),
                                          Text('100%', style: GoogleFonts.poppins(fontSize: 10, color: AppColor.textSecondary)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // LEGENDS
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: chartData.asMap().entries.map((entry) {
                                      final int i = entry.key;
                                      final item = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(color: chartColors[i % chartColors.length], shape: BoxShape.circle),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                item.label ?? '',
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(fontSize: 11, color: AppColor.textSecondary),
                                              ),
                                            ),
                                            Text(
                                              '${(item.percent ?? 0).toStringAsFixed(2)}%',
                                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${selectedFilter["title"]} Details',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: chartData.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = chartData[index];
                          final color = chartColors[index % chartColors.length];

                          final bool isExpanded = _expandedIndex == index;

                          return Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedIndex = -1;
                                    } else {
                                      _expandedIndex = index;
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      /// COLOR DOT
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                      ),

                                      const SizedBox(width: 12),

                                      /// TITLE
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.label ?? '',
                                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(item.amount ?? '0', style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),
                                          ],
                                        ),
                                      ),

                                      /// Percentage Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
                                        child: Text(
                                          '${(item.percent ?? 0).toStringAsFixed(2)}%',
                                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      /// Expand Arrow
                                      AnimatedRotation(
                                        turns: isExpanded ? 0.5 : 0,
                                        duration: const Duration(milliseconds: 250),
                                        child: const Icon(Icons.keyboard_arrow_down_rounded, size: 28, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              /// COMPANY LIST
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                child: isExpanded
                                    ? Padding(
                                        padding: const EdgeInsets.only(left: 40, right: 16, bottom: 14),
                                        child: item.companies == null || item.companies!.isEmpty
                                            ? Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                child: Text('No companies available', style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),
                                              )
                                            : Column(
                                                children: List.generate(item.companies!.length, (companyIndex) {
                                                  final company = item.companies![companyIndex];

                                                  return Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.business, size: 18, color: Colors.grey),
                                                        const SizedBox(width: 10),

                                                        Expanded(
                                                          child: Text(company.name ?? '', style: GoogleFonts.poppins(fontSize: 13, color: AppColor.textPrimary)),
                                                        ),

                                                        Text(
                                                          '${(company.percent ?? 0).toStringAsFixed(2)}%',
                                                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.primary),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                              ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
