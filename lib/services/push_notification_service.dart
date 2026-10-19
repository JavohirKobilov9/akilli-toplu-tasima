import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';

// Her platform için Firebase konsolundaki kendi uygulama bilgileri kullanılır.
const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _appId = String.fromEnvironment('FIREBASE_APP_ID');
const _senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
const _firebaseConfigured =
    _apiKey != '' && _appId != '' && _senderId != '' && _projectId != '';
const _options = FirebaseOptions(
  apiKey: _apiKey,
  appId: _appId,
  messagingSenderId: _senderId,
  projectId: _projectId,
  iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (_firebaseConfigured) await Firebase.initializeApp(options: _options);
  // notification yükünü Android/iOS arka planda kendisi gösterir.
}

class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();
  static final navigatorKey = GlobalKey<NavigatorState>();
  final changes = ValueNotifier<int>(0);
  bool _ready = false;
  bool _listening = false;
  bool _starting = false;

  Future<void> initialize() async {
    if (!_firebaseConfigured ||
        kIsWeb ||
        ![
          TargetPlatform.android,
          TargetPlatform.iOS,
        ].contains(defaultTargetPlatform)) {
      return;
    }
    try {
      await Firebase.initializeApp(options: _options);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _ready = true;
    } catch (_) {
      debugPrint(
        'Firebase başlatılamadı. Uygulama içi bildirimler kullanılabilir.',
      );
    }
  }

  Future<void> start() async {
    if (!_ready || _starting) return;
    _starting = true;
    try {
      final api = ApiService();
      if (await api.getToken() == null) return;
      final user = await api.getMe();
      if (user['role'] != 'user') return;
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.denied) return;
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      // Sunucu HTTP v1 token hedefini kullanır; FID tabanlı register() ayrı bir protokoldür.
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) await api.registerPushDevice(token);
      if (!_listening) {
        _listening = true;
        // ignore: deprecated_member_use
        messaging.onTokenRefresh.listen((token) async {
          try {
            await ApiService().registerPushDevice(token);
          } catch (_) {
            debugPrint(
              'Telefon bildirim kaydı yenilenemedi; sonraki açılışta tekrar denenecek.',
            );
          }
        });
        FirebaseMessaging.onMessage.listen((message) async {
          if (await ApiService().getToken() == null) return;
          changes.value++;
          final context = navigatorKey.currentContext;
          if (context == null || !context.mounted) return;
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(
                message.notification?.body ??
                    'Şikayetinizin durumu güncellendi.',
              ),
              action: SnackBarAction(label: 'Görüntüle', onPressed: _openInbox),
            ),
          );
        });
        FirebaseMessaging.onMessageOpenedApp.listen((_) => _openInbox());
        final initial = await messaging.getInitialMessage();
        if (initial != null) _openInbox();
      }
    } catch (_) {
      debugPrint(
        'Telefon bildirimi bağlantısı kurulamadı; sonraki açılışta tekrar denenecek.',
      );
    } finally {
      _starting = false;
    }
  }

  Future<void> _openInbox() async {
    if (await ApiService().getToken() == null) return;
    navigatorKey.currentState?.pushNamed('/bildirimler');
  }
}
