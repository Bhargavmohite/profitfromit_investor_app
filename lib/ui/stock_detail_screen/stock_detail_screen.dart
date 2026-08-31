import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/model/stock_detail_response.dart';
import 'package:profit_from_it_investors/provider/stock_detail/stock_detail_provider.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:provider/provider.dart';

class StockDetailScreen extends StatefulWidget {
  final String stockId;

  const StockDetailScreen({super.key, required this.stockId});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  int _selectedTab = 0;
  static const List<String> _tabs = ['Overview', 'Transactions'];
  String _activeTransactionFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockDetailProvider>().getStockDetail(context, stockId: widget.stockId, isRefresh: true);
    });
  }

  Future<void> _onRefresh() async {
    await context.read<StockDetailProvider>().getStockDetail(context, stockId: widget.stockId, isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, size: 20),
        ),
        title: Text(
          'Stock Detail',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: Consumer<StockDetailProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (provider.stockDetailResponse == null) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: const Center(child: Text("No Data Found")),
                ),
              ),
            );
          } else {
            final StockDetailResponse? response = provider.stockDetailResponse;
            final Data? stockData = response?.data;
            final Summary? summary = stockData?.summary;
            final double totalGainPercent = summary?.totalGain.toAmount() ?? 0.0;
            final bool isLoss = totalGainPercent < 0;

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // HEADER
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stockData!.companyName ?? "",
                            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
                          ),

                          const SizedBox(height: 2),

                          Text(stockData.isin ?? "", style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),

                          const SizedBox(height: 12),

                          Text(
                            summary?.currentValue ?? "0",
                            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
                          ),

                          const SizedBox(height: 4),

                          Row(
                            children: [
                              Icon(isLoss ? Icons.arrow_drop_down : Icons.arrow_drop_up, color: isLoss ? AppColor.lossText : AppColor.gainText, size: 20),
                              Text(
                                summary?.totalGain ?? "0",
                                /*(${totalGainPercent.abs().toStringAsFixed(2)}%)*/
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: isLoss ? AppColor.lossText : AppColor.gainText),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // TABS
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(_tabs.length, (i) {
                                final bool sel = i == _selectedTab;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedTab = i;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 20),
                                    padding: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: sel ? AppColor.primary : Colors.transparent, width: 2.5)),
                                    ),
                                    child: Text(
                                      _tabs[i],
                                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? AppColor.primary : AppColor.textSecondary),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // TAB CONTENT
                    if (_selectedTab == 0) _buildOverview(summary, isLoss, totalGainPercent),

                    if (_selectedTab == 1) _buildTransactions(stockData.transactions ?? []),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildOverview(Summary? summary, bool isLoss, double totalGainPercent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _InfoRow(label: 'Holding Qty', value: summary?.holdingQty ?? "-"),

          const Divider(height: 24),

          _InfoRow(label: 'Average Buy Price', value: summary?.avgBuyPrice ?? "-"),

          const Divider(height: 24),

          _InfoRow(label: 'Invested Value', value: summary?.investedValue ?? "-"),

          const Divider(height: 24),

          _InfoRow(label: 'Current Value', value: summary?.currentValue ?? "-"),

          const Divider(height: 24),

          _InfoRow(label: 'Total Gain', value: summary?.totalGain ?? "-", valueColor: isLoss ? AppColor.lossText : AppColor.gainText),

          const Divider(height: 24),

          _InfoRow(label: 'XIRR', value: summary?.xirr ?? "-", valueColor: AppColor.primary),

          const Divider(height: 24),

          _InfoRow(label: 'Total Holding Value', value: summary?.totalHoldingValue ?? "-"),

          const Divider(height: 24),

          _InfoRow(label: 'Total Buy Amount', value: summary?.totalBuyAmount ?? "-"),

          const Divider(height: 24),

          _InfoRow(label: 'Total Sell Amount', value: summary?.totalSellAmount ?? "-"),

          const Divider(height: 24),

          _InfoRow(label: 'Realised Gain', value: summary?.realisedGain ?? "-"),

          const Divider(height: 24),

          _InfoRow(label: 'Unrealised Gain', value: summary?.unrealisedGain ?? "-"),

          const Divider(height: 24),

          _InfoRow(label: "Today's Gain", value: summary?.todaysGain ?? "-"),

          const Divider(height: 24),

          _InfoRow(label: 'Dividend', value: summary?.dividend ?? "-"),
        ],
      ),
    );
  }

  // Widget _buildTransactions(List<Transaction> transactions) {
  //   if (transactions.isEmpty) {
  //     return _buildEmptyState("No Transactions Found");
  //   }
  //
  //   return Container(
  //     color: Colors.white,
  //     padding: const EdgeInsets.all(16),
  //     child: ListView.separated(
  //       shrinkWrap: true,
  //       physics: const NeverScrollableScrollPhysics(),
  //       itemCount: transactions.length,
  //       separatorBuilder: (_, _) => const Divider(height: 24),
  //       itemBuilder: (context, index) {
  //         final item = transactions[index];
  //
  //         final uiData = getTransactionUiData(item.action);
  //
  //         return Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Container(
  //               width: 42,
  //               height: 42,
  //               decoration: BoxDecoration(color: uiData.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
  //               child: Icon(uiData.icon, color: uiData.color),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text('${uiData.title} • ${item.quantity ?? 0} Qty', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
  //                   const SizedBox(height: 4),
  //                   Text(item.date ?? "", style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),
  //                   const SizedBox(height: 4),
  //                   Text('Balance Qty: ${item.balanceQty ?? "-"}', style: GoogleFonts.poppins(fontSize: 11, color: AppColor.textLight)),
  //                 ],
  //               ),
  //             ),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.end,
  //               children: [
  //                 Text(item.amount ?? "-", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
  //                 const SizedBox(height: 4),
  //                 Text(item.price ?? "0", style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),
  //                 const SizedBox(height: 4),
  //                 Text('Brokerage: ${item.brokerage ?? "0"}', style: GoogleFonts.poppins(fontSize: 11, color: AppColor.textLight)),
  //               ],
  //             ),
  //           ],
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _buildTransactions(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return _buildEmptyState("No Transactions Found");
    }

    final filters = _getTransactionFilters(transactions);
    final items = _filteredTransactions(transactions);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildTransactionFilter(filters, transactions),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final item = items[index];

              final uiData = getTransactionUiData(item.action);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: uiData.color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10)),
                    child: Icon(uiData.icon, color: uiData.color),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${uiData.title} • ${item.quantity ?? 0} Qty', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),

                        const SizedBox(height: 4),

                        Text(item.date ?? "", style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),

                        const SizedBox(height: 4),

                        Text('Balance Qty: ${item.balanceQty ?? "-"}', style: GoogleFonts.poppins(fontSize: 11, color: AppColor.textLight)),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(item.amount ?? "-", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),

                      const SizedBox(height: 4),

                      Text(item.price ?? "0", style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),

                      const SizedBox(height: 4),

                      Text('Brokerage: ${item.brokerage ?? "0"}', style: GoogleFonts.poppins(fontSize: 11, color: AppColor.textLight)),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Text(title, style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textSecondary)),
      ),
    );
  }

  TransactionUiData getTransactionUiData(String? action) {
    switch ((action ?? '').toUpperCase()) {
      case 'B':
        return const TransactionUiData(icon: Icons.arrow_downward_rounded, color: AppColor.success, title: 'Buy');

      case 'S':
        return const TransactionUiData(icon: Icons.arrow_upward_rounded, color: AppColor.danger, title: 'Sell');

      case 'DIVIDEND':
        return const TransactionUiData(icon: Icons.payments_rounded, color: Colors.orange, title: 'Dividend');

      case 'BONUS':
        return const TransactionUiData(icon: Icons.card_giftcard_rounded, color: Colors.purple, title: 'Bonus');

      default:
        return const TransactionUiData(icon: Icons.swap_horiz_rounded, color: Colors.blueGrey, title: 'Transaction');
    }
  }

  List<String> _getTransactionFilters(List<Transaction> transactions) {
    final filters = <String>['All'];

    for (final tx in transactions) {
      final type = _getTransactionType(tx.action);

      if (!filters.contains(type)) {
        filters.add(type);
      }
    }

    return filters;
  }

  String _getTransactionType(String? action) {
    switch ((action ?? '').toUpperCase()) {
      case 'B':
        return 'Buy';

      case 'S':
        return 'Sell';

      case 'DIVIDEND':
        return 'Dividend';

      case 'BONUS':
        return 'Bonus';

      default:
        return 'Other';
    }
  }

  List<Transaction> _filteredTransactions(List<Transaction> transactions) {
    if (_activeTransactionFilter == 'All') {
      return transactions;
    }

    return transactions.where((tx) {
      return _getTransactionType(tx.action) == _activeTransactionFilter;
    }).toList();
  }

  Widget _buildTransactionFilter(List<String> filters, List<Transaction> transactions) {
    return Container(
      color: AppColor.white,
      child: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final filter = filters[index];

                final isSelected = filter == _activeTransactionFilter;

                Color color = AppColor.primary;

                if (filter != 'All') {
                  color = getTransactionUiData(transactions.firstWhere((e) => _getTransactionType(e.action) == filter).action).color;
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeTransactionFilter = filter;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(color: isSelected ? color : color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(24)),
                    child: Text(
                      filter,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : color),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class TransactionUiData {
  final IconData icon;
  final Color color;
  final String title;

  const TransactionUiData({required this.icon, required this.color, required this.title});
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: GoogleFonts.poppins(fontSize: 13, color: AppColor.textSecondary)),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? AppColor.textPrimary),
          ),
        ),
      ],
    );
  }
}
