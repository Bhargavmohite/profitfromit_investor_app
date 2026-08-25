import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/model/transaction_response.dart';
import 'package:profit_from_it_investors/provider/transaction_provider/transaction_provider.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:provider/provider.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String _activeFilter = 'All';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().getTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          'Transactions',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
        ),
        centerTitle: false,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filterTypes = provider.transactionTypes;

          if (!filterTypes.contains(_activeFilter)) {
            _activeFilter = 'All';
          }

          final items = provider.filteredTransactions(_activeFilter);

          return RefreshIndicator(
            onRefresh: provider.refreshTransactions,
            child: Column(
              children: [
                _buildFilterSection(provider, filterTypes),

                Expanded(
                  child: items.isEmpty
                      ? _EmptyState(filter: _activeFilter)
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          itemCount: items.length,
                          itemBuilder: (_, index) => _TransactionTile(tx: items[index]),
                        ),
                ),

                // const AppBottomNavBar(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(TransactionProvider provider, List<String> filterTypes) {
    return Container(
      color: AppColor.white,
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filterTypes.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = filterTypes[index];

                bool isSelected = filter == _activeFilter;

                Color pillColor = AppColor.primary;

                if (filter != 'All') {
                  final tx = provider.transactions.firstWhere((e) => e.type == filter);

                  pillColor = (tx.colorCode ?? tx.color).toColor();
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeFilter = filter;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: isSelected ? pillColor : pillColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(24)),
                    child: Text(
                      filter,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : pillColor),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final Color dotColor = (tx.colorCode ?? tx.color).toColor();

    final double amount = tx.amount?.toAmount() ?? 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: dotColor.withValues(alpha: 0.40), blurRadius: 6)],
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.type ?? '',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: dotColor),
                ),

                const SizedBox(height: 2),

                Text(
                  tx.companyName ?? '',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColor.textPrimary),
                ),

                const SizedBox(height: 2),

                Text(tx.displayText ?? '', style: GoogleFonts.poppins(fontSize: 12, color: AppColor.textSecondary)),

                if ((tx.balanceQty ?? '0') != '0') ...[const SizedBox(height: 5), _BalanceChip(qty: tx.balanceQty ?? '0', color: dotColor)],
              ],
            ),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(tx.date ?? '', style: GoogleFonts.poppins(fontSize: 11, color: AppColor.textLight)),

              const SizedBox(height: 6),

              amount > 0
                  ? Text(
                      '${tx.amount}',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: dotColor),
                    )
                  : Text('—', style: GoogleFonts.poppins(fontSize: 13, color: AppColor.textLight)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  final String qty;
  final Color color;

  const _BalanceChip({required this.qty, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(6)),
      child: Text(
        'Balance: $qty',
        style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: AppColor.textLight.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            filter == 'All' ? 'No transactions yet' : 'No $filter transactions',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColor.textSecondary),
          ),
          const SizedBox(height: 6),
          Text('Your transaction history will appear here', style: GoogleFonts.poppins(fontSize: 13, color: AppColor.textLight)),
        ],
      ),
    );
  }
}