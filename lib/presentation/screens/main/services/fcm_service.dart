// lib/presentation/screens/main/services/fcm_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vms_app/presentation/services/services.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart'; //추가
import 'package:vms_app/presentation/widgets/overlay/popup_dialog.dart';

/// FCM 메시지 타입 정의
enum FCMMessageType {
  turbineEntryAlert('turbine_entry_alert'),
  weatherAlert('weather_alert'),
  submarineCableAlert('submarine_cable_alert'),
  unknown('unknown');

  final String value;
  const FCMMessageType(this.value);

  static FCMMessageType fromString(String? type) {
    if (type == null) return FCMMessageType.unknown;
    return FCMMessageType.values.firstWhere(
      (e) => e.value == type,
      orElse: () => FCMMessageType.unknown,
    );
  }
}

/// FCM 메시지 처리 결과
class FCMMessageResult {
  final bool success;
  final String? error;
  final FCMMessageType type;

  const FCMMessageResult({
    required this.success,
    this.error,
    required this.type,
  });

  factory FCMMessageResult.success(FCMMessageType type) {
    return FCMMessageResult(success: true, type: type);
  }

  factory FCMMessageResult.failure(FCMMessageType type, String error) {
    return FCMMessageResult(success: false, error: error, type: type);
  }
}

/// FCM 메시지 처리 서비스
///
/// Firebase Cloud Messaging을 통한 푸시 알림을 처리합니다.
/// - 토큰 관리
/// - 메시지 수신 및 처리
/// - 포그라운드 알림 표시
/// - 팝업 중복 방지
class FCMService {
  // ============================================
  // Dependencies
  // ============================================
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  final PopupService _popupService;
  final VoidCallback _onStartFlashing;
  final VoidCallback _onStopFlashing;

  // ============================================
  // Internal State
  // ============================================
  late final FirebaseMessaging _messaging;
  String _fcmToken = '';
  bool _isListenerRegistered = false;

  // ============================================
  // Getters
  // ============================================
  String get fcmToken => _fcmToken;
  bool get isListenerRegistered => _isListenerRegistered;

  // ============================================
  // Constructor
  // ============================================
  FCMService({
    required FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    required PopupService popupService,
    required VoidCallback onStartFlashing,
    required VoidCallback onStopFlashing,
  })  : _notificationsPlugin = flutterLocalNotificationsPlugin,
        _popupService = popupService,
        _onStartFlashing = onStartFlashing,
        _onStopFlashing = onStopFlashing {
    _messaging = FirebaseMessaging.instance;
  }

  // ============================================
  // Public Methods
  // ============================================

  /// FCM 토큰 초기화
  Future<String> initializeToken() async {
    try {
      _fcmToken = await _messaging.getToken() ?? '';
      if (_fcmToken.isEmpty) {
        AppLogger.w('FCM Token is empty');
      } else {
        AppLogger.i('FCM Token initialized: ${_fcmToken.substring(0, 20)}...');
      }
      return _fcmToken;
    } catch (e) {
      AppLogger.e('Failed to initialize FCM token', e);
      return '';
    }
  }

