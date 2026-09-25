import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/model/dividend_response.dart';
import 'package:profit_from_it_investors/provider/dividend_provider/dividend_provider.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:provider/provider.dart';

class DividendScreen extends StatefulWidget {
  const DividendScreen({super.key});

  @override
  State<DividendScreen> createState() => _DividendScreenState();
}

class _DividendScreenState extends State<DividendScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<DividendProvider>().getDividendDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DividendProvider>();
    final data = provider.data;
    final dividends = provider.dividends;

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
          'Dividend Income',
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
              onRefresh: provider.refreshDividendDetails,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  _DividendSummaryCard(data: data),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    count: data?.dividendCount ?? dividends.length,
                  ),
                  const SizedBox(height: 10),
                  if (dividends.isEmpty)
                    const _EmptyDividendState()
                  else
                    _DividendTable(dividends: dividends),
                  const SizedBox(height: 12),
                  _DividendTotalFooter(
                    total: data?.totalDividendFormatted ?? '₹0.00',
                  ),
                ],
              ),
            ),
    );
  }
}

class _DividendSummaryCard extends StatelessWidget {
  final DividendData? data;

  const _DividendSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final clientName = (data?.activeClientName ?? '').trim();
    final dividendCount = data?.dividendCount ?? 0;

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.payments_outlined,
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
                      'Total Dividend Income',
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
            data?.totalDividendFormatted ?? '₹0.00',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 30,
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
              const Icon(
                Icons.receipt_long_rounded,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 7),
              Text(
                '$dividendCount dividend '
                '${dividendCount == 1 ? 'entry' : 'entries'} applied',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: .72),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final int count;

  const _SectionHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dividend Applied',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Dividend history based on eligible quantity on the ex-date',
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w400,
                  color: AppColor.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColor.primary.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColor.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DividendTable extends StatelessWidget {
  final List<DividendEntry> dividends;

  const _DividendTable({required this.dividends});

  static const double _tableWidth = 760;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: _tableWidth,
          child: Column(
            children: [
              const _DividendTableHeader(),
              ...List.generate(dividends.length, (index) {
                return Column(
                  children: [
                    _DividendTableRow(entry: dividends[index]),
                    if (index != dividends.length - 1)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 14,
                        endIndent: 14,
                        color: Color(0xFFF0F2F5),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _DividendTableHeader extends StatelessWidget {
  const _DividendTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE8EDF4))),
      ),
      child: Row(
        children: [
          _HeaderCell(width: 105, text: 'DATE'),
          _HeaderCell(width: 230, text: 'COMPANY NAME'),
          _HeaderCell(width: 135, text: 'DIVIDEND / SHARE', alignRight: true),
          _HeaderCell(width: 90, text: 'QUANTITY', alignRight: true),
          _HeaderCell(width: 160, text: 'TOTAL DIVIDEND', alignRight: true),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final double width;
  final String text;
  final bool alignRight;

  const _HeaderCell({
    required this.width,
    required this.text,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: .45,
          color: AppColor.textSecondary,
        ),
      ),
    );
  }
}

class _DividendTableRow extends StatelessWidget {
  final DividendEntry entry;

  const _DividendTableRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final displayDate = (entry.displayDate ?? entry.date ?? '-').trim();

    final company = (entry.companyName ?? '-').trim();

    final perShare = (entry.perShareDividendFormatted ?? '₹0.00').trim();

    final total = (entry.totalDividendFormatted ?? '₹0.00').trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              displayDate.isEmpty ? '-' : displayDate,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColor.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 230,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                company.isEmpty ? '-' : company,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: AppColor.textPrimary,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 135,
            child: Text(
              perShare.isEmpty ? '₹0.00' : perShare,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColor.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              _formatQuantity(entry.quantity),
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColor.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: Text(
              total.isEmpty ? '₹0.00' : total,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColor.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatQuantity(double? value) {
    final qty = value ?? 0;

    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }

    return qty.toStringAsFixed(2);
  }
}

class _DividendTotalFooter extends StatelessWidget {
  final String total;

  const _DividendTotalFooter({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.summarize_outlined,
              size: 18,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Total Dividend Income',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColor.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            total,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColor.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDividendState extends StatelessWidget {
  const _EmptyDividendState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.payments_outlined,
              size: 24,
              color: AppColor.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No dividend entries found',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColor.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Eligible dividend corporate actions will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              height: 1.45,
              color: AppColor.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
