import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/model/watchlist_response.dart';
import 'package:profit_from_it_investors/provider/watchlist_provider/watchlist_provider.dart';
import 'package:profit_from_it_investors/ui/stock_detail_screen/stock_detail_screen.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:provider/provider.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  TopMoverType _selectedType = TopMoverType.gainers;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WatchlistProvider>().getTopMovers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Top Movers',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColor.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer<WatchlistProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.watchlistResponse == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final gainers = provider.watchlistResponse?.data?.gainers ?? [];
          final losers = provider.watchlistResponse?.data?.losers ?? [];
          final highestYielding =
              provider.watchlistResponse?.data?.highestYieldingAssets ?? [];
          final lowestYielding =
              provider.watchlistResponse?.data?.lowestYieldingAssets ?? [];

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: Column(
              children: [
                _MoverToggle(
                  selectedType: _selectedType,
                  onChanged: (type) {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                ),

                Expanded(
                  child: _MoverListPage(
                    items: switch (_selectedType) {
                      TopMoverType.gainers => gainers,
                      TopMoverType.losers => losers,
                      TopMoverType.highestYielding => highestYielding,
                      TopMoverType.lowestYielding => lowestYielding,
                    },
                    type: _selectedType,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MoverToggle extends StatelessWidget {
  final TopMoverType selectedType;
  final ValueChanged<TopMoverType> onChanged;

  const _MoverToggle({required this.selectedType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7EBF2)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _MoverToggleButton(
              title: 'Top Gainers',
              icon: Icons.trending_up_rounded,
              isSelected: selectedType == TopMoverType.gainers,
              onTap: () => onChanged(TopMoverType.gainers),
            ),
            _MoverToggleButton(
              title: 'Top Losers',
              icon: Icons.trending_down_rounded,
              isSelected: selectedType == TopMoverType.losers,
              onTap: () => onChanged(TopMoverType.losers),
            ),
            _MoverToggleButton(
              title: 'Highest Yielding',
              icon: Icons.percent_rounded,
              isSelected: selectedType == TopMoverType.highestYielding,
              onTap: () => onChanged(TopMoverType.highestYielding),
            ),
            _MoverToggleButton(
              title: 'Lowest Yielding',
              icon: Icons.show_chart_rounded,
              isSelected: selectedType == TopMoverType.lowestYielding,
              onTap: () => onChanged(TopMoverType.lowestYielding),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoverToggleButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoverToggleButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF0A2D63);

    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: .16),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : const Color(0xFF52627A),
              ),
              const SizedBox(width: 5),
              Text(
                title,
                maxLines: 1,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF52627A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _MoverListPage extends StatelessWidget {
  final List<Gainer> items;
  final TopMoverType type;

  const _MoverListPage({required this.items, required this.type});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColor.textSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 18),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final item = items[index];

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            nextRoute(
              MaterialPageRoute(
                builder: (context) {
                  return StockDetailScreen(stockId: item.id.toString());
                },
              ),
            );
          },
          child: _MoverTile(item: item, type: type),
        );
      },
    );
  }
}

class _MoverTile extends StatelessWidget {
  final Gainer item;
  final TopMoverType type;

  const _MoverTile({required this.item, required this.type});

  @override
  Widget build(BuildContext context) {
    final bool isYielding =
        type == TopMoverType.highestYielding ||
        type == TopMoverType.lowestYielding;

    final double percentValue = isYielding
        ? (item.gainerReturn ?? 0).toDouble()
        : (item.changePercent ?? 0).toDouble();

    final bool isPositive = percentValue >= 0;
    final Color movementColor = isPositive
        ? const Color(0xFF009B72)
        : const Color(0xFFE53935);

    final String company = (item.company ?? '').trim();
    final String cmp = _formatMoney(item.cmp);
    final String avgCost = _formatMoney(item.avgCost);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 11, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E9F1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: initials, company, CMP and % movement.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: getAvatarColor(item.id ?? '').withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      getInitials(company),
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: getAvatarColor(item.id ?? ''),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  company,
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

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cmp,
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: movementColor.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_drop_up_rounded
                              : Icons.arrow_drop_down_rounded,
                          size: 13,
                          color: movementColor,
                        ),
                        Text(
                          '${percentValue.abs().toStringAsFixed(2)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: movementColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 9),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F6)),

          const SizedBox(height: 9),

          // Bottom row: Avg Cost + relevant metric + arrow.
          Row(
            children: [
              if ((item.avgCost ?? '').trim().isNotEmpty) ...[
                Text(
                  'Avg Cost:',
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    color: AppColor.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  avgCost,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 13, color: const Color(0xFFE6EAF0)),
                const SizedBox(width: 12),
              ],

              Expanded(
                child: Row(
                  children: [
                    Text(
                      isYielding ? 'Unrealized Yield:' : 'Change:',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w500,
                        color: AppColor.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${isPositive ? '+' : '-'}${percentValue.abs().toStringAsFixed(2)}%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: movementColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              const Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: Color(0xFF66758B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMoney(String? raw) {
    final value = (raw ?? '').trim();

    if (value.isEmpty || value == '0') {
      return value.isEmpty ? '-' : '₹0';
    }

    return value.startsWith('₹') ? value : '₹$value';
  }

  String getInitials(String company) {
    final words = company
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return '';

    if (words.length == 1) {
      return words.first.length >= 3
          ? words.first.substring(0, 3).toUpperCase()
          : words.first.toUpperCase();
    }

    if (words.length == 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    }

    return (words[0][0] + words[1][0] + words[2][0]).toUpperCase();
  }

  Color getAvatarColor(String seed) {
    const colors = [
      Color(0xFF1A5FFF),
      Color(0xFFF57F17),
      Color(0xFF2E7D32),
      Color(0xFF00897B),
      Color(0xFF4527A0),
      Color(0xFF0288D1),
      Color(0xFF6D4C41),
      Color(0xFFE53935),
      Color(0xFFAB47BC),
      Color(0xFF37474F),
    ];

    return colors[seed.hashCode.abs() % colors.length];
  }
}
