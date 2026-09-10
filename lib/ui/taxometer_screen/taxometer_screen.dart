import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';

class TaxometerScreen extends StatefulWidget {
  const TaxometerScreen({super.key});

  @override
  State<TaxometerScreen> createState() => _TaxometerScreenState();
}

class _TaxometerScreenState extends State<TaxometerScreen> {
  final List<String> _financialYears = const [
    '2026-2027',
    '2025-2026',
    '2024-2025',
    '2023-2024',
  ];

  String _selectedFinancialYear = '2026-2027';

  // ---------------------------------------------------------------------------
  // PHASE 1: UI PREVIEW DATA ONLY
  // These values will be replaced by TaxometerProvider/API data in Phase 2.
  // ---------------------------------------------------------------------------
  static const String _clientName = 'Aakash Ramawat';
  static const String _clientCode = 'PF191';
  static const String _realizedStcg = '₹2,000';
  static const String _stcgTax = '₹400';
  static const String _netRealizedLtcg = '₹13,807';
  static const String _ltcgTax = '₹0';
  static const String _dividend = '₹3,989';
  static const String _totalTax = '₹400';
  static const String _utilizedExemption = '₹13,807';
  static const String _remainingExemption = '₹1,11,193';
  static const double _exemptionProgress = 13807 / 125000;

  String get _fyShort {
    final parts = _selectedFinancialYear.split('-');
    if (parts.length != 2) return _selectedFinancialYear;
    return 'FY${parts.first.substring(2)}-${parts.last.substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildStatCard(
                indicatorColor: AppColor.danger,
                title: 'REALIZED STCG (20%)',
                amount: _realizedStcg,
                taxLabel: 'Tax Impact:',
                taxAmount: _stcgTax,
                taxColor: AppColor.danger,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                indicatorColor: const Color(0xFF10B981),
                title: 'NET REALIZED LTCG (12.5%)',
                amount: _netRealizedLtcg,
                taxLabel: 'Tax Impact:',
                taxAmount: _ltcgTax,
                taxColor: const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              _buildDividendCard(),
              const SizedBox(height: 12),
              _buildTotalTaxCard(),
              const SizedBox(height: 16),
              _buildLiabilityMeterCard(),
              const SizedBox(height: 16),
              _buildExemptionCard(),
              const SizedBox(height: 16),
              _buildOptimizationCard(),
              const SizedBox(height: 24),
              Text(
                '© 2026 Profit From It. All rights reserved.',
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
    );
  }

  Widget _buildHeaderCard() {
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
                      '$_fyShort Real-time Tax Liability & Optimization Engine',
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
                      value: _selectedFinancialYear,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColor.textPrimary,
                      ),
                      items: _financialYears
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
                                  Flexible(child: Text(year)),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedFinancialYear = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _selectorBox(
                  label: 'SELECT CLIENT ACCOUNT',
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
                              _clientName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            Text(
                              '($_clientCode)',
                              maxLines: 1,
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                color: AppColor.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColor.textSecondary,
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

  Widget _selectorBox({
    required String label,
    required Widget child,
  }) {
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
              color: AppColor.textPrimary,
            ),
          ),
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

  Widget _buildDividendCard() {
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
            _dividend,
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
                  'Taxable as per your individual slab rate',
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

  Widget _buildTotalTaxCard() {
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
                'TOTAL ESTIMATED ${_fyShort.replaceFirst('FY', 'FY')} TAX',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: const Color(0xFFBFDBFE),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _totalTax,
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

  Widget _buildLiabilityMeterCard() {
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
                  'Slab 20%',
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
                    painter: _TaxMeterPainter(progress: 0.20),
                  ),
                ),
                Positioned(
                  bottom: 7,
                  child: Column(
                    children: [
                      Text(
                        _totalTax,
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
                  label: 'Threshold 0%',
                  value: '₹0 - ₹1.25L',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _meterInfoBox(
                  label: 'Current Bracket',
                  value: 'Active STCG',
                  valueColor: AppColor.danger,
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
            style: GoogleFonts.poppins(
              fontSize: 8,
              color: AppColor.textLight,
            ),
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

  Widget _buildExemptionCard() {
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
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Available',
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF047857),
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
              _legendDot(const Color(0xFF2563EB), 'Utilized (11%)'),
              const SizedBox(width: 14),
              _legendDot(const Color(0xFFE2E8F0), 'Remaining (89%)'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _exemptionProgress,
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
                  value: _utilizedExemption,
                  alignment: CrossAxisAlignment.start,
                  valueColor: AppColor.primary,
                ),
              ),
              Expanded(
                child: _exemptionValue(
                  label: 'Remaining',
                  value: _remainingExemption,
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
                '₹1,25,000',
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
          style: GoogleFonts.poppins(
            fontSize: 8,
            color: AppColor.textLight,
          ),
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

  Widget _buildOptimizationCard() {
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
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            child: Column(
              children: [
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
                  'The portfolio is currently operating efficiently based on the latest tax rules. Any tax harvesting or loss offsetting opportunities will appear here automatically.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    height: 1.55,
                    color: AppColor.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: Text(
                    'Re-evaluate Ledger',
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

    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      backgroundPaint,
    );

    canvas.drawArc(
      rect,
      math.pi,
      math.pi * safeProgress,
      false,
      progressPaint,
    );

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
