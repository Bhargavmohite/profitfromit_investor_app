import 'dart:typed_data';

import 'package:excel_community/excel_community.dart' as xls;
import 'package:file_saver/file_saver.dart';
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
  bool _isExporting = false;

  Future<void> _exportDividendExcel({DateTimeRange? dateRange}) async {
    final provider = context.read<DividendProvider>();

    final dividends = dateRange == null
        ? List<DividendEntry>.from(provider.dividends)
        : provider.dividends.where((entry) {
            final entryDate = _parseDate(entry.date);

            if (entryDate == null) {
              return false;
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

            return !entryDate.isBefore(fromDate) && !entryDate.isAfter(toDate);
          }).toList();

    if (dividends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dateRange == null
                ? 'No dividend data available to export.'
                : 'No dividend data found for the selected date range.',
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
      final excel = xls.Excel.createExcel();

      // Reuse the default sheet and give it a clear professional name.
      final defaultSheet = excel.getDefaultSheet();
      const sheetName = 'Dividend Income';

      if (defaultSheet != null && defaultSheet != sheetName) {
        excel.rename(defaultSheet, sheetName);
      }

      final sheet = excel[sheetName];
      excel.setDefaultSheet(sheetName);

      // --------------------------------------------------------------
      // HEADER
      // --------------------------------------------------------------
      sheet.appendRow([
        xls.TextCellValue('Date'),
        xls.TextCellValue('Company Name'),
        xls.TextCellValue('Dividend / Share'),
        xls.TextCellValue('Qty'),
        xls.TextCellValue('Total Dividend'),
      ]);

      final headerStyle = xls.CellStyle(
        backgroundColorHex: xls.ExcelColor.blue900,
        fontColorHex: xls.ExcelColor.white,
        bold: true,
        horizontalAlign: xls.HorizontalAlign.Center,
        verticalAlign: xls.VerticalAlign.Center,
      );

      for (var column = 0; column < 5; column++) {
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

      // Readable Excel widths.
      sheet.setColumnWidth(0, 16); // Date
      sheet.setColumnWidth(1, 34); // Company Name
      sheet.setColumnWidth(2, 19); // Dividend / Share
      sheet.setColumnWidth(3, 12); // Qty
      sheet.setColumnWidth(4, 20); // Total Dividend

      // --------------------------------------------------------------
      // WHOLE DIVIDEND DATA
      // --------------------------------------------------------------
      for (final entry in dividends) {
        final displayDate = (entry.displayDate ?? entry.date ?? '-').trim();

        final companyName = (entry.companyName ?? '-').trim();

        sheet.appendRow([
          xls.TextCellValue(displayDate.isEmpty ? '-' : displayDate),
          xls.TextCellValue(companyName.isEmpty ? '-' : companyName),
          xls.DoubleCellValue(entry.perShareDividend ?? 0),
          xls.DoubleCellValue(entry.quantity ?? 0),
          xls.DoubleCellValue(entry.totalDividend ?? 0),
        ]);
      }

      final encoded = excel.encode();

      if (encoded == null || encoded.isEmpty) {
        throw Exception('Unable to generate Excel file.');
      }

      final clientName = (provider.data?.activeClientName ?? 'Client')
          .trim()
          .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');

      final now = DateTime.now();
      final exportDate =
          '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';

      final periodName = dateRange == null
          ? 'Since_Inception'
          : '${_fileDate(dateRange.start)}_to_${_fileDate(dateRange.end)}';

      final fileName =
          'Dividend_Income_${clientName.isEmpty ? "Client" : clientName}_${periodName}_$exportDate';

      final savedPath = await FileSaver.instance.saveAs(
        name: fileName,
        bytes: Uint8List.fromList(encoded),
        fileExtension: 'xlsx',
        includeExtension: true,
        mimeType: MimeType.microsoftExcel,
        dialogTitle: 'Export Dividend Income',
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
        const SnackBar(content: Text('Dividend Excel exported successfully.')),
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
                              'Export Dividend Income',
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
                        subtitle: 'Complete dividend history',
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
      await _exportDividendExcel();
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
      helpText: 'Select Dividend Export Period',
      saveText: 'EXPORT',
      confirmText: 'EXPORT',
      cancelText: 'CANCEL',
    );

    if (!mounted || pickedRange == null) {
      return;
    }

    await _exportDividendExcel(dateRange: pickedRange);
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
