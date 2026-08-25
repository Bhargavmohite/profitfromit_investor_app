import 'package:flutter/material.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/style.dart';

class SelectionBottomSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) itemText;
  final Function(T) onSelect;

  const SelectionBottomSheet({super.key, required this.title, required this.items, required this.itemText, required this.onSelect});

  @override
  State<SelectionBottomSheet<T>> createState() => _SelectionBottomSheetState<T>();
}

class _SelectionBottomSheetState<T> extends State<SelectionBottomSheet<T>> {
  final TextEditingController _searchController = TextEditingController();

  late List<T> filteredItems;

  @override
  void initState() {
    super.initState();
    filteredItems = widget.items;
  }

  void _filterItems(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        filteredItems = widget.items;
      } else {
        filteredItems = widget.items.where((item) => widget.itemText(item).toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _filterItems("");
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.black,
            child: Row(
              children: [
                Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 40,
              child: TextFormField(
                controller: _searchController,
                onChanged: _filterItems,
                style: medium,
                decoration: InputDecoration(
                  hintText: "Search...",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.close, size: 18), onPressed: _clearSearch) : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(child: Text("No results found"))
                : ListView.separated(
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];

                      return ListTile(
                        title: Text(widget.itemText(item), style: medium.copyWith(color: AppColor.black)),
                        onTap: () {
                          widget.onSelect(item);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:profit_from_it_investors/utility/app_color.dart';
// import 'package:profit_from_it_investors/utility/style.dart';
//
// class SelectionBottomSheet<T> extends StatelessWidget {
//   final String title;
//   final List<T> items;
//   final String Function(T) itemText;
//   final Function(T) onSelect;
//
//   const SelectionBottomSheet({super.key, required this.title, required this.items, required this.itemText, required this.onSelect});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 420,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       child: Column(
//         children: [
//           Container(
//             height: 56,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             color: Colors.black,
//             child: Row(
//               children: [
//                 Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
//                 const Spacer(),
//                 GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: const Icon(Icons.close, color: Colors.white),
//                 ),
//               ],
//             ),
//           ),
//
//           Expanded(
//             child: ListView.separated(
//               itemCount: items.length,
//               separatorBuilder: (_, __) => const Divider(height: 1),
//               itemBuilder: (context, index) {
//                 final item = items[index];
//
//                 return ListTile(
//                   title: Text(itemText(item), style: medium.copyWith(color: AppColor.black)),
//                   onTap: () {
//                     onSelect(item);
//                     Navigator.pop(context);
//                   },
//                 );
//               },
//             ),
//           ),
//           // Expanded(
//           //   child: GridView.builder(
//           //     padding: EdgeInsets.zero,
//           //     itemCount: items.length,
//           //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.4),
//           //     itemBuilder: (context, index) {
//           //       final item = items[index];
//           //       return GestureDetector(
//           //         onTap: () {
//           //           onSelect(item);
//           //           Navigator.pop(context);
//           //         },
//           //         child: Container(
//           //           decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
//           //           child: Center(child: Text(itemText(item), style: const TextStyle(fontSize: 16))),
//           //         ),
//           //       );
//           //     },
//           //   ),
//           // ),
//         ],
//       ),
//     );
//   }
// }
