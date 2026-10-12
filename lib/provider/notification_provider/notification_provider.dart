import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:profit_from_it_investors/model/app_notification_response.dart';
import 'package:profit_from_it_investors/network/http_request.dart';
import 'package:profit_from_it_investors/utility/common.dart';
import 'package:profit_from_it_investors/utility/constant.dart';

class AppNotificationProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isMarkingRead = false;
  int _unreadCount = 0;
  List<AppNotificationItem> _notifications = <AppNotificationItem>[];

  bool get isLoading => _isLoading;
  bool get isMarkingRead => _isMarkingRead;
  int get unreadCount => _unreadCount;
  List<AppNotificationItem> get notifications =>
      List<AppNotificationItem>.unmodifiable(_notifications);

  Future<bool> getNotifications({bool showLoader = true}) async {
    try {
      if (showLoader) {
        _isLoading = true;
        notifyListeners();
      }

      final Response? response = await httpGet('${CMD.notifications}?limit=100');
      if (response == null) {
        return false;
      }

      final parsed = appNotificationResponseFromJson(response.body);

      if (response.statusCode == 200 && parsed.status == 200) {
        _notifications = parsed.data?.notifications ?? <AppNotificationItem>[];
        _unreadCount = parsed.data?.unreadCount ?? 0;
        notifyListeners();
        return true;
      }

      showError(parsed.message.isNotEmpty
          ? parsed.message
          : 'Unable to load notifications.');
      return false;
    } catch (e) {
      debugPrint('notifications api error =====> $e');

      if (e is SocketException) {
        showError('No internet connection. Please check your network.');
      } else if (showLoader) {
        showError('Something went wrong. Please try again.');
      }

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markAsRead(Iterable<int> notificationIds) async {
    final ids = notificationIds.where((id) => id > 0).toSet().toList();
    if (ids.isEmpty || _isMarkingRead) {
      return false;
    }

    try {
      _isMarkingRead = true;
      notifyListeners();

      final Response? response = await httpPost(CMD.notificationsMarkRead, {
        'ids': ids,
      });

      if (response == null || response.statusCode != 200) {
        showError('Unable to mark notifications as read.');
        return false;
      }

      final parsed = appNotificationResponseFromJson(response.body);
      if (parsed.status != 200) {
        showError(parsed.message.isNotEmpty
            ? parsed.message
            : 'Unable to mark notifications as read.');
        return false;
      }

      final now = DateTime.now().toIso8601String();
      final idSet = ids.toSet();

      for (final notification in _notifications) {
        if (idSet.contains(notification.id) && !notification.isRead) {
          notification.readAt = now;
        }
      }

      _unreadCount = parsed.data?.unreadCount ??
          _notifications.where((item) => !item.isRead).length;

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('mark notification read error =====> $e');
      showError('Something went wrong. Please try again.');
      return false;
    } finally {
      _isMarkingRead = false;
      notifyListeners();
    }
  }

  void clear() {
    _notifications = <AppNotificationItem>[];
    _unreadCount = 0;
    _isLoading = false;
    _isMarkingRead = false;
    notifyListeners();
  }
}
