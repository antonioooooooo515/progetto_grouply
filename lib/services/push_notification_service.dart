import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef NotificationTapCallback = void Function(Map<String, dynamic> data);

class PushNotificationsService {
  PushNotificationsService._internal();
  static final PushNotificationsService instance =
  PushNotificationsService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'grouply_high_importance';
  static const String _channelName = 'Grouply Notifications';
  static const String _channelDescription =
      'Notifiche per post, eventi, sondaggi, pagamenti e chat.';

  bool _initialized = false;
  NotificationTapCallback? _onTap;

  Future<void> init({NotificationTapCallback? onTap}) async {
    if (_initialized) return;
    _initialized = true;

    _onTap = onTap;

    if (kIsWeb) {
      if (kDebugMode) {
        debugPrint(
            'PushNotificationsService: web -> disabled (no FCM / no local notifications)');
      }
      return;
    }

    await _requestPermission();

    await _initLocalNotifications();

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    final token = await _messaging.getToken();
    if (kDebugMode) {
      debugPrint('FCM token: $token');
    }

    _messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        debugPrint('FCM token refreshed: $newToken');
      }
    });
  }

  /// Imposta/aggiorna il callback di tap (se vuoi farlo dopo init).
  void setOnTap(NotificationTapCallback onTap) {
    _onTap = onTap;
  }

  /// Subscribe al topic del gruppo (es: group_<groupId>)
  Future<void> subscribeToGroup(String groupId) async {
    if (kIsWeb) return;
    final topic = _topicForGroup(groupId);
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe dal topic del gruppo
  Future<void> unsubscribeFromGroup(String groupId) async {
    if (kIsWeb) return;
    final topic = _topicForGroup(groupId);
    await _messaging.unsubscribeFromTopic(topic);
  }

  String _topicForGroup(String groupId) => 'group_$groupId';

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    if (kDebugMode) {
      debugPrint('Notification permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Tap su notifica locale
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;

        try {
          final data = jsonDecode(payload);
          if (data is Map<String, dynamic>) {
            _onTap?.call(data);
          }
        } catch (_) {
          // ignore
        }
      },
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotificationFromFCM(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    _onTap?.call(data);
  }

  Future<void> _showLocalNotificationFromFCM(RemoteMessage message) async {
    if (kIsWeb) return;

    final notification = message.notification;

    final title =
        notification?.title ?? (message.data['title']?.toString() ?? 'Nuova notifica');
    final body = notification?.body ?? (message.data['body']?.toString() ?? '');

    final payload = jsonEncode(message.data);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> showLocal({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    if (kIsWeb) return;

    final payload = jsonEncode(data);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }
}
