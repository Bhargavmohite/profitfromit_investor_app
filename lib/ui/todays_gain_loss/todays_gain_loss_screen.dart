import 'dart:async';
import 'package:profit_from_it_investors/utility/app_activity_route_aware.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:profit_from_it_investors/model/dashboard_response.dart';
import 'package:profit_from_it_investors/provider/home/home_provider.dart';
import 'package:profit_from_it_investors/ui/stock_detail_screen/stock_detail_screen.dart';
import 'package:provider/provider.dart';

/// Drill-down for the Home chart's Today's Gain/Loss tile.
/// Uses the same Dashboard calculation as the tile (PortfolioController logic),
/// rather than independently recalculating prices on the device.
class TodaysGainLossScreen extends StatefulWidget {
  const TodaysGainLossScreen({super.key});

  @override
  State<TodaysGainLossScreen> createState() => _TodaysGainLossScreenState();
}

enum _MovementFilter { all, gainers, losers }

class _TodaysGainLossScreenState extends State<TodaysGainLossScreen>
    with WidgetsBindingObserver, AppActivityRouteAware<TodaysGainLossScreen> {
  @override
  String get activityScreenKey => 'todays_gain_loss';

  static const _navy = Color(0xFF0C2448);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _positive = Color(0xFF07966E);
  static const _negative = Color(0xFFDC485A);
  static const _canvas = Color(0xFFF5F8FC);

  static final _amount = NumberFormat('#,##0.00', 'en_IN');
  static final _quantity = NumberFormat('#,##0.##', 'en_IN');

  final TextEditingController _search = TextEditingController();
  _MovementFilter _filter = _MovementFilter.all;
  Timer? _autoRefreshTimer;
  bool _refreshInProgress = false;
  bool _appInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appInForeground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    // Refresh only while this page is visible. Keep existing data, table
    // scroll position, search text and selected filter during polling.
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshIfVisible(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
    if (_appInForeground) _refreshIfVisible();
  }

  void _refreshIfVisible() {
    if (!mounted ||
        !_appInForeground ||
        ModalRoute.of(context)?.isCurrent != true ||
        _refreshInProgress) {
      return;
    }
    unawaited(_loadLatest(silentErrors: true));
  }

  // Skip overlapping requests if the API takes longer than one second.
  // Silent polling preserves the latest good data when connectivity drops.
  Future<void> _loadLatest({bool silentErrors = false}) async {
    if (_refreshInProgress || !mounted) return;
    _refreshInProgress = true;
    try {
      await context.read<HomeProvider>().getDashboard(
        context,
        isRefresh: true,
        silentErrors: silentErrors,
      );
    } finally {
      _refreshInProgress = false;
    }
  }

  Future<void> _refresh() => _loadLatest();

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  double _parseCurrency(String? value) {
    final normalized = (value ?? '').replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  String _rupees(double value, {bool signed = false}) {
    final sign = value < 0 ? '−' : (signed && value > 0 ? '+' : '');
    return '$sign₹${_amount.format(value.abs())}';
  }

  String _percent(double value) =>
      '${value > 0
          ? '+'
          : value < 0
          ? '−'
          : ''}${value.abs().toStringAsFixed(2)}%';

  Color _movementColor(double value) => value > 0
      ? _positive
      : value < 0
      ? _negative
      : _muted;

  TextStyle _type(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = _ink,
  }) => GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color);

  Widget _metric(String label, String value, {required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE5EBF3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: _muted),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: _type(10, color: _muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: _type(18, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _filterButton(String label, _MovementFilter value) {
    final active = _filter == value;
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: active ? _navy : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: active ? _navy : const Color(0xFFE1E8F0)),
        ),
        child: Text(
          label,
          style: _type(
            11,
            weight: FontWeight.w600,
            color: active ? Colors.white : _muted,
          ),
        ),
      ),
    );
  }

  // Fixed column widths keep numeric cells aligned for a genuine table.
  // The table can scroll horizontally on narrow phones without squeezing text.
  static const double _tableWidth = 606;
  static const double _nameWidth = 172;
  static const double _cmpWidth = 116;
  static const double _qtyWidth = 72;
  static const double _percentWidth = 108;
  static const double _pnlWidth = 138;

  Widget _cell(
    String value,
    double width, {
    bool right = false,
    Color color = _ink,
    bool strong = false,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: right ? TextAlign.right : TextAlign.left,
          style: _type(
            strong ? 12 : 11,
            weight: strong ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String value, double width, {bool right = false}) =>
      SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            value,
            textAlign: right ? TextAlign.right : TextAlign.left,
            maxLines: 1,
            style: _type(
              10,
              color: const Color(0xFF506279),
              weight: FontWeight.w700,
            ),
          ),
        ),
      );

  Widget _tableHeader() => Container(
    color: const Color(0xFFEFF4FA),
    padding: const EdgeInsets.symmetric(vertical: 15),
    child: Row(
      children: [
        _headerCell('NSE Symbol', _nameWidth),
        _headerCell('CMP', _cmpWidth, right: true),
        _headerCell('Qty', _qtyWidth, right: true),
        _headerCell('1D Change', _percentWidth, right: true),
        _headerCell('Day P&L', _pnlWidth, right: true),
      ],
    ),
  );

  Widget _stockRow(DailyGainHolding row, int index) {
    return Material(
      color: index.isEven ? Colors.white : const Color(0xFFFAFCFF),
      child: InkWell(
        onTap: row.isin.isEmpty
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StockDetailScreen(stockId: row.isin),
                ),
              ),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF0F3F7))),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: _nameWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.nseSymbol.isEmpty ? row.isin : row.nseSymbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _type(12, weight: FontWeight.w700),
                      ),
                      if (row.companyName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          row.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _type(9, color: _muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _cell(
                row.cmp > 0 ? _rupees(row.cmp) : '—',
                _cmpWidth,
                right: true,
              ),
              _cell(_quantity.format(row.quantity), _qtyWidth, right: true),
              SizedBox(
                width: _percentWidth,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _movementColor(
                          row.dayChangePercent,
                        ).withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        _percent(row.dayChangePercent),
                        style: _type(
                          10,
                          weight: FontWeight.w700,
                          color: _movementColor(row.dayChangePercent),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _cell(
                _rupees(row.dayPnl, signed: true),
                _pnlWidth,
                color: _movementColor(row.dayPnl),
                right: true,
                strong: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Today’s Gain/Loss',
          style: _type(18, weight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh prices',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, _) {
          final data = provider.dashboardData;
          final holdings = data?.todayGainHoldings;
          final query = _search.text.trim().toLowerCase();
          final visible = (holdings ?? <DailyGainHolding>[]).where((row) {
            if (_filter == _MovementFilter.gainers &&
                row.dayChangePercent <= 0) {
              return false;
            }
            if (_filter == _MovementFilter.losers &&
                row.dayChangePercent >= 0) {
              return false;
            }
            return query.isEmpty ||
                row.nseSymbol.toLowerCase().contains(query) ||
                row.companyName.toLowerCase().contains(query) ||
                row.isin.toLowerCase().contains(query);
          }).toList();

          final gainers =
              holdings?.where((row) => row.dayChangePercent > 0).length ?? 0;
          final losers =
              holdings?.where((row) => row.dayChangePercent < 0).length ?? 0;
          final todayPnl = _parseCurrency(data?.todaysGainLoss);
          final positive = todayPnl >= 0;
          final pnlColor = positive
              ? const Color(0xFF77F0C4)
              : const Color(0xFFFFB3B8);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(21),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF071D3E), Color(0xFF164A91)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _navy.withValues(alpha: .16),
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
                          const Icon(
                            Icons.show_chart_rounded,
                            color: Color(0xFFB2D1FB),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PORTFOLIO • TODAY',
                            style: _type(
                              10,
                              color: const Color(0xFFB2D1FB),
                              weight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          if (provider.dashboardLoading)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _rupees(todayPnl, signed: true),
                          style: _type(
                            29,
                            color: pnlColor,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Net gain / loss across your holdings',
                        style: _type(11, color: const Color(0xFFD0E2F8)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            positive
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 17,
                            color: pnlColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _percent(data?.todaysGainLossPercentage ?? 0),
                            style: _type(
                              12,
                              color: pnlColor,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Portfolio day return',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _type(10, color: const Color(0xFFB2D1FB)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _metric(
                      'Holdings',
                      '${holdings?.length ?? 0}',
                      icon: Icons.view_list_rounded,
                    ),
                    const SizedBox(width: 9),
                    _metric(
                      'Gainers',
                      '$gainers',
                      icon: Icons.trending_up_rounded,
                    ),
                    const SizedBox(width: 9),
                    _metric(
                      'Losers',
                      '$losers',
                      icon: Icons.trending_down_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Company Performance',
                        style: _type(16, weight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${visible.length} stocks',
                      style: _type(11, color: _muted),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Daily price movement and position contribution',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _type(11, color: _muted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.circle, color: _positive, size: 7),
                    const SizedBox(width: 5),
                    Text(
                      'LIVE · 1s',
                      style: _type(
                        10,
                        color: _positive,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFE4EAF2)),
                  ),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    style: _type(12),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _muted,
                        size: 19,
                      ),
                      hintText: 'Search NSE symbol or company',
                      hintStyle: _type(11, color: _muted),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterButton('All Holdings', _MovementFilter.all),
                      const SizedBox(width: 7),
                      _filterButton('Gainers', _MovementFilter.gainers),
                      const SizedBox(width: 7),
                      _filterButton('Losers', _MovementFilter.losers),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE3EAF2)),
                    boxShadow: [
                      BoxShadow(
                        color: _navy.withValues(alpha: .035),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (holdings == null) ...[
                        const SizedBox(height: 35),
                        const Icon(
                          Icons.sync_problem_rounded,
                          color: _muted,
                          size: 28,
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Text(
                            'Company breakdown is not available yet. '
                            'Update the Dashboard API on the server and refresh.',
                            textAlign: TextAlign.center,
                            style: _type(12, color: _muted),
                          ),
                        ),
                        const SizedBox(height: 35),
                      ] else if (visible.isEmpty) ...[
                        const SizedBox(height: 35),
                        const Icon(
                          Icons.search_off_rounded,
                          color: _muted,
                          size: 28,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No matching holdings',
                          style: _type(12, color: _muted),
                        ),
                        const SizedBox(height: 35),
                      ] else ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: _tableWidth,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _tableHeader(),
                                  for (int i = 0; i < visible.length; i++)
                                    _stockRow(visible[i], i),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(Icons.swipe_rounded, size: 16, color: _muted),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Swipe table sideways to see all columns. Tap a row for Stock Detail.',
                        style: _type(10, color: _muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
