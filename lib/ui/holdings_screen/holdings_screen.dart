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
                decoration: const InputDecoration(hintText: 'Search holdings...', border: InputBorder.none),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
              )
            : Text(
                'Holdings',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
              ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: AppColor.textPrimary),
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
                    child: Center(child: Text("No data found", style: GoogleFonts.poppins())),
                  ),
                ],
              ),
            );
          }

          final holdings = provider.holdings;

          final filteredHoldings = holdings.where((holding) {
            final name = (holding.assetName ?? '').toLowerCase();
            return name.contains(_searchText.toLowerCase());
          }).toList();

          _applySorting(filteredHoldings);

          return Column(
            children: [
              // Total Summary
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Holdings (${filteredHoldings.length})', style: GoogleFonts.poppins(fontSize: 13, color: AppColor.textSecondary)),
                    Text(
                      provider.totalInvested,
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
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
                                child: Text('No holdings found', style: GoogleFonts.poppins(color: AppColor.textSecondary)),
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
                                Navigator.push(context, MaterialPageRoute(builder: (_) => StockDetailScreen(stockId: holding.id ?? '')));
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
        list.sort((a, b) => (a.assetName?.toLowerCase() ?? '').compareTo(b.assetName?.toLowerCase() ?? ''));
        break;

      case HoldingSortType.alphabeticalDesc:
        list.sort((a, b) => (b.assetName?.toLowerCase() ?? '').compareTo(a.assetName?.toLowerCase() ?? ''));
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
        list.sort((a, b) => b.investedValue.toAmount().compareTo(a.investedValue.toAmount()));
        break;

      case HoldingSortType.investedLowToHigh:
        list.sort((a, b) => a.investedValue.toAmount().compareTo(b.investedValue.toAmount()));
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

                            Text(holding.investedValue ?? "", style: GoogleFonts.poppins(color: AppColor.black, fontWeight: FontWeight.w600, fontSize: 10)),

                            const SizedBox(height: 6),

                            Text("Current", style: GoogleFonts.poppins(fontSize: 9, color: AppColor.textSecondary)),

                            const SizedBox(height: 2),

                            Text(holding.currentValue ?? "", style: GoogleFonts.poppins(color: AppColor.black, fontWeight: FontWeight.w600, fontSize: 10)),
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
