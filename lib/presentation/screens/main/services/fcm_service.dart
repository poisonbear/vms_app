import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vms_app/presentation/services/services.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/presentation/widgets/overlay/popup_dialog.dart';

/// FCM 메시지 처리 서비스
class FCMService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final PopupService popupService;
  final Function() onStartFlashing;
  final Function() onStopFlashing;
  
  late FirebaseMessaging messaging;
  late String fcmToken;
  bool _isFCMListenerRegistered = false;
  
  FCMService({
    required this.flutterLocalNotificationsPlugin,
    required this.popupService,
    required this.onStartFlashing,
    required this.onStopFlashing,
  }) {
    messaging = FirebaseMessaging.instance;
  }
  
  /// FCM 토큰 초기화
  Future<void> initializeToken() async {
    fcmToken = await messaging.getToken() ?? '';
    AppLogger.d('FCM Token: $fcmToken');
  }
  
  /// FCM 리스너 등록
  void registerFCMListener(BuildContext context) {
    if (_isFCMListenerRegistered) return;
    _isFCMListenerRegistered = true;
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(context, message);
    });
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // 앱이 백그라운드에서 메시지를 탭했을 때
    });
  }
  
  /// 메시지 처리
  void _handleMessage(BuildContext context, RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    
    _showForegroundNotification(message);
    
    if (type == 'turbine_entry_alert' &&
        !popupService.isPopupActive(PopupService.TURBINE_ENTRY_ALERT)) {
      popupService.showPopup(PopupService.TURBINE_ENTRY_ALERT);
      onStartFlashing();
      MainScreenPopups.showTurbineWarningPopup(
        context,
        message.notification?.title ?? '알림',
        message.notification?.body ?? '새로운 메시지',
        () {
          onStopFlashing();
          popupService.hidePopup(PopupService.TURBINE_ENTRY_ALERT);
        },
      );
    } else if (type == 'weather_alert' &&
        !popupService.isPopupActive(PopupService.WEATHER_ALERT)) {
      popupService.showPopup(PopupService.WEATHER_ALERT);
      MainScreenPopups.showWeatherWarningPopup(
        context,
        message.notification?.title ?? '알림',
        message.notification?.body ?? '새로운 메시지',
        () {
          onStopFlashing();
          popupService.hidePopup(PopupService.WEATHER_ALERT);
        },
      );
    } else if (type == 'submarine_cable_alert' &&
        !popupService.isPopupActive(PopupService.SUBMARINE_CABLE_ALERT)) {
      popupService.showPopup(PopupService.SUBMARINE_CABLE_ALERT);
      onStartFlashing();
      MainScreenPopups.showSubmarineWarningPopup(
        context,
        message.notification?.title ?? '알림',
        message.notification?.body ?? '새로운 메시지',
        () {
          onStopFlashing();
          popupService.hidePopup(PopupService.SUBMARINE_CABLE_ALERT);
        },
      );
    }
  }
  
  /// 포그라운드 알림 표시
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
    
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      notificationId,
      message.notification?.title ?? '알림',
      message.notification?.body ?? '알림 내용이 없습니다.',
      platformChannelSpecifics,
    );
  }
  
  /// 알림 권한 요청
  Future<void> requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLogger.d('✅ 알림 권한 허용됨');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      AppLogger.d('❌ 알림 권한 거부됨');
    } else {
      AppLogger.d('⚠️ 알림 권한 상태: ${settings.authorizationStatus}');
    }
  }
}
