import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:profit_from_it_investors/model/dashboard_response.dart';
import 'package:profit_from_it_investors/provider/client_switch/client_switch_provider.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:provider/provider.dart';

class ClientSelectionBottomSheet extends StatefulWidget {
  const ClientSelectionBottomSheet({super.key});

  @override
  State<ClientSelectionBottomSheet> createState() =>
      _ClientSelectionBottomSheetState();
}

class _ClientSelectionBottomSheetState
    extends State<ClientSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<ClientList> _filteredClients(List<ClientList> clients) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return clients;

    return clients.where((client) {
      final name = (client.name ?? '').trim().toLowerCase();
      final code = (client.ccode ?? '').trim().toLowerCase();
      return name.contains(query) || code.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Consumer<ClientSwitchProvider>(
      builder: (context, provider, child) {
        final isPartner = provider.isPartner;
        final clients = _filteredClients(provider.clientList);

        final sheetTitle = isPartner ? 'Switch Member' : 'Switch User';

        final sheetSubtitle = isPartner
            ? 'Search by client name or client code'
            : 'Search by client name or client code';

        final emptyMessage = isPartner
            ? 'No linked client accounts found.'
            : 'No client accounts found.';

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.82),
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
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    enabled: !provider.isSwitching,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColor.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search name or client code',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColor.textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColor.primary,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _query = '';
                                });
                                _searchFocusNode.requestFocus();
                              },
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColor.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColor.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColor.primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  else if (clients.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 34,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No client found for "${_query.trim()}"',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: clients.length,
                        separatorBuilder: (context, index) {
                          return Divider(height: 1, color: AppColor.divider);
                        },
                        itemBuilder: (context, index) {
                          final client = clients[index];
                          final isSelected = provider.isSelected(client);
                          final clientName = (client.name ?? '').trim();
                          final clientCode = (client.ccode ?? '').trim();
                          final initial = clientName.isNotEmpty
                              ? clientName[0].toUpperCase()
                              : '?';
                          final isMaster =
                              client.id != null &&
                              client.id == provider.masterClientId;

                          final subtitleParts = <String>[];
                          if (clientCode.isNotEmpty) {
                            subtitleParts.add('Client Code: $clientCode');
                          }
                          if (isMaster) {
                            subtitleParts.add('My Account');
                          }

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
                              clientName.isNotEmpty ? clientName : 'Client',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColor.textPrimary,
                              ),
                            ),
                            subtitle: subtitleParts.isNotEmpty
                                ? Text(
                                    subtitleParts.join('  •  '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
