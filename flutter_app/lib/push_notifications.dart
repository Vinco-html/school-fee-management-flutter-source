import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_client.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'school-fee-alerts',
  'School fee alerts',
  description: 'Notifications about payments, students, and school activity.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class PushNotificationService {
  PushNotificationService._();

  static StreamSubscription<String>? _tokenSubscription;
  static StreamSubscription<RemoteMessage>? _messageSubscription;

  static Future<void> initialize(ApiClient api) async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const settings = InitializationSettings(
      android: AndroidInitializationSettings(
        '@mipmap/petunia_logo_transparent',
      ),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(settings: settings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    final permission = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (permission.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await api.registerDeviceToken(
        deviceToken: token,
        platform: defaultTargetPlatform.name,
      );
    }

    await _tokenSubscription?.cancel();
    _tokenSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      unawaited(api.registerDeviceToken(
        deviceToken: token,
        platform: defaultTargetPlatform.name,
      ));
    });

    await _messageSubscription?.cancel();
    _messageSubscription =
        FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'school-fee-alerts',
          'School fee alerts',
          channelDescription:
              'Notifications about payments, students, and school activity.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/petunia_logo_transparent',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
