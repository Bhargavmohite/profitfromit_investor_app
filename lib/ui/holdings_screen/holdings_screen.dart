import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/model/holdings_detail_response.dart';
import 'package:profit_from_it_investors/provider/holdings/holdings_provider.dart';
import 'package:profit_from_it_investors/ui/holdings_screen/holding_sort_type.dart';
import 'package:profit_from_it_investors/ui/holdings_screen/holdings_sort_bottom_sheet.dart';
import 'package:profit_from_it_investors/ui/stock_detail_screen/stock_detail_screen.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:provider/provider.dart';

class HoldingsScreen extends StatefulWidget {
  const HoldingsScreen({super.key});

  @override
  State<HoldingsScreen> createState() => _HoldingsScreenState();
}

class _HoldingsScreenState extends State<HoldingsScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        leading: null,
        automaticallyImplyLeading: false,
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
