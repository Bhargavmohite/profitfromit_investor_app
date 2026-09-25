import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/provider/client_switch/client_switch_provider.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:provider/provider.dart';

class ClientSelectionBottomSheet extends StatelessWidget {
  const ClientSelectionBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Consumer<ClientSwitchProvider>(
      builder: (context, provider, child) {
        final isPartner = provider.isPartner;

        final sheetTitle = isPartner ? 'Switch Member' : 'Switch User';

        final sheetSubtitle = isPartner
            ? 'Select one of your linked client accounts to view'
            : 'Select the client account you want to view';

        final emptyMessage = isPartner
            ? 'No linked client accounts found.'
            : 'No client accounts found.';

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    sheetTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sheetSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (provider.clientList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: provider.clientList.length,
                        separatorBuilder: (context, index) {
                          return Divider(height: 1, color: AppColor.divider);
                        },
                        itemBuilder: (context, index) {
                          final client = provider.clientList[index];
                          final isSelected = provider.isSelected(client);
                          final clientName = (client.name ?? "").trim();
                          final initial = clientName.isNotEmpty
                              ? clientName[0].toUpperCase()
                              : "?";
                          final isMaster =
                              client.id != null &&
                              client.id == provider.masterClientId;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            minVerticalPadding: 8,
                            enabled: !provider.isSwitching,
                            onTap: () async {
                              if (isSelected || provider.isSwitching) {
                                Navigator.pop(context, false);
                                return;
                              }

                              final changed = await provider.selectClient(
                                client,
                              );

                              if (changed && context.mounted) {
                                Navigator.pop(context, true);
                              }
                            },
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
                            title: Text(
                              clientName.isNotEmpty ? clientName : "Client",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            subtitle: isMaster
                                ? Text(
                                    "My Account",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColor.textSecondary,
                                    ),
                                  )
                                : null,
                            trailing:
                                provider.isSwitching &&
                                    client.id == provider.switchingClientId
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColor.primary,
                                    ),
                                  )
                                : AnimatedSwitcher(
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
