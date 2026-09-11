import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/provider/taxometer/taxometer_provider.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:provider/provider.dart';

class TaxometerScreen extends StatefulWidget {
  const TaxometerScreen({super.key});

  @override
  State<TaxometerScreen> createState() => _TaxometerScreenState();
}

class _TaxometerScreenState extends State<TaxometerScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await context.read<TaxometerProvider>().getTaxometer(context);
    });
  }

  String _fyShort(String financialYear) {
    final parts = financialYear.split('-');

    if (parts.length != 2 || parts.first.length < 4 || parts.last.length < 4) {
      return financialYear.isEmpty ? 'FY' : financialYear;
    }

    return 'FY${parts.first.substring(2)}-${parts.last.substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final taxometerProvider = context.watch<TaxometerProvider>();
    final taxData = taxometerProvider.taxData;

    return Scaffold(
      backgroundColor: AppColor.background,
      body:
          taxometerProvider.taxometerLoading &&
              taxometerProvider.taxometerResponse == null
          ? const SafeArea(
              child: Center(
                child: CircularProgressIndicator(color: AppColor.primary),
              ),
            )
          : taxData == null
          ? SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 42,
                        color: AppColor.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        taxometerProvider.taxometerResponse?.message ??
                            'Taxometer data is not available.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColor.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () {
                          taxometerProvider.getTaxometer(context);
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  await taxometerProvider.refreshTaxometer(context);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(taxometerProvider),
                      const SizedBox(height: 16),
                      _buildStatCard(
                        indicatorColor: AppColor.danger,
                        title: 'REALIZED STCG (20%)',
                        amount: _formatCurrency(taxData.grossRealizedStcg),
                        taxLabel: 'Tax Impact:',
                        taxAmount: _formatCurrency(taxData.stcgTax),
                        taxColor: AppColor.danger,
                        amountColor: (taxData.grossRealizedStcg ?? 0) < 0
                            ? AppColor.danger
                            : AppColor.textPrimary,
                      ),
                      const SizedBox(height: 12),
                      _buildStatCard(
                        indicatorColor: const Color(0xFF10B981),
                        title: 'NET REALIZED LTCG (12.5%)',
                        amount: _formatCurrency(taxData.netRealizedLtcg),
                        taxLabel: 'Tax Impact:',
                        taxAmount: _formatCurrency(taxData.ltcgTax),
                        taxColor: const Color(0xFF10B981),
                        detail: (taxData.stclSetoffAmount ?? 0) > 0
                            ? '(${_formatCurrency(taxData.grossRealizedLtcg)} Gross LTCG - ${_formatCurrency(taxData.stclSetoffAmount)} ST Loss)'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildDividendCard(taxometerProvider),
                      const SizedBox(height: 12),
                      _buildTotalTaxCard(taxometerProvider),
                      const SizedBox(height: 16),
                      _buildLiabilityMeterCard(taxometerProvider),
                      const SizedBox(height: 16),
                      _buildExemptionCard(taxometerProvider),
                      const SizedBox(height: 16),
                      _buildOptimizationCard(taxometerProvider),
                      const SizedBox(height: 24),
                      Text(
                        '© ${DateTime.now().year} Profit From It. All rights reserved.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColor.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard(TaxometerProvider provider) {
    final financialYears = provider.financialYears;
    final selectedFinancialYear =
        financialYears.contains(provider.selectedFinancialYear)
        ? provider.selectedFinancialYear
        : (financialYears.isNotEmpty ? financialYears.first : null);

    final clientName = (provider.client?.name ?? '').trim();
    final clientCode = (provider.client?.ccode ?? '').trim();

    return _surfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: AppColor.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Live Taxometer',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'LIVE',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: AppColor.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_fyShort(provider.selectedFinancialYear)} Real-time Tax Liability & Optimization Engine',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _selectorBox(
                  label: 'FINANCIAL YEAR',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedFinancialYear,
                      isExpanded: true,
                      hint: Text(
                        'Select FY',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColor.textSecondary,
                        ),
                      ),
                      icon: provider.taxometerLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColor.primary,
                              ),
                            )
                          : const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                            ),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColor.textPrimary,
                      ),
                      items: financialYears
                          .map(
                            (year) => DropdownMenuItem<String>(
                              value: year,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 13,
                                    color: AppColor.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      year,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: provider.taxometerLoading
                          ? null
                          : (value) async {
                              if (value == null) return;

                              await provider.changeFinancialYear(
                                context,
                                value,
                              );
                            },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _selectorBox(
                  label: 'CLIENT ACCOUNT',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: AppColor.textSecondary,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              clientName.isNotEmpty ? clientName : 'My Account',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            if (clientCode.isNotEmpty)
                              Text(
                                '($clientCode)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  color: AppColor.textSecondary,
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
        ],
      ),
    );
  }

  Widget _selectorBox({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 5),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 7,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColor.textSecondary,
            ),
          ),
        ),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required Color indicatorColor,
    required String title,
    required String amount,
    required String taxLabel,
    required String taxAmount,
    required Color taxColor,
    String? detail,
    Color? amountColor,
  }) {
    return _surfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.7,
                    color: AppColor.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: amountColor ?? AppColor.textPrimary,
            ),
          ),
          if (detail != null && detail.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              detail,
              style: GoogleFonts.poppins(
                fontSize: 8,
                color: AppColor.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  taxLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: AppColor.textLight,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: taxColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  taxAmount,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: taxColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDividendCard(TaxometerProvider provider) {
    final taxData = provider.taxData;
    final dividendNote = (taxData?.dividendNote ?? '').trim().isNotEmpty
        ? taxData!.dividendNote!.trim()
        : 'Taxable as per your individual slab rate.';

    return _surfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5CF6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'DIVIDEND (SLAB RATE)',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.7,
                  color: AppColor.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(taxData?.dividend),
            style: GoogleFonts.poppins(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: AppColor.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dividendNote,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: AppColor.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalTaxCard(TaxometerProvider provider) {
    final totalTax = provider.taxData?.totalTax ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -24,
            child: Transform.rotate(
              angle: -0.15,
              child: Icon(
                Icons.currency_rupee_rounded,
                size: 92,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL ESTIMATED ${_fyShort(provider.selectedFinancialYear)} TAX',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: const Color(0xFFBFDBFE),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatCurrency(totalTax),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0x3360A5FA)),
              const SizedBox(height: 9),
              Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 13,
                    color: Color(0xFFBFDBFE),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Before optimization strategies',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: const Color(0xFFDBEAFE),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiabilityMeterCard(TaxometerProvider provider) {
    final taxData = provider.taxData;
    final totalTax = taxData?.totalTax ?? 0;

    // Same ₹5,00,000 display scale used by the website meter.
    final meterProgress = (totalTax / 500000).clamp(0.0, 1.0).toDouble();

    String currentBracket = 'No Tax Due';
    Color currentBracketColor = AppColor.textSecondary;

    if ((taxData?.netRealizedStcg ?? 0) > 0) {
      currentBracket = 'Active STCG';
      currentBracketColor = AppColor.danger;
    } else if ((taxData?.taxableLtcg ?? 0) > 0) {
      currentBracket = 'Active LTCG';
      currentBracketColor = const Color(0xFF10B981);
    }

    return _surfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Liability Meter',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.help_outline_rounded,
                      size: 14,
                      color: AppColor.textSecondary,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Live',
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: AppColor.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 142,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TaxMeterPainter(progress: meterProgress),
                  ),
                ),
                Positioned(
                  bottom: 7,
                  child: Column(
                    children: [
                      Text(
                        _formatCurrency(totalTax),
                        style: GoogleFonts.poppins(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        ),
                      ),
                      Text(
                        'TAX DUE',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: AppColor.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _meterInfoBox(
                  label: 'LTCG Exemption',
                  value: _formatCurrency(taxData?.exemptionLimit),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _meterInfoBox(
                  label: 'Current Bracket',
                  value: currentBracket,
                  valueColor: currentBracketColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meterInfoBox({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 8, color: AppColor.textLight),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColor.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExemptionCard(TaxometerProvider provider) {
    final taxData = provider.taxData;

    final exemptionLimit = taxData?.exemptionLimit ?? 125000;
    final utilizedExemption = taxData?.utilizedExemption ?? 0;
    final remainingExemption = taxData?.remainingExemption ?? 0;

    final exemptionProgress = exemptionLimit > 0
        ? (utilizedExemption / exemptionLimit).clamp(0.0, 1.0).toDouble()
        : 0.0;

    final utilizedPercent = (exemptionProgress * 100).round();
    final remainingPercent = 100 - utilizedPercent;
    final hasRemainingExemption = remainingExemption > 0;

    return _surfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '₹1.25L Exemption Status',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasRemainingExemption
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: hasRemainingExemption
                            ? const Color(0xFF10B981)
                            : AppColor.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      hasRemainingExemption ? 'Available' : 'Utilized',
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: hasRemainingExemption
                            ? const Color(0xFF047857)
                            : const Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(
                const Color(0xFF2563EB),
                'Utilized ($utilizedPercent%)',
              ),
              const SizedBox(width: 14),
              _legendDot(
                const Color(0xFFE2E8F0),
                'Remaining ($remainingPercent%)',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: exemptionProgress,
              minHeight: 9,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _exemptionValue(
                  label: 'Utilized',
                  value: _formatCurrency(utilizedExemption),
                  alignment: CrossAxisAlignment.start,
                  valueColor: AppColor.primary,
                ),
              ),
              Expanded(
                child: _exemptionValue(
                  label: 'Remaining',
                  value: _formatCurrency(remainingExemption),
                  alignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Total annual Section 112A LTCG tax-free limit:',
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    color: AppColor.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatCurrency(exemptionLimit),
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 8,
            color: AppColor.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _exemptionValue({
    required String label,
    required String value,
    required CrossAxisAlignment alignment,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 8, color: AppColor.textLight),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColor.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildOptimizationCard(TaxometerProvider provider) {
    final taxData = provider.taxData;

    final exemptionHarvestAmount = taxData?.exemptionHarvestAmount ?? 0;
    final exemptionSavings = taxData?.exemptionSavings ?? 0;
    final taxLossHarvestAmount = taxData?.taxLossHarvestAmount ?? 0;
    final taxLossSavings = taxData?.taxLossSavings ?? 0;
    final dividend = taxData?.dividend ?? 0;

    final hasExemptionHarvest = exemptionHarvestAmount > 0;
    final hasTaxLossHarvest = taxLossHarvestAmount > 0;
    final hasHighDividend = dividend > 100000;

    final hasOptimization =
        hasExemptionHarvest || hasTaxLossHarvest || hasHighDividend;

    return _surfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 17,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Smart Tax Optimization Actions',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),
                if (provider.taxometerLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColor.primary,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              children: [
                if (hasExemptionHarvest)
                  _optimizationAction(
                    icon: Icons.eco_outlined,
                    iconBackground: const Color(0xFFD1FAE5),
                    iconColor: const Color(0xFF16A34A),
                    title: 'Exemption Harvesting Opportunity',
                    description:
                        'Book ${_formatCurrency(exemptionHarvestAmount)} of unrealized long-term gains to utilize the remaining tax-free limit.',
                    impact:
                        'Potential future tax saving: ${_formatCurrency(exemptionSavings)}',
                  ),
                if (hasExemptionHarvest &&
                    (hasTaxLossHarvest || hasHighDividend))
                  const SizedBox(height: 12),
                if (hasTaxLossHarvest)
                  _optimizationAction(
                    icon: Icons.trending_down_rounded,
                    iconBackground: const Color(0xFFDBEAFE),
                    iconColor: const Color(0xFF2563EB),
                    title: 'Tax-Loss Harvesting Available',
                    description:
                        'Harvest ${_formatCurrency(taxLossHarvestAmount)} of unrealized short-term losses to offset realized STCG.',
                    impact:
                        'Potential current tax reduction: ${_formatCurrency(taxLossSavings)}',
                  ),
                if (hasTaxLossHarvest && hasHighDividend)
                  const SizedBox(height: 12),
                if (hasHighDividend)
                  _optimizationAction(
                    icon: Icons.warning_amber_rounded,
                    iconBackground: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    title: 'High Dividend Tax Burden',
                    description:
                        'Dividend income is ${_formatCurrency(dividend)} and may be taxable at your applicable slab rate.',
                    impact:
                        'Review dividend-heavy positions around ex-dates when planning taxable income.',
                  ),
                if (!hasOptimization) ...[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD1FAE5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 30,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No immediate optimization\nrequired',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'The portfolio is currently operating efficiently based on the latest tax rules.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      height: 1.55,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: provider.taxometerLoading
                      ? null
                      : () async {
                          await provider.refreshTaxometer(context);
                        },
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: Text(
                    'Re-evaluate Taxometer',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.primary,
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _optimizationAction({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String description,
    required String impact,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    height: 1.45,
                    color: AppColor.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  impact,
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D9488),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(num? value) {
    final amount = value ?? 0;
    final negative = amount < 0;
    final rounded = amount.abs().round().toString();

    String formatted;

    if (rounded.length <= 3) {
      formatted = rounded;
    } else {
      final lastThree = rounded.substring(rounded.length - 3);
      var remaining = rounded.substring(0, rounded.length - 3);

      final groups = <String>[];

      while (remaining.length > 2) {
        groups.insert(0, remaining.substring(remaining.length - 2));

        remaining = remaining.substring(0, remaining.length - 2);
      }

      if (remaining.isNotEmpty) {
        groups.insert(0, remaining);
      }

      formatted = '${groups.join(',')},$lastThree';
    }

    return negative ? '₹-$formatted' : '₹$formatted';
  }

  Widget _surfaceCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TaxMeterPainter extends CustomPainter {
  final double progress;

  _TaxMeterPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final safeProgress = progress.clamp(0.0, 1.0);
    final strokeWidth = 16.0;
    final radius = math.min(size.width * 0.32, 82.0);
    final center = Offset(size.width / 2, size.height - 10);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFB000), Color(0xFFFF6B00)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, backgroundPaint);

    canvas.drawArc(rect, math.pi, math.pi * safeProgress, false, progressPaint);

    final tickPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2;

    final tickStart = Offset(center.dx, center.dy - radius - 3);
    final tickEnd = Offset(center.dx, center.dy - radius + 7);
    canvas.drawLine(tickStart, tickEnd, tickPaint);
  }

  @override
  bool shouldRepaint(covariant _TaxMeterPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
