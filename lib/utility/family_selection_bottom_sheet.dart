import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/provider/family/family_provider.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:provider/provider.dart';

class FamilySelectionBottomSheet extends StatelessWidget {
  const FamilySelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Consumer<FamilyProvider>(
      builder: (context, familyProvider, child) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Bottom sheet can never become
              // taller than 75% of the screen.
              maxHeight: screenHeight * 0.75,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ============================
                  // DRAG HANDLE
                  // ============================

                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ============================
                  // TITLE
                  // ============================
                  Text(
                    "Select Family Member",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ============================
                  // EMPTY FAMILY LIST
                  // ============================
                  if (familyProvider.familyList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "No family members found.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    )
                  // ============================
                  // FAMILY MEMBER LIST
                  // ============================
                  else
                    Flexible(
                      child: ListView.separated(
                        // IMPORTANT:
                        // The list scrolls instead
                        // of increasing bottom
                        // sheet height endlessly.
                        shrinkWrap: true,

                        physics: const ClampingScrollPhysics(),

                        padding: EdgeInsets.zero,

                        itemCount: familyProvider.familyList.length,

                        separatorBuilder: (context, index) {
                          return Divider(height: 1, color: AppColor.divider);
                        },

                        itemBuilder: (context, index) {
                          final family = familyProvider.familyList[index];

                          final isSelected = familyProvider.isSelected(family);

                          final familyName = (family.name ?? "").trim();

                          // Prevent substring()
                          // crash when name is empty.
                          final initial = familyName.isNotEmpty
                              ? familyName[0].toUpperCase()
                              : "?";

                          return ListTile(
                            contentPadding: EdgeInsets.zero,

                            minVerticalPadding: 8,

                            onTap: () {
                              // Already selected.
                              if (isSelected) {
                                Navigator.pop(context, false);

                                return;
                              }

                              // Update selected
                              // family member.
                              familyProvider.selectFamily(family);

                              if (context.mounted) {
                                Navigator.pop(context, true);
                              }
                            },

                            // ====================
                            // AVATAR
                            // ====================
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColor.primary.withValues(
                                alpha: 0.12,
                              ),
                              child: Text(
                                initial,
                                style: GoogleFonts.poppins(
                                  color: AppColor.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),

                            // ====================
                            // FAMILY NAME
                            // ====================
                            title: Text(
                              familyName.isNotEmpty
                                  ? familyName
                                  : "Family Member",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColor.textPrimary,
                              ),
                            ),

                            // ====================
                            // SELECTED ICON
                            // ====================
                            trailing: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      key: ValueKey(true),
                                      color: AppColor.primary,
                                    )
                                  : const Icon(
                                      Icons.radio_button_unchecked,
                                      key: ValueKey(false),
                                      color: Colors.grey,
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
