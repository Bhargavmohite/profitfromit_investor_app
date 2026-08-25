import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/provider/family/family_provider.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:provider/provider.dart';

class FamilySelectionBottomSheet extends StatelessWidget {
  const FamilySelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyProvider>(
      builder: (context, familyProvider, child) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(50)),
                ),

                const SizedBox(height: 20),

                Text("Select Family Member", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),

                const SizedBox(height: 20),

                if (familyProvider.familyList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text("No family members found.", style: GoogleFonts.poppins()),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    itemCount: familyProvider.familyList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final family = familyProvider.familyList[index];
                      final isSelected = familyProvider.isSelected(family);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,

                        onTap: () async {
                          if (isSelected) {
                            Navigator.pop(context, false);
                            return;
                          }

                          familyProvider.selectFamily(family);

                          if (context.mounted) {
                            Navigator.pop(context, true);
                          }
                        },

                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColor.primary.withValues(alpha: .12),
                          child: Text(
                            (family.name ?? "").substring(0, 1).toUpperCase(),
                            style: GoogleFonts.poppins(color: AppColor.primary, fontWeight: FontWeight.w700),
                          ),
                        ),

                        title: Text(family.name ?? "", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500)),

                        trailing: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: isSelected ? const Icon(Icons.check_circle, key: ValueKey(true), color: AppColor.primary) : const Icon(Icons.radio_button_unchecked, key: ValueKey(false), color: Colors.grey),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:profit_from_it_investors/provider/family/family_provider.dart';
// import 'package:profit_from_it_investors/provider/home/home_provider.dart';
// import 'package:profit_from_it_investors/utility/app_color.dart';
// import 'package:provider/provider.dart';
//
// class FamilySelectionBottomSheet extends StatelessWidget {
//   const FamilySelectionBottomSheet({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<FamilyProvider>(
//       builder: (context, familyProvider, child) {
//         return SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 50,
//                   height: 5,
//                   decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(50)),
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 Text("Select Family Member", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
//
//                 const SizedBox(height: 20),
//
//                 if (familyProvider.familyList.isEmpty)
//                   Padding(
//                     padding: const EdgeInsets.all(20),
//                     child: Text("No family members found.", style: GoogleFonts.poppins()),
//                   )
//                 else
//                   ListView.separated(
//                     shrinkWrap: true,
//                     itemCount: familyProvider.familyList.length,
//                     separatorBuilder: (_, __) => const Divider(height: 1),
//                     itemBuilder: (context, index) {
//                       final family = familyProvider.familyList[index];
//
//                       final isSelected = familyProvider.isSelected(family);
//
//                       return ListTile(
//                         contentPadding: EdgeInsets.zero,
//                         onTap: () async {
//                           if (isSelected) {
//                             Navigator.pop(context);
//                             return;
//                           }
//
//                           await familyProvider.selectFamily(family);
//
//                           if (context.mounted) {
//                             await context.read<HomeProvider>().refreshDashboard(context);
//                           }
//
//                           if (context.mounted) {
//                             Navigator.pop(context);
//                           }
//                         },
//
//                         leading: CircleAvatar(
//                           radius: 22,
//                           backgroundColor: AppColor.primary.withValues(alpha: 0.12),
//                           child: Text(
//                             family.name!.substring(0, 1).toUpperCase(),
//                             style: GoogleFonts.poppins(color: AppColor.primary, fontWeight: FontWeight.w700),
//                           ),
//                         ),
//
//                         title: Text(family.name ?? "", style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500)),
//
//                         trailing: AnimatedSwitcher(
//                           duration: const Duration(milliseconds: 250),
//                           child: isSelected ? const Icon(Icons.check_circle, color: Colors.green, key: ValueKey(true)) : const Icon(Icons.radio_button_unchecked, color: Colors.grey, key: ValueKey(false)),
//                         ),
//                       );
//                     },
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
