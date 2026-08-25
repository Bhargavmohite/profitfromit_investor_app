import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/ui/holdings_screen/holding_sort_type.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';

class HoldingsSortBottomSheet extends StatefulWidget {
  final HoldingSortType? selectedSort;
  final ValueChanged<HoldingSortType> onSelected;
  final VoidCallback onDone;
  final VoidCallback onClear;

  const HoldingsSortBottomSheet({super.key, required this.selectedSort, required this.onSelected, required this.onDone, required this.onClear});

  @override
  State<HoldingsSortBottomSheet> createState() => _HoldingsSortBottomSheetState();
}

class _HoldingsSortBottomSheetState extends State<HoldingsSortBottomSheet> {
  late HoldingSortType? _tempSelectedSort;

  @override
  void initState() {
    super.initState();
    _tempSelectedSort = widget.selectedSort;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sort by',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColor.textPrimary),
            ),

            const SizedBox(height: 20),

            _sortRow(title: 'Alphabetically', leftLabel: 'A → Z', rightLabel: 'Z → A', leftType: HoldingSortType.alphabeticalAsc, rightType: HoldingSortType.alphabeticalDesc),
            _sortRow(title: 'Percent (%)', leftLabel: 'High → Low', rightLabel: 'Low → High', leftType: HoldingSortType.percentHighToLow, rightType: HoldingSortType.percentLowToHigh),
            // _sortRow(title: 'Price (₹)', leftLabel: 'High → Low', rightLabel: 'Low → High', leftType: HoldingSortType.priceHighToLow, rightType: HoldingSortType.priceLowToHigh),
            _sortRow(title: 'Profit (₹)', leftLabel: 'High → Low', rightLabel: 'Low → High', leftType: HoldingSortType.profitHighToLow, rightType: HoldingSortType.profitLowToHigh),
            _sortRow(title: 'Invested (₹)', leftLabel: 'High → Low', rightLabel: 'Low → High', leftType: HoldingSortType.investedHighToLow, rightType: HoldingSortType.investedLowToHigh),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onClear();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Clear', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_tempSelectedSort != null) {
                        widget.onSelected(_tempSelectedSort!);
                      }
                      widget.onDone();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColor.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortRow({required String title, required String leftLabel, required String rightLabel, required HoldingSortType leftType, required HoldingSortType rightType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: _sortButton(
              text: leftLabel,
              isSelected: _tempSelectedSort == leftType,
              onTap: () {
                setState(() {
                  _tempSelectedSort = leftType;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _sortButton(
              text: rightLabel,
              isSelected: _tempSelectedSort == rightType,
              onTap: () {
                setState(() {
                  _tempSelectedSort = rightType;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortButton({required String text, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColor.primary.withValues(alpha: 0.08) : Colors.white,
          border: Border.all(color: isSelected ? AppColor.primary : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppColor.primary : AppColor.textPrimary),
        ),
      ),
    );
  }
}
