import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/model/watchlist_response.dart';
import 'package:profit_from_it_investors/provider/watchlist_provider/watchlist_provider.dart';
import 'package:profit_from_it_investors/ui/stock_detail_screen/stock_detail_screen.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:provider/provider.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  TopMoverType _selectedType = TopMoverType.gainers;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WatchlistProvider>().getTopMovers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Top Movers',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
        ),
        centerTitle: false,
      ),
      body: Consumer<WatchlistProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.watchlistResponse == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final gainers = provider.watchlistResponse?.data?.gainers ?? [];
          final losers = provider.watchlistResponse?.data?.losers ?? [];
          final highestYielding = provider.watchlistResponse?.data?.highestYieldingAssets ?? [];
          final lowestYielding = provider.watchlistResponse?.data?.lowestYieldingAssets ?? [];

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: Column(
              children: [
                _MoverToggle(
                  selectedType: _selectedType,
                  onChanged: (type) {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                ),

                Expanded(
                  child: _MoverListPage(
                    items: switch (_selectedType) {
                      TopMoverType.gainers => gainers,
                      TopMoverType.losers => losers,
                      TopMoverType.highestYielding => highestYielding,
                      TopMoverType.lowestYielding => lowestYielding,
                    },
                    type: _selectedType,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MoverToggle extends StatelessWidget {
  final TopMoverType selectedType;
  final ValueChanged<TopMoverType> onChanged;

  const _MoverToggle({required this.selectedType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _ToggleButton(title: 'Top Gainers', isSelected: selectedType == TopMoverType.gainers, activeColor: AppColor.gainText, onTap: () => onChanged(TopMoverType.gainers)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ToggleButton(title: 'Top Losers', isSelected: selectedType == TopMoverType.losers, activeColor: AppColor.lossText, onTap: () => onChanged(TopMoverType.losers)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ToggleButton(title: 'Highest Yielding', isSelected: selectedType == TopMoverType.highestYielding, activeColor: Colors.blue, onTap: () => onChanged(TopMoverType.highestYielding)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ToggleButton(title: 'Lowest Yielding', isSelected: selectedType == TopMoverType.lowestYielding, activeColor: Colors.orange, onTap: () => onChanged(TopMoverType.lowestYielding)),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleButton({required this.title, required this.isSelected, required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        height: 80,
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? activeColor : AppColor.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? activeColor : AppColor.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

// class _MoverListPage extends StatelessWidget {
//   final List<Gainer> items;
//   final TopMoverType type;
//
//   const _MoverListPage({required this.items, required this.type});
//
//   @override
//   Widget build(BuildContext context) {
//     if (items.isEmpty) {
//       return Center(child: Text("No data available", style: GoogleFonts.poppins()));
//     }
//
//     final bool isYielding = type == TopMoverType.highestYielding || type == TopMoverType.lowestYielding;
//
//     return Column(
//       children: [
//         Container(
//           padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 6),
//           child: Row(
//             children: [
//               Expanded(
//                 flex: 4,
//                 child: Text(
//                   "COMPANY",
//                   style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
//                 ),
//               ),
//
//               if (isYielding)
//                 Expanded(
//                   flex: 2,
//                   child: Text(
//                     "AVG COST",
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
//                   ),
//                 ),
//
//               Expanded(
//                 flex: 2,
//                 child: Text(
//                   "CMP",
//                   textAlign: TextAlign.center,
//                   style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
//                 ),
//               ),
//
//               Expanded(
//                 flex: 2,
//                 child: Text(
//                   isYielding ? "RETURN %" : "CHANGE %",
//                   textAlign: TextAlign.end,
//                   style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//         Expanded(
//           child: ListView.builder(
//             padding: EdgeInsets.zero,
//             itemCount: items.length,
//             itemBuilder: (context, index) {
//               return _MoverTile(item: items[index], type: type);
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class _MoverTile extends StatelessWidget {
//   final Gainer item;
//   final TopMoverType type;
//
//   const _MoverTile({required this.item, required this.type});
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isYielding = type == TopMoverType.highestYielding || type == TopMoverType.lowestYielding;
//
//     final bool isPositive = type == TopMoverType.gainers || type == TopMoverType.highestYielding;
//
//     final Color chipColor = isPositive ? AppColor.gainText : AppColor.lossText;
//
//     final IconData icon = isPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded;
//
//     final String cmp = item.cmp ?? "--";
//     final String avgCost = item.avgCost ?? "--";
//
//     final double value = isYielding ? (item.gainerReturn ?? 0).toDouble() : (item.changePercent ?? 0).toDouble();
//
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: AppColor.divider),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 8, offset: const Offset(0, 2))],
//       ),
//       child: Row(
//         children: [
//
//           /// COMPANY
//           Expanded(
//             flex: 4,
//             child: Text(
//               item.company ?? "--",
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: GoogleFonts.poppins(fontSize: 11, color: AppColor.textPrimary),
//             ),
//           ),
//
//           /// AVG COST (Only Yielding)
//           if (isYielding)
//             Expanded(
//               flex: 2,
//               child: Text(
//                 avgCost,
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.poppins(fontSize: 11, color: AppColor.textSecondary),
//               ),
//             ),
//
//           /// CMP
//           Expanded(
//             flex: 2,
//             child: Text(
//               cmp,
//               textAlign: TextAlign.center,
//               style: GoogleFonts.poppins(fontSize: 11, color: AppColor.textPrimary),
//             ),
//           ),
//
//           /// CHANGE %
//           Expanded(
//             flex: 2,
//             child: Align(
//               alignment: Alignment.centerRight,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
//                 decoration: BoxDecoration(color: chipColor.withOpacity(.10), borderRadius: BorderRadius.circular(8)),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(icon, color: chipColor, size: 14),
//                     Text(
//                       "${value.abs().toStringAsFixed(2)}%",
//                       style: GoogleFonts.poppins(fontSize: 11, color: chipColor),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


class _MoverListPage extends StatelessWidget {
  final List<Gainer> items;
  final TopMoverType type;

  const _MoverListPage({required this.items, required this.type});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text('No data available', style: GoogleFonts.poppins(fontSize: 14, color: AppColor.textSecondary)),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 74, color: AppColor.divider),
      itemBuilder: (_, i) => InkWell(
        onTap: () {
          nextRoute(MaterialPageRoute(builder: (context) {
            return StockDetailScreen(stockId: items[i].id.toString());
          },));
        },
        child: _MoverTile(item: items[i], type: type),
      ),
    );
  }
}

class _MoverTile extends StatelessWidget {
  final Gainer item;
  final TopMoverType type;

  const _MoverTile({required this.item, required this.type});

  @override
  Widget build(BuildContext context) {
    final Color changeColor;
    final IconData changeIcon;

    switch (type) {
      case TopMoverType.gainers:
        changeColor = AppColor.gainText;
        changeIcon = Icons.arrow_drop_up_rounded;
        break;
      case TopMoverType.highestYielding:
        changeColor = AppColor.primary;
        changeIcon = Icons.arrow_drop_up_rounded;
        break;
      case TopMoverType.losers:
        changeColor = AppColor.lossText;
        changeIcon = Icons.arrow_drop_down_rounded;
        break;
      case TopMoverType.lowestYielding:
        changeColor = AppColor.warning;
        changeIcon = Icons.arrow_drop_down_rounded;
        break;
    }

    final bool isYielding = type == TopMoverType.highestYielding || type == TopMoverType.lowestYielding;

    // final String subtitleValue = isYielding ? (item.avgCost ?? '0') : (item.cmp ?? '0');

    final double trailingValue = isYielding ? (item.gainerReturn ?? 0).toDouble() : (item.changePercent ?? 0).toDouble();

    final String trailingText = isYielding ? '${trailingValue.abs().toStringAsFixed(2)}%' : '${trailingValue.abs().toStringAsFixed(2)}%';

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: getAvatarColor(item.id ?? '').withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Text(
            getInitials(item.company ?? ''),
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: getAvatarColor(item.id ?? '')),
          ),
        ),
      ),
      title: Text(
        item.company ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.textPrimary),
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(isYielding)...[
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AVG. COST",
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textLight),
                  ),
                  Text(
                    (item.avgCost ?? '0'),
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CPM",
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textLight),
                ),
                Text(
                  (item.cmp ?? '0'),
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: changeColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(changeIcon, size: 16, color: changeColor),
            Text(
              trailingText,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: changeColor),
            ),
          ],
        ),
      ),
    );
  }

  String getInitials(String company) {
    final words = company.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return '';
    if (words.length == 1) {
      return words.first.length >= 2 ? words.first.substring(0, 2).toUpperCase() : words.first.toUpperCase();
    }
    if (words.length == 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
    return (words[0][0] + words[1][0] + words[2][0]).toUpperCase();
  }

  Color getAvatarColor(String seed) {
    const colors = [Color(0xFF1A5FFF), Color(0xFFF57F17), Color(0xFF2E7D32), Color(0xFF00897B), Color(0xFF4527A0), Color(0xFF0288D1), Color(0xFF6D4C41), Color(0xFFE53935), Color(0xFFAB47BC), Color(0xFF37474F)];
    return colors[seed.hashCode.abs() % colors.length];
  }
}
