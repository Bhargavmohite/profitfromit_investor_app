import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:profit_from_it_investors/network/http_request.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:profit_from_it_investors/utility/notification_service.dart';

class SupportMessagesScreen extends StatefulWidget {
  final bool nominationRequest;
  final int? initialTicketId;

  const SupportMessagesScreen({
    super.key,
    this.nominationRequest = false,
    this.initialTicketId,
  });

  @override
  State<SupportMessagesScreen> createState() => _SupportMessagesScreenState();
}

class _SupportMessagesScreenState extends State<SupportMessagesScreen> {
  static const int _dailyTicketLimit = 3;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isListPolling = false;
  String? _errorMessage;
  List<_SupportTicket> _tickets = <_SupportTicket>[];
  Timer? _listPollTimer;

  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  bool _initialTicketHandled = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Important for Family / Partner / Readonly Admin switching:
      // the backend stores the same physical device token against the
      // currently active user-id so support-reply pushes reach that client.
      await NotificationService.registerCurrentToken();

      if (mounted) {
        await _loadTickets();
        await _openInitialTicketIfNeeded();
        _startListAutoRefresh();
      }
    });
  }

  void _startListAutoRefresh() {
    _listPollTimer?.cancel();
    _listPollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _pollTicketList(),
    );
  }

  Future<void> _pollTicketList() async {
    if (!mounted || _isLoading || _isRefreshing || _isListPolling) {
      return;
    }

    _isListPolling = true;

    try {
      await _loadTickets(showLoader: false, silent: true);
    } finally {
      _isListPolling = false;
    }
  }

  @override
  void dispose() {
    _listPollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets({
    bool showLoader = true,
    bool silent = false,
  }) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else if (!silent) {
      setState(() => _isRefreshing = true);
    }

    try {
      final response = await httpGet('support-tickets');

      if (!mounted) return;

      if (response == null ||
          response.statusCode < 200 ||
          response.statusCode >= 300) {
        setState(() {
          _errorMessage = 'Unable to load support tickets.';
        });
        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        setState(() {
          _errorMessage = decoded is Map<String, dynamic>
              ? (decoded['message']?.toString() ??
                    'Unable to load support tickets.')
              : 'Unable to load support tickets.';
        });
        return;
      }

      final data = decoded['data'];
      final rawTickets = data is Map<String, dynamic> ? data['tickets'] : null;

      final tickets = <_SupportTicket>[];

      if (rawTickets is List) {
        for (final item in rawTickets) {
          if (item is Map) {
            tickets.add(
              _SupportTicket.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }

      setState(() {
        _tickets = tickets;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Unable to load support tickets. Please check your connection.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!silent) {
            _isRefreshing = false;
          }
        });
      }
    }
  }

  Future<void> _openInitialTicketIfNeeded() async {
    if (_initialTicketHandled || !mounted) {
      return;
    }

    final ticketId = widget.initialTicketId;

    // No notification/deep-link ticket was supplied.
    if (ticketId == null || ticketId <= 0) {
      _initialTicketHandled = true;
      return;
    }

    // Mark it handled before navigation so rebuilds/polling cannot open it twice.
    _initialTicketHandled = true;

    _SupportTicket? matchedTicket;

    for (final ticket in _tickets) {
      if (ticket.id == ticketId) {
        matchedTicket = ticket;
        break;
      }
    }

    if (!mounted) {
      return;
    }

    if (matchedTicket != null) {
      await _openTicket(matchedTicket);
      return;
    }

    // Fallback: the ticket may not be present in the currently loaded list
    // (for example after a notification/deep link). Open it directly by ID.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SupportTicketConversationScreen(
          ticketId: ticketId,
          ticketNo: 'Ticket #$ticketId',
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadTickets(showLoader: false);
  }

  int get _todayTicketCount {
    final now = DateTime.now();

    return _tickets.where((ticket) {
      final rawCreatedAt = ticket.createdAt;

      if (rawCreatedAt == null || rawCreatedAt.trim().isEmpty) {
        return false;
      }

      final parsed = DateTime.tryParse(rawCreatedAt);

      if (parsed == null) {
        return false;
      }

      final created = parsed.toLocal();

      return created.year == now.year &&
          created.month == now.month &&
          created.day == now.day;
    }).length;
  }

  int get _remainingTicketsToday {
    final remaining = _dailyTicketLimit - _todayTicketCount;
    return remaining < 0 ? 0 : remaining;
  }

  bool get _dailyTicketLimitReached => _todayTicketCount >= _dailyTicketLimit;

  Future<void> _showDailyTicketLimitMessage() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 430),
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: .14),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.lock_clock_rounded,
                        color: Color(0xFFEA580C),
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Support Limit Reached',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              height: 1.25,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You have used all $_dailyTicketLimit support tickets available for today.',
                            style: GoogleFonts.poppins(
                              fontSize: 10.8,
                              height: 1.45,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Today\'s usage',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColor.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEDD5),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$_todayTicketCount / $_dailyTicketLimit used',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFC2410C),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: 1,
                          minHeight: 7,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFEA580C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 19,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'New ticket creation will be available again tomorrow. '
                          'You can still open any existing ticket and continue the conversation.',
                          style: GoogleFonts.poppins(
                            fontSize: 10.4,
                            height: 1.5,
                            color: const Color(0xFF1E3A5F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.forum_outlined, size: 18),
                    label: Text(
                      'View Existing Tickets',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openNewTicketForm() async {
    if (!mounted) return;

    // Refresh from the server before checking the daily limit so the user
    // cannot create a 4th ticket from a stale local list.
    await _loadTickets(showLoader: false, silent: true);

    if (!mounted) return;

    if (_dailyTicketLimitReached) {
      await _showDailyTicketLimitMessage();
      return;
    }

    final result = await showModalBottomSheet<_TicketSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF0F172A).withValues(alpha: .42),
      builder: (_) =>
          _NewTicketFormSheet(nominationRequest: widget.nominationRequest),
    );

    if (!mounted || result != _TicketSheetResult.submitted) {
      return;
    }

    await NotificationService.registerCurrentToken();
    await _loadTickets(showLoader: false);

    if (!mounted) return;

    final remaining = _remainingTicketsToday;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            remaining > 0
                ? 'Support ticket submitted. $remaining of $_dailyTicketLimit tickets remaining today.'
                : 'Support ticket submitted. Daily limit of $_dailyTicketLimit tickets reached.',
          ),
        ),
      );
  }

  Future<void> _openTicket(_SupportTicket ticket) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SupportTicketConversationScreen(
          ticketId: ticket.id,
          ticketNo: ticket.ticketNo,
        ),
      ),
    );

    if (!mounted) return;

    // Opening show() marks admin replies as read, and a client reply can
    // change ticket status. Always refresh the list when returning.
    await _loadTickets(showLoader: false);
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF082D59), Color(0xFF0D3CCF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withValues(alpha: .14),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Create a ticket and keep all support replies in one place.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: .78),
                    fontSize: 10.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _dailyTicketLimitReached
                      ? 'Today: $_todayTicketCount / $_dailyTicketLimit used • New tickets available tomorrow'
                      : 'Today: $_todayTicketCount / $_dailyTicketLimit used • $_remainingTicketsToday remaining',
                  style: GoogleFonts.poppins(
                    color: _dailyTicketLimitReached
                        ? const Color(0xFFFFD7A8)
                        : Colors.white.withValues(alpha: .92),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNominationNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.person_add_alt_1_rounded,
            color: AppColor.primary,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'To request nominee addition, tap the + button. Investment and Adding the Nominee will be selected automatically for you.',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                height: 1.45,
                color: AppColor.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabelFor(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'replied':
        return 'Replied';
      case 'closed':
        return 'Closed';
      case 'open':
      default:
        return 'Open';
    }
  }

  List<_SupportTicket> get _visibleTickets {
    final query = _searchController.text.trim().toLowerCase();

    return _tickets.where((ticket) {
      final matchesFilter = switch (_selectedFilter) {
        'unread' => ticket.unreadCount > 0,
        'open' => ticket.status == 'open',
        'in_progress' => ticket.status == 'in_progress',
        'replied' => ticket.status == 'replied',
        'closed' => ticket.status == 'closed',
        _ => true,
      };

      if (!matchesFilter) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final searchable = <String>[
        ticket.ticketNo,
        ticket.title,
        ticket.department,
        ticket.issueType,
        _statusLabelFor(ticket.status),
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  Future<void> _showTicketActions(_SupportTicket ticket) async {
    if (!mounted) return;

    final canMarkUnread = ticket.hasAdminReply && ticket.unreadCount == 0;

    final shouldMarkUnread = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7DEE8),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: AppColor.primary,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ticket.ticketNo,
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ListTile(
                enabled: canMarkUnread,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: canMarkUnread
                        ? const Color(0xFFEEF4FF)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.mark_chat_unread_rounded,
                    size: 20,
                    color: canMarkUnread
                        ? AppColor.primary
                        : AppColor.textLight,
                  ),
                ),
                title: Text(
                  ticket.unreadCount > 0
                      ? 'Already unread'
                      : ticket.hasAdminReply
                      ? 'Mark as unread'
                      : 'No Support Team reply yet',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: canMarkUnread
                        ? AppColor.textPrimary
                        : AppColor.textLight,
                  ),
                ),
                subtitle: canMarkUnread
                    ? Text(
                        'The latest Support Team reply will show as unread again.',
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          color: AppColor.textSecondary,
                        ),
                      )
                    : null,
                onTap: canMarkUnread
                    ? () => Navigator.of(sheetContext).pop(true)
                    : null,
              ),
            ],
          ),
        );
      },
    );

    if (shouldMarkUnread == true) {
      await _markTicketUnread(ticket);
    }
  }

  Future<void> _markTicketUnread(_SupportTicket ticket) async {
    try {
      final response = await httpPost(
        'support-tickets/${ticket.id}/unread',
        <String, dynamic>{},
      );

      if (!mounted) return;

      if (response != null &&
          response.statusCode >= 200 &&
          response.statusCode < 300) {
        await _loadTickets(showLoader: false, silent: true);

        if (!mounted) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Ticket marked as unread.')),
          );
        return;
      }

      String message = 'Unable to mark this ticket as unread.';

      try {
        final decoded = jsonDecode(response?.body ?? '');
        if (decoded is Map<String, dynamic> &&
            decoded['message']?.toString().trim().isNotEmpty == true) {
          message = decoded['message'].toString();
        }
      } catch (_) {}

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to mark this ticket as unread. Please try again.',
            ),
          ),
        );
    }
  }

  Widget _buildSearchAndFilters() {
    const filters = <(String, String)>[
      ('all', 'All'),
      ('unread', 'Unread'),
      ('open', 'Open'),
      ('in_progress', 'In Progress'),
      ('replied', 'Replied'),
      ('closed', 'Closed'),
    ];

    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            color: AppColor.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search ticket number, title or department...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 10.5,
              color: AppColor.textLight,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColor.textSecondary,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColor.textSecondary,
                    ),
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColor.primary, width: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 7),
            itemBuilder: (_, index) {
              final filter = filters[index];
              final selected = _selectedFilter == filter.$1;

              return ChoiceChip(
                selected: selected,
                showCheckmark: false,
                label: Text(filter.$2),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : AppColor.textSecondary,
                ),
                side: BorderSide(
                  color: selected ? AppColor.primary : const Color(0xFFDCE3ED),
                ),
                backgroundColor: Colors.white,
                selectedColor: AppColor.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                onSelected: (_) {
                  setState(() => _selectedFilter = filter.$1);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTicketList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColor.primary),
      );
    }

    if (_errorMessage != null) {
      return _SupportStateCard(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load tickets',
        message: _errorMessage!,
        buttonText: 'Try Again',
        onPressed: () => _loadTickets(),
      );
    }

    if (_tickets.isEmpty) {
      return _SupportStateCard(
        icon: Icons.forum_outlined,
        title: 'No support tickets yet',
        message:
            'Tap the + button to contact the right department. Your conversations and support replies will appear here.',
        buttonText: 'Create your first ticket',
        onPressed: _openNewTicketForm,
      );
    }

    final visibleTickets = _visibleTickets;

    if (visibleTickets.isEmpty) {
      return _SupportStateCard(
        icon: Icons.search_off_rounded,
        title: 'No matching tickets',
        message: 'Try another search term or choose a different ticket filter.',
        buttonText: 'Clear filters',
        onPressed: () {
          _searchController.clear();
          setState(() => _selectedFilter = 'all');
        },
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: visibleTickets.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final ticket = visibleTickets[index];

        return _SupportTicketCard(
          ticket: ticket,
          onTap: () => _openTicket(ticket),
          onLongPress: () => _showTicketActions(ticket),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColor.textPrimary,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          'Support Messages',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColor.textPrimary,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE7ECF3)),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
        ),
        actions: const [SizedBox(width: 8)],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEF1F5)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewTicketForm,
        backgroundColor: _dailyTicketLimitReached
            ? const Color(0xFF94A3B8)
            : AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tooltip: _dailyTicketLimitReached
            ? 'Daily ticket limit reached'
            : 'Raise support ticket',
        child: Icon(
          _dailyTicketLimitReached
              ? Icons.lock_clock_rounded
              : Icons.add_rounded,
          size: 28,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 88),
          child: Column(
            children: [
              _buildHero(),
              if (widget.nominationRequest) ...[
                const SizedBox(height: 12),
                _buildNominationNote(),
              ],
              const SizedBox(height: 14),
              _buildSearchAndFilters(),
              const SizedBox(height: 12),
              Expanded(child: _buildTicketList()),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTicket {
  final int id;
  final String ticketNo;
  final String title;
  final String department;
  final String issueType;
  final String status;
  final int unreadCount;
  final bool hasAdminReply;
  final String? lastMessageAt;
  final String? createdAt;

  const _SupportTicket({
    required this.id,
    required this.ticketNo,
    required this.title,
    required this.department,
    required this.issueType,
    required this.status,
    required this.unreadCount,
    required this.hasAdminReply,
    required this.lastMessageAt,
    required this.createdAt,
  });

  factory _SupportTicket.fromJson(Map<String, dynamic> json) {
    return _SupportTicket(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      ticketNo: json['ticket_no']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      issueType: json['issue_type']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '') ?? 0,
      hasAdminReply:
          json['has_admin_reply'] == true ||
          json['has_admin_reply']?.toString() == '1',
      lastMessageAt: json['last_message_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class _SupportMessage {
  final int id;
  final String senderType;
  final String message;
  final bool hasAttachment;
  final String? attachmentName;
  final int? attachmentSize;
  final String? createdAt;

  const _SupportMessage({
    required this.id,
    required this.senderType,
    required this.message,
    required this.hasAttachment,
    required this.attachmentName,
    required this.attachmentSize,
    required this.createdAt,
  });

  bool get isAdmin => senderType.trim().toLowerCase() == 'admin';

  factory _SupportMessage.fromJson(Map<String, dynamic> json) {
    return _SupportMessage(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      senderType: json['sender_type']?.toString() ?? 'client',
      message: json['message']?.toString() ?? '',
      hasAttachment:
          json['has_attachment'] == true ||
          json['has_attachment']?.toString() == '1',
      attachmentName: json['attachment_name']?.toString(),
      attachmentSize: int.tryParse(json['attachment_size']?.toString() ?? ''),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class _SupportStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const _SupportStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: .08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: AppColor.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  height: 1.55,
                  color: AppColor.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColor.primary,
                  side: const BorderSide(color: Color(0xFFC7D2FE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  buttonText,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTicketCard extends StatelessWidget {
  final _SupportTicket ticket;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SupportTicketCard({
    required this.ticket,
    required this.onTap,
    required this.onLongPress,
  });

  Color _statusColor() {
    switch (ticket.status) {
      case 'in_progress':
        return const Color(0xFFD97706);
      case 'replied':
        return const Color(0xFF15803D);
      case 'closed':
        return const Color(0xFF64748B);
      case 'open':
      default:
        return AppColor.primary;
    }
  }

  Color _statusBackground() {
    switch (ticket.status) {
      case 'in_progress':
        return const Color(0xFFFFF7ED);
      case 'replied':
        return const Color(0xFFECFDF3);
      case 'closed':
        return const Color(0xFFF1F5F9);
      case 'open':
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  String _statusLabel() {
    switch (ticket.status) {
      case 'in_progress':
        return 'In Progress';
      case 'replied':
        return 'Replied';
      case 'closed':
        return 'Closed';
      case 'open':
      default:
        return 'Open';
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';

    try {
      return DateFormat(
        'dd MMM • hh:mm a',
      ).format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final date = _formatDate(ticket.lastMessageAt ?? ticket.createdAt);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: ticket.unreadCount > 0
                  ? AppColor.primary.withValues(alpha: .35)
                  : const Color(0xFFE7ECF3),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: .025),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  ticket.unreadCount > 0
                      ? Icons.mark_chat_unread_rounded
                      : Icons.chat_bubble_outline_rounded,
                  color: statusColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            ticket.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary,
                            ),
                          ),
                        ),
                        if (ticket.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${ticket.unreadCount} new',
                              style: GoogleFonts.poppins(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      ticket.ticketNo,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColor.primary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${ticket.department} • ${ticket.issueType}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              color: AppColor.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _statusBackground(),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(),
                            style: GoogleFonts.poppins(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (date.isNotEmpty)
                          Text(
                            date,
                            style: GoogleFonts.poppins(
                              fontSize: 8.5,
                              color: AppColor.textLight,
                            ),
                          ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColor.textLight,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTicketConversationScreen extends StatefulWidget {
  final int ticketId;
  final String ticketNo;

  const _SupportTicketConversationScreen({
    required this.ticketId,
    required this.ticketNo,
  });

  @override
  State<_SupportTicketConversationScreen> createState() =>
      _SupportTicketConversationScreenState();
}

class _SupportTicketConversationScreenState
    extends State<_SupportTicketConversationScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSending = false;
  bool _isConversationPolling = false;
  String? _errorMessage;
  _SupportTicket? _ticket;
  List<_SupportMessage> _messages = <_SupportMessage>[];
  Timer? _conversationPollTimer;

  @override
  void initState() {
    super.initState();
    _loadConversation().then((_) {
      if (mounted) {
        _startConversationAutoRefresh();
      }
    });
  }

  void _startConversationAutoRefresh() {
    _conversationPollTimer?.cancel();
    _conversationPollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollConversation(),
    );
  }

  Future<void> _pollConversation() async {
    if (!mounted || _isLoading || _isSending || _isConversationPolling) {
      return;
    }

    _isConversationPolling = true;

    try {
      await _loadConversation(showLoader: false, silent: true);
    } finally {
      _isConversationPolling = false;
    }
  }

  @override
  void dispose() {
    _conversationPollTimer?.cancel();
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation({
    bool showLoader = true,
    bool silent = false,
  }) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await httpGet('support-tickets/${widget.ticketId}');

      if (!mounted) return;

      if (response == null ||
          response.statusCode < 200 ||
          response.statusCode >= 300) {
        setState(() {
          _errorMessage = 'Unable to load this support conversation.';
        });
        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        setState(() {
          _errorMessage = decoded is Map<String, dynamic>
              ? (decoded['message']?.toString() ??
                    'Unable to load this support conversation.')
              : 'Unable to load this support conversation.';
        });
        return;
      }

      final data = decoded['data'];

      if (data is! Map<String, dynamic>) {
        setState(() {
          _errorMessage = 'Unable to read this support conversation.';
        });
        return;
      }

      _SupportTicket? ticket;
      final rawTicket = data['ticket'];

      if (rawTicket is Map) {
        ticket = _SupportTicket.fromJson(Map<String, dynamic>.from(rawTicket));
      }

      final previousMessageCount = _messages.length;

      final messages = <_SupportMessage>[];
      final rawMessages = data['messages'];

      if (rawMessages is List) {
        for (final item in rawMessages) {
          if (item is Map) {
            messages.add(
              _SupportMessage.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }

      final hasNewMessage = messages.length > previousMessageCount;

      setState(() {
        _ticket = ticket;
        _messages = messages;
        _errorMessage = null;
      });

      if (!silent || hasNewMessage) {
        _scrollToBottom();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Unable to load this support conversation. Please try again.';
      });
    } finally {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      } else if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendReply() async {
    if (_isSending) return;

    final message = _replyController.text.trim();

    if (message.isEmpty) {
      return;
    }

    setState(() => _isSending = true);
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final response = await httpPost(
        'support-tickets/${widget.ticketId}/reply',
        {'message': message},
      );

      if (!mounted) return;

      if (response != null &&
          response.statusCode >= 200 &&
          response.statusCode < 300) {
        _replyController.clear();
        await _loadConversation(showLoader: false);

        if (!mounted) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Reply sent successfully.')),
          );
        return;
      }

      String error = 'Unable to send your reply.';

      try {
        final decoded = jsonDecode(response?.body ?? '');
        if (decoded is Map<String, dynamic> &&
            decoded['message']?.toString().trim().isNotEmpty == true) {
          error = decoded['message'].toString();
        }
      } catch (_) {}

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to send your reply. Please check your connection.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';

    try {
      return DateFormat(
        'dd MMM yyyy • hh:mm a',
      ).format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw;
    }
  }

  String _formatAttachmentSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';

    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildMessage(_SupportMessage message) {
    final isAdmin = message.isAdmin;
    final date = _formatDate(message.createdAt);

    return Align(
      alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .78,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: isAdmin
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                isAdmin ? 'Support Team' : 'You',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textLight,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: isAdmin ? Colors.white : const Color(0xFF173D70),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isAdmin ? 5 : 15),
                  topRight: Radius.circular(isAdmin ? 15 : 5),
                  bottomLeft: const Radius.circular(15),
                  bottomRight: const Radius.circular(15),
                ),
                border: isAdmin
                    ? Border.all(color: const Color(0xFFE1E7EF))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.message.trim().isNotEmpty)
                    Text(
                      message.message,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        height: 1.5,
                        color: isAdmin ? AppColor.textPrimary : Colors.white,
                      ),
                    ),
                  if (message.hasAttachment) ...[
                    if (message.message.trim().isNotEmpty)
                      const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? const Color(0xFFF8FAFC)
                            : Colors.white.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_file_rounded,
                            size: 17,
                            color: isAdmin ? AppColor.primary : Colors.white,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              message.attachmentName ?? 'Attachment',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: isAdmin
                                    ? AppColor.textPrimary
                                    : Colors.white,
                              ),
                            ),
                          ),
                          finalSizeWidget(message, isAdmin),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (date.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    color: AppColor.textLight,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget finalSizeWidget(_SupportMessage message, bool isAdmin) {
    final size = _formatAttachmentSize(message.attachmentSize);

    if (size.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 7),
      child: Text(
        size,
        style: GoogleFonts.poppins(
          fontSize: 8,
          color: isAdmin ? AppColor.textSecondary : Colors.white70,
        ),
      ),
    );
  }

  Widget _buildConversation() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColor.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _SupportStateCard(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load conversation',
            message: _errorMessage!,
            buttonText: 'Try Again',
            onPressed: () => _loadConversation(),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColor.primary,
      onRefresh: () => _loadConversation(showLoader: false),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
        itemCount: _messages.length,
        itemBuilder: (_, index) => _buildMessage(_messages[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;
    final isClosed = ticket?.status == 'closed';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: .5,
        backgroundColor: Colors.white,
        foregroundColor: AppColor.textPrimary,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket?.title ?? 'Support Conversation',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
            Text(
              ticket?.ticketNo ?? widget.ticketNo,
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColor.primary,
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEF1F5)),
        ),
      ),
      body: Column(
        children: [
          if (ticket != null)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${ticket.department} • ${ticket.issueType}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        color: AppColor.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ConversationStatusChip(status: ticket.status),
                ],
              ),
            ),
          Expanded(child: _buildConversation()),
          if (!_isLoading && ticket != null)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE7ECF3))),
                ),
                child: isClosed
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          'This ticket is closed. Create a new ticket if you need more help.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.newline,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: AppColor.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Write a reply...',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColor.textLight,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 11,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFDCE3ED),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFDCE3ED),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: AppColor.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 46,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _isSending ? null : _sendReply,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: AppColor.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded, size: 20),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConversationStatusChip extends StatelessWidget {
  final String status;

  const _ConversationStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color background;
    String label;

    switch (status) {
      case 'in_progress':
        color = const Color(0xFFD97706);
        background = const Color(0xFFFFF7ED);
        label = 'In Progress';
        break;
      case 'replied':
        color = const Color(0xFF15803D);
        background = const Color(0xFFECFDF3);
        label = 'Replied';
        break;
      case 'closed':
        color = const Color(0xFF64748B);
        background = const Color(0xFFF1F5F9);
        label = 'Closed';
        break;
      case 'open':
      default:
        color = AppColor.primary;
        background = const Color(0xFFEFF6FF);
        label = 'Open';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

enum _TicketSheetResult { submitted }

class _NewTicketFormSheet extends StatefulWidget {
  final bool nominationRequest;

  const _NewTicketFormSheet({required this.nominationRequest});

  @override
  State<_NewTicketFormSheet> createState() => _NewTicketFormSheetState();
}

class _NewTicketFormSheetState extends State<_NewTicketFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  String? _department;
  String? _issueType;
  PlatformFile? _selectedAttachment;
  int? _selectedAttachmentSize;
  bool _isPickingAttachment = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.nominationRequest ? 'Nominee Addition Request' : '',
    );
    _descriptionController = TextEditingController();
    _department = widget.nominationRequest ? 'Investment' : null;
    _issueType = widget.nominationRequest ? 'Adding the Nominee' : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<String> _issueTypesFor(String? department) {
    switch (department) {
      case 'Technical Issue':
        return const [
          'Login / OTP Issue',
          'Data Not Loading',
          'App Crash / Error',
          'Connectivity / Server Issue',
        ];
      case 'App Related Issue':
        return const [
          'UI / Display Issue',
          'Navigation Issue',
          'Notification Issue',
          'Feature Request',
        ];
      case 'Investment':
        return const ['Adding the Nominee'];
      case 'Other':
        return const ['Other Query'];
      default:
        return const [];
    }
  }

  void _closeSheet() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  Future<void> _pickAttachment() async {
    if (_isPickingAttachment) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isPickingAttachment = true);

    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const [
          'jpg',
          'jpeg',
          'png',
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
        ],
      );

      if (!mounted || result == null || result.files.isEmpty) return;

      final PlatformFile file = result.files.single;
      final int fileSize = file.size;
      const maxAttachmentBytes = 10 * 1024 * 1024;

      if (fileSize > maxAttachmentBytes) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Please select a file smaller than 10 MB.'),
            ),
          );
        return;
      }

      setState(() {
        _selectedAttachment = file;
        _selectedAttachmentSize = fileSize;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to open file picker. Please try again.'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isPickingAttachment = false);
      }
    }
  }

  void _removeAttachment() {
    setState(() {
      _selectedAttachment = null;
      _selectedAttachmentSize = null;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final department = _department;
    final issueType = _issueType;

    if (department == null || issueType == null) {
      return;
    }

    final attachment = _selectedAttachment;

    if (attachment != null &&
        (attachment.path == null || attachment.path!.trim().isEmpty) &&
        (attachment.bytes == null || attachment.bytes!.isEmpty)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to access the selected attachment. Please select it again.',
            ),
          ),
        );
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSubmitting = true);

    try {
      final response = await httpMultipartPost(
        'support-tickets',
        {
          'title': _titleController.text.trim(),
          'department': department,
          'issue_type': issueType,
          'description': _descriptionController.text.trim(),
        },
        fileField: attachment != null ? 'attachment' : null,
        filePath: attachment?.path,
        fileName: attachment?.name,
        fileBytes: attachment?.bytes,
      );

      if (!mounted) return;

      if (response != null &&
          response.statusCode >= 200 &&
          response.statusCode < 300) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pop(_TicketSheetResult.submitted);
        return;
      }

      final message = _readApiError(response?.statusCode, response?.body ?? '');

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to submit the ticket. Please check your connection and try again.',
            ),
          ),
        );
    } finally {
      if (mounted && _isSubmitting) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _readApiError(int? statusCode, String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];

        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }

        final errors = decoded['errors'];

        if (errors is Map) {
          for (final value in errors.values) {
            if (value is List && value.isNotEmpty) {
              return value.first.toString();
            }

            if (value is String && value.trim().isNotEmpty) {
              return value.trim();
            }
          }
        }
      }
    } catch (_) {
      // Fall back to the user-friendly messages below.
    }

    if (statusCode == 413) {
      return 'The attachment is too large. Maximum file size is 10 MB.';
    }

    if (statusCode == 422) {
      return 'Please check the ticket details and try again.';
    }

    return 'Unable to submit the support ticket. Please try again.';
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColor.textPrimary,
      ),
    );
  }

  TextStyle _inputTextStyle() {
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColor.textPrimary,
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    bool alignIconTop = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 11.5, color: AppColor.textLight),
      prefixIcon: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 9,
          top: alignIconTop ? 13 : 0,
          bottom: alignIconTop ? 50 : 0,
        ),
        child: Icon(icon, size: 19, color: AppColor.textSecondary),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 42),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFDCE3ED)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFDCE3ED)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColor.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColor.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColor.danger, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final issueOptions = _issueTypesFor(_department);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .90,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9E0EA),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.add_comment_rounded,
                      color: AppColor.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Support Ticket',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColor.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tell us what you need help with.',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting ? null : _closeSheet,
                    icon: const Icon(Icons.close_rounded),
                    color: AppColor.textSecondary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEF1F5)),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Title'),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _titleController,
                        textInputAction: TextInputAction.next,
                        style: _inputTextStyle(),
                        decoration: _inputDecoration(
                          hint: 'Enter ticket title',
                          icon: Icons.title_rounded,
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel('Department'),
                      const SizedBox(height: 7),
                      DropdownButtonFormField<String>(
                        value: _department,
                        isExpanded: true,
                        style: _inputTextStyle(),
                        decoration: _inputDecoration(
                          hint: 'Select department',
                          icon: Icons.apartment_rounded,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Technical Issue',
                            child: Text('Technical Issue'),
                          ),
                          DropdownMenuItem(
                            value: 'App Related Issue',
                            child: Text('App Related Issue'),
                          ),
                          DropdownMenuItem(
                            value: 'Investment',
                            child: Text('Investment'),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _department = value;
                            _issueType = null;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a department' : null,
                      ),
                      if (_department != null) ...[
                        const SizedBox(height: 16),
                        _fieldLabel('Issue Type'),
                        const SizedBox(height: 7),
                        DropdownButtonFormField<String>(
                          key: ValueKey<String?>(_department),
                          value: issueOptions.contains(_issueType)
                              ? _issueType
                              : null,
                          isExpanded: true,
                          style: _inputTextStyle(),
                          decoration: _inputDecoration(
                            hint: 'Select issue type',
                            icon: Icons.tune_rounded,
                          ),
                          items: issueOptions
                              .map(
                                (option) => DropdownMenuItem<String>(
                                  value: option,
                                  child: Text(option),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _issueType = value);
                          },
                          validator: (value) => value == null
                              ? 'Please select an issue type'
                              : null,
                        ),
                      ],
                      const SizedBox(height: 16),
                      _fieldLabel('Description'),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 4,
                        maxLines: 6,
                        textInputAction: TextInputAction.newline,
                        style: _inputTextStyle(),
                        decoration: _inputDecoration(
                          hint: 'Describe your query or issue...',
                          icon: Icons.notes_rounded,
                          alignIconTop: true,
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel('Attachment'),
                      const SizedBox(height: 7),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: (_isPickingAttachment || _isSubmitting)
                            ? null
                            : _pickAttachment,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedAttachment != null
                                  ? AppColor.primary.withValues(alpha: .45)
                                  : const Color(0xFFDCE3ED),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE7ECF3),
                                  ),
                                ),
                                child: _isPickingAttachment
                                    ? const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColor.primary,
                                        ),
                                      )
                                    : Icon(
                                        _selectedAttachment != null
                                            ? Icons.insert_drive_file_rounded
                                            : Icons.attach_file_rounded,
                                        size: 20,
                                        color: AppColor.primary,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedAttachment?.name ??
                                          'Add Attachment',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedAttachment != null
                                          ? _formatFileSize(
                                              _selectedAttachmentSize ?? 0,
                                            )
                                          : 'Image, PDF, Word or Excel • Max 10 MB',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9.5,
                                        color: AppColor.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedAttachment != null)
                                IconButton(
                                  tooltip: 'Remove attachment',
                                  onPressed: _isSubmitting
                                      ? null
                                      : _removeAttachment,
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: AppColor.danger,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 20,
                                  color: AppColor.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColor.primary
                                .withValues(alpha: .60),
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            _isSubmitting ? 'Submitting...' : 'Submit Ticket',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
