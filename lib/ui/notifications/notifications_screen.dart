import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:profit_from_it_investors/model/app_notification_response.dart';
import 'package:profit_from_it_investors/provider/notification_provider/notification_provider.dart';
import 'package:profit_from_it_investors/utility/app_color.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Set<int> _selectedIds = <int>{};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppNotificationProvider>().getNotifications();
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(_selectedIds.clear);
  }

  void _toggleSelectAll(List<AppNotificationItem> notifications) {
    setState(() {
      final allIds = notifications.map((item) => item.id).where((id) => id > 0);
      final allSelected = notifications.isNotEmpty &&
          allIds.every((id) => _selectedIds.contains(id));

      if (allSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(allIds);
      }
    });
  }

  Future<void> _markSelectedAsRead() async {
    if (_selectedIds.isEmpty) return;

    final success = await context
        .read<AppNotificationProvider>()
        .markAsRead(_selectedIds);

    if (!mounted) return;

    if (success) {
      _clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected notifications marked as read.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppNotificationProvider>(
      builder: (context, provider, _) {
        final notifications = provider.notifications;
        final allSelected = notifications.isNotEmpty &&
            notifications
                .map((item) => item.id)
                .where((id) => id > 0)
                .every((id) => _selectedIds.contains(id));

        return Scaffold(
          backgroundColor: AppColor.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            foregroundColor: AppColor.textPrimary,
            leading: _isSelectionMode
                ? IconButton(
                    tooltip: 'Cancel selection',
                    onPressed: _clearSelection,
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
            title: _isSelectionMode
                ? Text(
                    '${_selectedIds.length} selected',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (provider.unreadCount > 0)
                        Text(
                          '${provider.unreadCount} unread',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColor.textSecondary,
                          ),
                        ),
                    ],
                  ),
            actions: _isSelectionMode
                ? [
                    TextButton(
                      onPressed: notifications.isEmpty
                          ? null
                          : () => _toggleSelectAll(notifications),
                      child: Text(allSelected ? 'Clear all' : 'Select all'),
                    ),
                    const SizedBox(width: 4),
                  ]
                : [
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: provider.isLoading
                          ? null
                          : () {
                              provider.getNotifications(showLoader: false);
                            },
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
          ),
          body: _buildBody(provider),
          bottomNavigationBar: _isSelectionMode
              ? SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: AppColor.divider),
                      ),
                    ),
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed:
                            provider.isMarkingRead ? null : _markSelectedAsRead,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: provider.isMarkingRead
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.done_all_rounded),
                        label: Text(
                          provider.isMarkingRead
                              ? 'Marking as read...'
                              : 'Mark as Read (${_selectedIds.length})',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(AppNotificationProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await provider.getNotifications(showLoader: false);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
            const Icon(
              Icons.notifications_none_rounded,
              size: 58,
              color: AppColor.textLight,
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'No notifications yet',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Your recent portfolio and corporate-action notifications will appear here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColor.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
          await provider.getNotifications(showLoader: false);
        },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: provider.notifications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final notification = provider.notifications[index];
          final selected = _selectedIds.contains(notification.id);

          return _NotificationTile(
            notification: notification,
            selected: selected,
            selectionMode: _isSelectionMode,
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(notification.id);
              }
            },
            onLongPress: () => _toggleSelection(notification.id),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotificationItem notification;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NotificationTile({
    required this.notification,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return Material(
      color: selected
          ? const Color(0xFFE8EFFF)
          : unread
          ? const Color(0xFFF4F7FF)
          : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColor.primary
                  : unread
                  ? const Color(0xFFD8E3FF)
                  : AppColor.divider,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 2),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? AppColor.primary : AppColor.textLight,
                    size: 22,
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _iconForType(notification.notificationType),
                    color: AppColor.primary,
                    size: 21,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight:
                                  unread ? FontWeight.w700 : FontWeight.w600,
                              color: AppColor.textPrimary,
                            ),
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: const BoxDecoration(
                              color: AppColor.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (notification.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        notification.body,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatNotificationTime(notification.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColor.textLight,
                      ),
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

  static IconData _iconForType(String type) {
    switch (type.trim().toUpperCase()) {
      case 'DIVIDEND':
        return Icons.currency_rupee_rounded;
      case 'BONUS':
        return Icons.card_giftcard_rounded;
      case 'SPLIT':
        return Icons.call_split_rounded;
      case 'SPIN-OFF':
      case 'SPINOFF':
        return Icons.account_tree_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  static String _formatNotificationTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';

    final parsed = DateTime.tryParse(raw.trim().replaceFirst(' ', 'T'));
    if (parsed == null) return raw;

    final now = DateTime.now();
    final date = DateTime(parsed.year, parsed.month, parsed.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(date).inDays;

    if (difference == 0) {
      return 'Today, ${DateFormat('h:mm a').format(parsed)}';
    }

    if (difference == 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(parsed)}';
    }

    return DateFormat('d MMM yyyy, h:mm a').format(parsed);
  }
}
