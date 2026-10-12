import 'dart:convert';

AppNotificationResponse appNotificationResponseFromJson(String str) =>
    AppNotificationResponse.fromJson(json.decode(str));

class AppNotificationResponse {
  final int status;
  final String message;
  final AppNotificationData? data;

  AppNotificationResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory AppNotificationResponse.fromJson(Map<String, dynamic> json) {
    return AppNotificationResponse(
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? AppNotificationData.fromJson(json['data'])
          : null,
    );
  }
}

class AppNotificationData {
  final int unreadCount;
  final List<AppNotificationItem> notifications;

  AppNotificationData({required this.unreadCount, required this.notifications});

  factory AppNotificationData.fromJson(Map<String, dynamic> json) {
    final rawList = json['notifications'];

    return AppNotificationData(
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
      notifications: rawList is List
          ? rawList
                .whereType<Map>()
                .map(
                  (item) => AppNotificationItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <AppNotificationItem>[],
    );
  }
}

class AppNotificationItem {
  final int id;
  final int userId;
  final int corporateActionId;
  final String notificationType;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  String? readAt;
  final String? createdAt;

  AppNotificationItem({
    required this.id,
    required this.userId,
    required this.corporateActionId,
    required this.notificationType,
    required this.title,
    required this.body,
    required this.data,
    required this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null && readAt!.trim().isNotEmpty;

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];

    Map<String, dynamic> parsedData = <String, dynamic>{};
    if (rawData is Map) {
      parsedData = Map<String, dynamic>.from(rawData);
    }

    return AppNotificationItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      corporateActionId:
          int.tryParse(json['corporate_action_id']?.toString() ?? '0') ?? 0,
      notificationType: json['notification_type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: parsedData,
      readAt: json['read_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
