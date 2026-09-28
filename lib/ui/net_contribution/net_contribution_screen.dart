import 'dart:typed_data';

import 'package:excel_community/excel_community.dart' as xls;
import 'package:file_saver/file_saver.dart';
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

  bool _isExporting = false;

  Future<void> _exportNetContributionExcel({DateTimeRange? dateRange}) async {
    final provider = context.read<NetContributionProvider>();
    final data = provider.data;

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Net contribution data is not available.'),
        ),
      );
      return;
    }

    final payIn = _filterEntries(provider.payIn, dateRange);

    final payOut = _filterEntries(provider.payOut, dateRange);

    final buyBack = _filterEntries(provider.buyback, dateRange);

    final hasAnyData =
        payIn.isNotEmpty || payOut.isNotEmpty || buyBack.isNotEmpty;

    if (!hasAnyData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dateRange == null
                ? 'No net contribution data available to export.'
                : 'No Pay In, Pay Out or Buy Back data found for the selected date range.',
          ),
        ),
      );
      return;
    }

    if (_isExporting) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final payInTotal = payIn.fold<double>(
        0,
        (total, entry) => total + (entry.amount ?? 0),
      );

      final payOutTotal = payOut.fold<double>(
        0,
        (total, entry) => total + (entry.amount ?? 0),
      );

      final buyBackTotal = buyBack.fold<double>(
        0,
        (total, entry) => total + (entry.amount ?? 0),
      );

      final netContribution = payInTotal - payOutTotal - buyBackTotal;

      final excel = xls.Excel.createExcel();

      final defaultSheet = excel.getDefaultSheet();
      const summarySheetName = 'Summary';

      if (defaultSheet != null && defaultSheet != summarySheetName) {
        excel.rename(defaultSheet, summarySheetName);
      }

      excel.setDefaultSheet(summarySheetName);

      final summary = excel[summarySheetName];
      final payInSheet = excel['Pay In'];
      final payOutSheet = excel['Pay Out'];
      final buyBackSheet = excel['Buy Back'];

      final headerStyle = xls.CellStyle(
        backgroundColorHex: xls.ExcelColor.blue900,
        fontColorHex: xls.ExcelColor.white,
        bold: true,
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
      );

      final labelStyle = xls.CellStyle(bold: true);

      // ============================================================
      // SUMMARY SHEET
      // ============================================================
      summary.appendRow([xls.TextCellValue('Net Contribution Summary')]);

      summary
              .cell(xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
              .cellStyle =
          headerStyle;

      summary.appendRow([
        xls.TextCellValue('Client Name'),
        xls.TextCellValue((data.activeClientName ?? '-').trim()),
      ]);

      summary.appendRow([
        xls.TextCellValue('Total Net Contribution'),
        xls.DoubleCellValue(netContribution),
      ]);

      summary.appendRow([
        xls.TextCellValue('Total Pay In'),
        xls.DoubleCellValue(payInTotal),
      ]);

      summary.appendRow([
        xls.TextCellValue('Total Pay Out'),
        xls.DoubleCellValue(payOutTotal),
      ]);

      summary.appendRow([
        xls.TextCellValue('Total Buy Back'),
        xls.DoubleCellValue(buyBackTotal),
      ]);

      for (var row = 1; row <= 5; row++) {
        summary
                .cell(
                  xls.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
                )
                .cellStyle =
            labelStyle;
      }

      summary.setColumnWidth(0, 28);
      summary.setColumnWidth(1, 24);

      // ============================================================
      // PAY IN / PAY OUT / BUY BACK SHEETS
      // ============================================================
      _writeContributionSheet(
        sheet: payInSheet,
        entries: payIn,
        headerStyle: headerStyle,
        totalLabel: 'Total Pay In',
        totalAmount: payInTotal,
      );

      _writeContributionSheet(
        sheet: payOutSheet,
        entries: payOut,
        headerStyle: headerStyle,
        totalLabel: 'Total Pay Out',
        totalAmount: payOutTotal,
      );

      _writeContributionSheet(
        sheet: buyBackSheet,
        entries: buyBack,
        headerStyle: headerStyle,
        totalLabel: 'Total Buy Back',
        totalAmount: buyBackTotal,
      );

      final encoded = excel.encode();

      if (encoded == null || encoded.isEmpty) {
        throw Exception('Unable to generate Excel file.');
      }

      final clientName = (data.activeClientName ?? 'Client').trim().replaceAll(
        RegExp(r'[^A-Za-z0-9_-]+'),
        '_',
      );

      final now = DateTime.now();

      final exportDate =
          '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';

      final periodName = dateRange == null
          ? 'Since_Inception'
          : '${_fileDate(dateRange.start)}_to_${_fileDate(dateRange.end)}';

      final fileName =
          'Net_Contribution_'
          '${clientName.isEmpty ? "Client" : clientName}_'
          '${periodName}_'
          '$exportDate';

      final savedPath = await FileSaver.instance.saveAs(
        name: fileName,
        bytes: Uint8List.fromList(encoded),
        fileExtension: 'xlsx',
        includeExtension: true,
        mimeType: MimeType.microsoftExcel,
        dialogTitle: 'Export Net Contribution',
      );

      if (!mounted) {
        return;
      }

      if (savedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Excel export cancelled.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Net Contribution Excel exported successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to export Excel: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _showExportPeriodDialog() async {
    if (_isExporting) {
      return;
    }

    final selectedOption = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .36),
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 390),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .10),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.file_download_outlined,
                        size: 20,
                        color: AppColor.primary,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Export Net Contribution',
                              maxLines: 1,
                              style: GoogleFonts.poppins(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                color: AppColor.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose the period for your Excel export.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(
                          Icons.close_rounded,
                          size: 19,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE7ECF3)),
                  ),
                  child: Column(
                    children: [
                      _ExportOptionCard(
                        icon: Icons.history_rounded,
                        title: 'Since Inception',
                        subtitle: 'Complete contribution history',
                        onTap: () {
                          Navigator.of(dialogContext).pop('since');
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFE7ECF3),
                        ),
                      ),
                      _ExportOptionCard(
                        icon: Icons.date_range_outlined,
                        title: 'Select Date Range',
                        subtitle: 'Choose From Date and To Date',
                        onTap: () {
                          Navigator.of(dialogContext).pop('range');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedOption == null) {
      return;
    }

    if (selectedOption == 'since') {
      await _exportNetContributionExcel();
      return;
    }

    final now = DateTime.now();

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1990, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      ),
      helpText: 'Select Net Contribution Export Period',
      saveText: 'EXPORT',
      confirmText: 'EXPORT',
      cancelText: 'CANCEL',
    );

    if (!mounted || pickedRange == null) {
      return;
    }

    await _exportNetContributionExcel(dateRange: pickedRange);
  }

  List<ContributionEntry> _filterEntries(
    List<ContributionEntry> entries,
    DateTimeRange? dateRange,
  ) {
    if (dateRange == null) {
      return List<ContributionEntry>.from(entries);
    }

    final fromDate = DateTime(
      dateRange.start.year,
      dateRange.start.month,
      dateRange.start.day,
    );

    final toDate = DateTime(
      dateRange.end.year,
      dateRange.end.month,
      dateRange.end.day,
      23,
      59,
      59,
    );

    return entries.where((entry) {
      final entryDate = _parseDate(entry.date);

      if (entryDate == null) {
        return false;
      }

      return !entryDate.isBefore(fromDate) && !entryDate.isAfter(toDate);
    }).toList();
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(value.trim());
    } catch (_) {
      return null;
    }
  }

  String _fileDate(DateTime date) {
    return '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _writeContributionSheet({
    required xls.Sheet sheet,
    required List<ContributionEntry> entries,
    required xls.CellStyle headerStyle,
    required String totalLabel,
    required double totalAmount,
  }) {
    sheet.appendRow([
      xls.TextCellValue('Date'),
      xls.TextCellValue('Amount'),
      xls.TextCellValue('Narration'),
    ]);

    for (var column = 0; column < 3; column++) {
      sheet
              .cell(
                xls.CellIndex.indexByColumnRow(
                  columnIndex: column,
                  rowIndex: 0,
                ),
              )
              .cellStyle =
          headerStyle;
    }

    sheet.setRowHeight(0, 24);

    sheet.setColumnWidth(0, 18);
    sheet.setColumnWidth(1, 20);
    sheet.setColumnWidth(2, 46);

    for (final entry in entries) {
      final displayDate = (entry.displayDate ?? entry.date ?? '-').trim();

      final narration = (entry.narration ?? '').trim();

      sheet.appendRow([
        xls.TextCellValue(displayDate.isEmpty ? '-' : displayDate),
        xls.DoubleCellValue(entry.amount ?? 0),
        xls.TextCellValue(narration.isEmpty ? '-' : narration),
      ]);
    }

    sheet.appendRow([
      xls.TextCellValue(totalLabel),
      xls.DoubleCellValue(totalAmount),
      xls.TextCellValue(''),
    ]);

    final totalRowIndex = entries.length + 1;

    final totalStyle = xls.CellStyle(bold: true);

    sheet
            .cell(
              xls.CellIndex.indexByColumnRow(
                columnIndex: 0,
                rowIndex: totalRowIndex,
              ),
            )
            .cellStyle =
        totalStyle;

    sheet
            .cell(
              xls.CellIndex.indexByColumnRow(
                columnIndex: 1,
                rowIndex: totalRowIndex,
              ),
            )
            .cellStyle =
        totalStyle;
  }

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

    // On smaller phones the summary + tabs can leave too little height
    // for the transaction table. Give the table section its own bounded
    // height and allow the whole page to scroll.
    final contributionListHeight = (MediaQuery.sizeOf(context).height * 0.42)
        .clamp(280.0, 420.0)
        .toDouble();

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
        actions: [
          Tooltip(
            message: 'Export Excel',
            child: IconButton(
              onPressed: provider.isLoading || _isExporting
                  ? null
                  : _showExportPeriodDialog,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_download_outlined, size: 23),
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 6),
        ],
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

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            child: SizedBox(
                              height: contributionListHeight,
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

class _ExportOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColor.primary, size: 18),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF8A97A8),
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
      height: 42,
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
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
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
