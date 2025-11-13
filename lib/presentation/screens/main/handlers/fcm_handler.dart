import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

class FCMHandler {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final Function(String type, String? title, String? body) onMessageReceived;

  FCMHandler({
    required this.flutterLocalNotificationsPlugin,
    required this.onMessageReceived,
  });

  void initialize() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;
      final type = data['type'];

      _showForegroundNotification(message);

      if (type != null) {
        onMessageReceived(
          type,
          message.notification?.title,
          message.notification?.body,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.d('앱이 백그라운드에서 열림: ${message.messageId}');
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final int notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        const AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: '중요 알림을 위한 채널입니다.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      styleInformation: BigTextStyleInformation(''),
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      message.notification?.title ?? '알림',
      message.notification?.body ?? '알림 내용이 없습니다.',
      platformChannelSpecifics,
    );
  }

  Future<void> requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLogger.d('알림 권한 허용됨');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      AppLogger.d('알림 권한 거부됨');
    } else {
      AppLogger.d('알림 권한 상태: ${settings.authorizationStatus}');
    }
  }
}
