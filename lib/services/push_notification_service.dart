import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // kIsWeb, kDebugMode, debugPrint
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Callback invocata quando l'utente apre una notifica (tap).
/// Ti passa la mappa `data` (quella che mandi nelle FCM data payload).
typedef NotificationTapCallback = void Function(Map<String, dynamic> data);

class PushNotificationsService {
  PushNotificationsService._internal();
  static final PushNotificationsService instance =
  PushNotificationsService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // Canale Android (necessario per Android 8+)
  static const String _channelId = 'grouply_high_importance';
  static const String _channelName = 'Grouply Notifications';
  static const String _channelDescription =
      'Notifiche per post, eventi, sondaggi, pagamenti e chat.';

  bool _initialized = false;
  NotificationTapCallback? _onTap;

  /// Chiamalo una sola volta all’avvio (es. in main, prima di runApp).
  Future<void> init({NotificationTapCallback? onTap}) async {
    if (_initialized) return;
    _initialized = true;

    _onTap = onTap;

    // ✅ WEB: non vogliamo notifiche + evita crash service worker di firebase_messaging
    if (kIsWeb) {
      if (kDebugMode) {
        debugPrint(
            'PushNotificationsService: web -> disabled (no FCM / no local notifications)');
      }
      return;
    }

    // 1) Permessi (iOS + Android 13+)
    await _requestPermission();

    // 2) Init local notifications (per mostrare banner in foreground)
    await _initLocalNotifications();

    // 3) iOS: fai vedere alert/sound/badge anche in foreground (safe anche se già lo fai in main)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4) Listener: messaggi in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5) Listener: tap su notifica quando app è in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 6) Caso: app avviata da terminated tramite tap sulla notifica
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // 7) Token (utile se vuoi salvarlo su Firestore; qui lo stampo soltanto)
    final token = await _messaging.getToken();
    if (kDebugMode) {
      debugPrint('FCM token: $token');
    }

    // 8) Token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        debugPrint('FCM token refreshed: $newToken');
      }
      // TODO: qui eventualmente aggiorni Firestore con il nuovo token
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
    // Su Android < 13 non serve runtime permission. Su Android 13+ e iOS sì.
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

    // Crea canale Android
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
    // Quando l’app è aperta: mostriamo una notifica locale (banner)
    await _showLocalNotificationFromFCM(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    // Quando l'utente tocca una notifica FCM (background/terminated)
    final data = Map<String, dynamic>.from(message.data);
    _onTap?.call(data);
  }

  Future<void> _showLocalNotificationFromFCM(RemoteMessage message) async {
    if (kIsWeb) return;

    final notification = message.notification;

    // Titolo/testo: prova dalla notification, fallback su data
    final title =
        notification?.title ?? (message.data['title']?.toString() ?? 'Nuova notifica');
    final body = notification?.body ?? (message.data['body']?.toString() ?? '');

    // payload: salva solo data (serve per routing quando tocchi la notifica locale)
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

  // ✅ Notifica locale manuale (perfetta per FOREGROUND da Firestore)
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
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // id univoco
      title,
      body,
      details,
      payload: payload,
    );
  }
}