  /// FCM 리스너 등록
  void registerFCMListener(BuildContext context) {
    if (_isListenerRegistered) {
      AppLogger.w('FCM listener already registered');
      return;
    }

    _isListenerRegistered = true;

    // 포그라운드 메시지 수신
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      //mounted 체크 추가 (라인 126 근처)
      if (!context.mounted) {
        AppLogger.w('Context is not mounted, skipping message handling');
        return;
      }

      _handleMessage(context, message);
    });

    // 백그라운드에서 앱을 열었을 때
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.d('Message opened app: ${message.messageId}');

      //mounted 체크 추가 (라인 132 근처)
      if (!context.mounted) {
        AppLogger.w(
            'Context is not mounted, skipping background message handling');
        return;
      }

      _handleBackgroundMessage(context, message);
    });

    AppLogger.i('FCM listener registered successfully');
  }

  /// 리스너 해제
  void unregisterFCMListener() {
    _isListenerRegistered = false;
    AppLogger.i('FCM listener unregistered');
  }

  // ============================================
  // Private Methods
  // ============================================

  /// 메시지 처리 (포그라운드)
  void _handleMessage(BuildContext context, RemoteMessage message) {
    try {
      AppLogger.d(' FCM Message received: ${message.messageId}');
      AppLogger.d(' - Type: ${message.data['type']}');
      AppLogger.d(' - Title: ${message.notification?.title}');

      // 포그라운드 알림 표시
      _showForegroundNotification(message);

      //mounted 체크 추가 (추가 안전성)
      if (!context.mounted) {
        AppLogger.w('Context became unmounted during message handling');
        return;
      }

      // 메시지 타입별 처리
      final result = _processMessage(context, message);

      if (!result.success) {
        AppLogger.w('Message processing failed: ${result.error}');
      }
    } catch (e) {
      AppLogger.e('Error handling FCM message', e);
    }
  }

  /// 백그라운드 메시지 처리
  void _handleBackgroundMessage(BuildContext context, RemoteMessage message) {
    AppLogger.d('Background message opened');
    // 필요시 특정 화면으로 이동하는 로직 추가 가능

    //mounted 체크 추가 (추가 안전성)
    if (!context.mounted) {
      AppLogger.w('Context is not mounted for background message');
      return;
    }
  }

  /// 메시지 타입별 처리
  FCMMessageResult _processMessage(
    BuildContext context,
    RemoteMessage message,
  ) {
    final messageType = FCMMessageType.fromString(message.data['type']);
    final title = message.notification?.title ?? InfoMessages.notification;
    final body = message.notification?.body ?? InfoMessages.newMessageArrived;

    // 메시지 타입별 처리
    switch (messageType) {
      case FCMMessageType.turbineEntryAlert:
        return _handleTurbineAlert(context, title, body);

      case FCMMessageType.weatherAlert:
        return _handleWeatherAlert(context, title, body);

      case FCMMessageType.submarineCableAlert:
        return _handleSubmarineAlert(context, title, body);

      case FCMMessageType.unknown:
        AppLogger.w('Unknown message type: ${message.data['type']}');
        return FCMMessageResult.failure(
          messageType,
          'Unknown message type',
        );
    }
  }

  /// 터빈 진입 경고 처리
  FCMMessageResult _handleTurbineAlert(
    BuildContext context,
    String title,
    String body,
  ) {
    if (_popupService.isPopupActive(PopupService.TURBINE_ENTRY_ALERT)) {
      return FCMMessageResult.failure(
        FCMMessageType.turbineEntryAlert,
        'Popup already active',
      );
    }

    //mounted 체크 추가
    if (!context.mounted) {
      return FCMMessageResult.failure(
        FCMMessageType.turbineEntryAlert,
        'Context not mounted',
      );
    }

    _popupService.showPopup(PopupService.TURBINE_ENTRY_ALERT);
    _onStartFlashing();

    MainScreenPopups.showTurbineWarningPopup(
      context,
      title,
      body,
      () {
        _onStopFlashing();
        _popupService.hidePopup(PopupService.TURBINE_ENTRY_ALERT);
      },
    );

    return FCMMessageResult.success(FCMMessageType.turbineEntryAlert);
  }

  /// 날씨 경고 처리
  FCMMessageResult _handleWeatherAlert(
    BuildContext context,
    String title,
    String body,
  ) {
    if (_popupService.isPopupActive(PopupService.WEATHER_ALERT)) {
      return FCMMessageResult.failure(
        FCMMessageType.weatherAlert,
        'Popup already active',
      );
    }

    //mounted 체크 추가
    if (!context.mounted) {
      return FCMMessageResult.failure(
        FCMMessageType.weatherAlert,
        'Context not mounted',
      );
    }

    _popupService.showPopup(PopupService.WEATHER_ALERT);

    MainScreenPopups.showWeatherWarningPopup(
      context,
      title,
      body,
      () {
        _onStopFlashing();
        _popupService.hidePopup(PopupService.WEATHER_ALERT);
      },
    );

    return FCMMessageResult.success(FCMMessageType.weatherAlert);
  }

  /// 해저 케이블 경고 처리
  FCMMessageResult _handleSubmarineAlert(
    BuildContext context,
    String title,
    String body,
  ) {
    if (_popupService.isPopupActive(PopupService.SUBMARINE_CABLE_ALERT)) {
      return FCMMessageResult.failure(
        FCMMessageType.submarineCableAlert,
        'Popup already active',
      );
    }

    //mounted 체크 추가
    if (!context.mounted) {
      return FCMMessageResult.failure(
        FCMMessageType.submarineCableAlert,
        'Context not mounted',
      );
    }

    _popupService.showPopup(PopupService.SUBMARINE_CABLE_ALERT);
    _onStartFlashing();

    MainScreenPopups.showSubmarineWarningPopup(
      context,
      title,
      body,
      () {
        _onStopFlashing();
        _popupService.hidePopup(PopupService.SUBMARINE_CABLE_ALERT);
      },
    );

    return FCMMessageResult.success(FCMMessageType.submarineCableAlert);
  }

  /// 포그라운드 알림 표시
  void _showForegroundNotification(RemoteMessage message) {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    _notificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? InfoMessages.notification,
      message.notification?.body ?? InfoMessages.newMessageArrived,
      notificationDetails,
    );

    AppLogger.d('Foreground notification shown');
  }

  // ============================================
  // Cleanup
  // ============================================

  /// 리소스 정리
  void dispose() {
    unregisterFCMListener();
    AppLogger.d('FCMService disposed');
  }
}
