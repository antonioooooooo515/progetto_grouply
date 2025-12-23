import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app.dart';
import 'firebase_options.dart';

import 'services/push_notification_service.dart';
import 'pagine/group_dashboard_page.dart';
import 'pagine/payments_page.dart';
import 'pagine/group_chat_page.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Apre la bacheca (dashboard) del gruppo partendo da groupId.
Future<void> _openGroupDashboard(String groupId) async {
  final snap =
  await FirebaseFirestore.instance.collection('groups').doc(groupId).get();

  if (!snap.exists) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (r) => false);
    return;
  }

  final g = snap.data() as Map<String, dynamic>;
  final groupName = (g['name'] ?? 'Gruppo').toString();
  final groupSport = (g['sport'] ?? '').toString();
  final adminId = (g['adminId'] ?? '').toString();
  final inviteCode = (g['inviteCode'] ?? '???').toString();

  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => GroupDashboardPage(
        groupId: groupId,
        groupName: groupName,
        groupSport: groupSport,
        adminId: adminId,
        inviteCode: inviteCode,
      ),
    ),
  );
}

/// Apre la chat del gruppo partendo da groupId.
Future<void> _openGroupChat(String groupId) async {
  final snap =
  await FirebaseFirestore.instance.collection('groups').doc(groupId).get();

  if (!snap.exists) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (r) => false);
    return;
  }

  final g = snap.data() as Map<String, dynamic>;
  final groupName = (g['name'] ?? 'Gruppo').toString();

  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => GroupChatPage(
        groupId: groupId,
        groupName: groupName,
      ),
    ),
  );
}

/// Apre la sezione pagamenti (non richiede parametri).
void _openPaymentsPage() {
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => const PaymentsPage(),
    ),
  );
}

/// Navigazione da notifica: eseguila SOLO dopo che il Navigator è pronto.
void _handleNotificationTap(Map<String, dynamic> data) {
  debugPrint('NOTIF TAP -> data = $data');

  // Esegui dopo il primo frame (risolve il caso "terminated -> tap")
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // piccolo retry se il navigator non è ancora pronto
    if (navigatorKey.currentState == null) {
      await Future.delayed(const Duration(milliseconds: 120));
    }

    final rawType = (data['type'] ?? '').toString().trim();
    final type = rawType.toLowerCase(); // normalizza
    final groupId = (data['groupId'] ?? '').toString().trim();

    // ✅ Pagamenti: accetta singolare e plurale
    if (type == 'payment_request' || type == 'payment_requests') {
      _openPaymentsPage();
      return;
    }

    // ✅ Bacheca gruppo (post/evento/sondaggio)
    if (type == 'group_content' && groupId.isNotEmpty) {
      await _openGroupDashboard(groupId);
      return;
    }

    // ✅ Chat gruppo: accetta singolare e plurale
    if ((type == 'chat_message' || type == 'chat_messages') &&
        groupId.isNotEmpty) {
      await _openGroupChat(groupId);
      return;
    }

    debugPrint('NOTIF TAP -> fallback (type="$rawType", groupId="$groupId")');
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (r) => false);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await initializeDateFormatting();

  await PushNotificationsService.instance.init(
    onTap: _handleNotificationTap,
  );

  runApp(const MyApp());
}
