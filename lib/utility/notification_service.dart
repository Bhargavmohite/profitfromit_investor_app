import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:profit_from_it_investors/network/http_request.dart';
import 'package:profit_from_it_investors/utility/constant.dart';
import 'package:profit_from_it_investors/utility/local_storage.dart';

/// Must remain a top-level function so Firebase can invoke it while the app
/// is in the background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint(
    '[FCM] Background message received: '
    'id=${message.messageId}, '
    'title=${message.notification?.title}, '
    'body=${message.notification?.body}',
  );
}

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// This ID must match the default channel ID already declared in
  /// AndroidManifest.xml.
  static const AndroidNotificationChannel _highImportanceChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'Important notifications from Profit Investor',
        importance: Importance.high,
      );

  static Future<void> initialize() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Register the background handler before setting up listeners.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initializeLocalNotifications();

    final NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    // Useful for iOS later; harmless on Android.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Firebase does not automatically show a visible Android notification
    // while the Flutter app is in the foreground. Display it locally.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint(
        '[FCM] Foreground message received: '
        'id=${message.messageId}, '
        'title=${message.notification?.title}, '
        'body=${message.notification?.body}',
      );

      await _showForegroundNotification(message);
    });

    // If the user is already logged in, register the current token at startup.
    await registerCurrentToken();

    // Firebase can rotate a token. Keep Laravel updated automatically.
    messaging.onTokenRefresh.listen((String token) async {
      await _registerTokenWithBackend(token);
    });
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(settings: initializationSettings);

    // Android 8+ requires the channel to exist before notifications can
    // reliably be displayed. This channel ID matches AndroidManifest.xml.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_highImportanceChannel);

    debugPrint(
      '[FCM] Android notification channel ready: '
      '${_highImportanceChannel.id}',
    );
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;

    if (notification == null) {
      debugPrint(
        '[FCM] Foreground message has no notification payload; '
        'nothing visible to display.',
      );
      return;
    }

    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'Important notifications from Profit Investor',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_notification',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      2147483647,
    );

    await _localNotifications.show(
      id: notificationId,
      title: notification.title ?? 'Profit Investor',
      body: notification.body ?? '',
      notificationDetails: notificationDetails,
    );

    debugPrint('[FCM] Visible foreground notification displayed.');
  }

  static Future<bool> registerCurrentToken() async {
    try {
      final String accessToken = await LocalStorage.getAccessToken();

      // Before OTP verification there is no authenticated Laravel session yet.
      if (accessToken.isEmpty) {
        debugPrint('[FCM] Backend registration skipped: user not logged in.');
        return false;
      }

      final String? token = await FirebaseMessaging.instance.getToken();

      if (token == null || token.trim().isEmpty) {
        debugPrint('[FCM] Backend registration skipped: token unavailable.');
        return false;
      }

      return await _registerTokenWithBackend(token);
    } catch (e) {
      debugPrint('[FCM] Unable to register current token: $e');
      return false;
    }
  }

  static Future<bool> _registerTokenWithBackend(String token) async {
    try {
      final String accessToken = await LocalStorage.getAccessToken();

      if (accessToken.isEmpty) {
        return false;
      }

      final response = await httpPost(CMD.deviceToken, {
        'fcm_token': token,
        'platform': Platform.isAndroid
            ? 'android'
            : Platform.isIOS
            ? 'ios'
            : 'unknown',
      });

      final bool success =
          response != null &&
          response.statusCode >= 200 &&
          response.statusCode < 300;

      debugPrint(
        success
            ? '[FCM] Device token registered with backend.'
            : '[FCM] Device token registration failed: ${response?.statusCode}',
      );

      return success;
    } catch (e) {
      debugPrint('[FCM] Device token registration error: $e');
      return false;
    }
  }
}
