import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/model/net_contribution_response.dart';
import 'package:profit_from_it_investors/provider/net_contribution_provider/net_contribution_provider.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:provider/provider.dart';

class NetContributionScreen extends StatefulWidget {
  const NetContributionScreen({super.key});

  @override
  State<NetContributionScreen> createState() => _NetContributionScreenState();
}

class _NetContributionScreenState extends State<NetContributionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<NetContributionProvider>().getNetContributionDetails();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NetContributionProvider>();
    final data = provider.data;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          color: AppColor.textPrimary,
        ),
        titleSpacing: 0,
        title: Text(
          'Net Contribution',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColor.textPrimary,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColor.divider),
        ),
      ),
      body: provider.isLoading && data == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.refreshNetContributionDetails,
              child: Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                            child: _ContributionHeader(data: data),
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                            child: _ContributionTabs(
                              controller: _tabController,
                            ),
                          ),
                        ),

                        SliverFillRemaining(
                          hasScrollBody: true,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _ContributionTabContent(
                                  entries: data?.payIn ?? const [],
                                  totalLabel: 'Total Pay In',
                                  totalAmount:
                                      data?.payInTotalFormatted ?? '₹0.00',
                                  emptyTitle: 'No Pay In entries',
                                  emptySubtitle:
                                      'Receipt vouchers will appear here.',
                                ),
                                _ContributionTabContent(
                                  entries: data?.payOut ?? const [],
                                  totalLabel: 'Total Pay Out',
                                  totalAmount:
                                      data?.payOutTotalFormatted ?? '₹0.00',
                                  emptyTitle: 'No Pay Out entries',
                                  emptySubtitle:
                                      'Payment vouchers will appear here.',
                                ),
                                _ContributionTabContent(
                                  entries: data?.buyback ?? const [],
                                  totalLabel: 'Total Buy Back',
                                  totalAmount:
                                      data?.buybackTotalFormatted ?? '₹0.00',
                                  emptyTitle: 'No Buy Back entries',
                                  emptySubtitle:
                                      'Buy Back vouchers will appear here.',
                                ),
                              ],
                            ),
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
}

class _ContributionHeader extends StatelessWidget {
  final NetContributionData? data;

  const _ContributionHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    final clientName = (data?.activeClientName ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B2451), Color(0xFF123B7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2451).withValues(alpha: .10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 21,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Net Contribution',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: .78),
                      ),
                    ),
                    if (clientName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: .58),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            data?.netContributionFormatted ?? '₹0.00',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 29,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: Colors.white.withValues(alpha: .10)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeaderMiniValue(
                  label: 'Pay In',
                  value: data?.payInTotalFormatted ?? '₹0.00',
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: Colors.white.withValues(alpha: .10),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: _HeaderMiniValue(
                    label: 'Pay Out',
                    value: data?.payOutTotalFormatted ?? '₹0.00',
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: Colors.white.withValues(alpha: .10),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: _HeaderMiniValue(
                    label: 'Buy Back',
                    value: data?.buybackTotalFormatted ?? '₹0.00',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMiniValue extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderMiniValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          style: GoogleFonts.poppins(
            fontSize: 9.5,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: .60),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ContributionTabs extends StatelessWidget {
  final TabController controller;

  const _ContributionTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F8),
        borderRadius: BorderRadius.circular(13),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: AppColor.primary,
        unselectedLabelColor: AppColor.textSecondary,
        labelStyle: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Pay In'),
          Tab(text: 'Pay Out'),
          Tab(text: 'Buy Back'),
        ],
      ),
    );
  }
}

class _ContributionTabContent extends StatelessWidget {
  final List<ContributionEntry> entries;
  final String totalLabel;
  final String totalAmount;
  final String emptyTitle;
  final String emptySubtitle;

  const _ContributionTabContent({
    required this.entries,
    required this.totalLabel,
    required this.totalAmount,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _TableHeader(),

          Expanded(
            child: entries.isEmpty
                ? _EmptyContributionState(
                    title: emptyTitle,
                    subtitle: emptySubtitle,
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: entries.length,
                    separatorBuilder: (context, index) {
                      return const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFF0F2F5),
                      );
                    },
                    itemBuilder: (context, index) {
                      return _ContributionRow(entry: entries[index]);
                    },
                  ),
          ),

          _TotalFooter(label: totalLabel, amount: totalAmount),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE8EDF4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'DATE',
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: .5,
                color: AppColor.textSecondary,
              ),
            ),
          ),
          Text(
            'AMOUNT',
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: .5,
              color: AppColor.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionRow extends StatelessWidget {
  final ContributionEntry entry;

  const _ContributionRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = (entry.displayDate ?? entry.date ?? '-').trim();

    final amount = (entry.amountFormatted ?? '₹0.00').trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 17,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              date.isEmpty ? '-' : date,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColor.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount.isEmpty ? '₹0.00' : amount,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColor.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalFooter extends StatelessWidget {
  final String label;
  final String amount;

  const _TotalFooter({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Color(0xFFE8EDF4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColor.textSecondary,
              ),
            ),
          ),
          Text(
            amount,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColor.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyContributionState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyContributionState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColor.textSecondary,
                size: 23,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColor.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                height: 1.4,
                color: AppColor.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
