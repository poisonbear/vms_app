// lib/presentation/providers/emergency_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/data/models/emergency_model.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 긴급 상황 관리 Provider
/// EmergencyService 기능을 통합한 단일 Provider
///
/// ⚠️ 이 Provider는 BaseProvider를 상속하지 않습니다.
/// 위치 추적, 전화 걸기 등 특수한 시스템 기능을 다루기 때문에
/// ChangeNotifier를 직접 상속하는 구조를 유지합니다.
class EmergencyProvider extends ChangeNotifier {
  // Constants
  static const String _emergencyHistoryKey = 'emergency_history';
  static const String _lastEmergencyKey = 'last_emergency';
  static const int _maxHistoryCount = 50;
  static const int _maxLocationHistory = 100;

  // Dispose 상태 추적
  bool _isDisposed = false;

  // 상태 변수들
  EmergencyStatus _status = EmergencyStatus.idle;
  Position? _currentPosition;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;
  EmergencyData? _currentEmergency;
  List<EmergencyData> _emergencyHistory = [];
  bool _isLocationTracking = false;
  String? _errorMessage;

  // 위치 추적 관련
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<LocationTrackingData> _locationHistory = [];

  // Getters
  EmergencyStatus get status => _status;
  Position? get currentPosition => _currentPosition;
  int get countdownSeconds => _countdownSeconds;
  EmergencyData? get currentEmergency => _currentEmergency;
  List<EmergencyData> get emergencyHistory => _emergencyHistory;
  bool get isLocationTracking => _isLocationTracking;
  String? get errorMessage => _errorMessage;
  bool get isEmergencyActive =>
      _status == EmergencyStatus.active || _status == EmergencyStatus.preparing;
  List<LocationTrackingData> get locationHistory =>
      List.unmodifiable(_locationHistory);

  // 초기화
  EmergencyProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadEmergencyHistory();
    await updateCurrentLocation();
  }

  /// 안전한 notifyListeners 호출
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      try {
        notifyListeners();
      } catch (e) {
        AppLogger.e('Error in notifyListeners: $e');
      }
    }
  }

  // ============================================
  // 위치 관련 메서드들
  // ============================================

  /// 현재 위치 가져오기
  Future<void> updateCurrentLocation() async {
    if (_isDisposed) return;

    try {
      _errorMessage = null;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = ErrorMessages.locationServiceDisabled;
        _safeNotifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = ErrorMessages.locationPermissionDenied;
          _safeNotifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = ErrorMessages.locationPermissionDeniedForever;
        _safeNotifyListeners();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (_isDisposed) return;

      _currentPosition = position;
      _addLocationToHistory(position);

      _safeNotifyListeners();
      AppLogger.d(
          '${InfoMessages.locationUpdate}: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      _errorMessage = '${ErrorMessages.locationGetFailed}: $e';
      AppLogger.e('${ErrorMessages.locationUpdateFailed}: $e');
      _safeNotifyListeners();
    }
  }

  /// 실시간 위치 추적 시작/중지 토글
  void toggleLocationTracking() {
    if (_isLocationTracking) {
      stopLocationTracking();
    } else {
      startLocationTracking();
    }
  }

  /// 실시간 위치 추적 시작
  void startLocationTracking() {
    if (_isLocationTracking || _isDisposed) return;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (_isDisposed) return;

        _currentPosition = position;
        _addLocationToHistory(position);
        _safeNotifyListeners();
        AppLogger.d(
            '${InfoMessages.locationUpdate}: ${position.latitude}, ${position.longitude}');
      },
      onError: (error) {
        AppLogger.e('${ErrorMessages.locationTrackingFailed}: $error');
        _errorMessage = ErrorMessages.locationTrackingError;
        _safeNotifyListeners();
      },
    );

    _isLocationTracking = true;
    _safeNotifyListeners();
    AppLogger.d(InfoMessages.locationTrackingStarted);
  }

  /// 실시간 위치 추적 중지
  void stopLocationTracking() {
    if (!_isLocationTracking) return;

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isLocationTracking = false;
    _safeNotifyListeners();
    AppLogger.d(InfoMessages.locationTrackingStopped);
  }

  /// 위치 히스토리에 추가
  void _addLocationToHistory(Position position) {
    _locationHistory.add(LocationTrackingData.fromPosition(
      position: position,
      reg_dt: DateTime.now(),
    ));

    if (_locationHistory.length > _maxLocationHistory) {
      _locationHistory.removeAt(0);
    }
  }

  // ============================================
  // 긴급신고 기능
  // ============================================

  /// 긴급신고 시작 (카운트다운)
  void startEmergency({
    required int? mmsi,
    required String? ship_nm,
    int countdownSeconds = 5,
  }) {
    if (_isDisposed) return;

    if (_status == EmergencyStatus.preparing ||
        _status == EmergencyStatus.active) {
      AppLogger.w(ErrorMessages.emergencyAlreadyActive);
      return;
    }

    _status = EmergencyStatus.preparing;
    _countdownSeconds = countdownSeconds;
    _errorMessage = null;

    _currentEmergency = EmergencyData.fromPosition(
      emergency_id: DateTime.now().millisecondsSinceEpoch.toString(),
      mmsi: mmsi,
      ship_nm: ship_nm,
      position: _currentPosition,
      reg_dt: DateTime.now(),
      status: EmergencyStatus.preparing,
      phone_no: '122',
    );

    if (!_isLocationTracking) {
      startLocationTracking();
    }

    _safeNotifyListeners();
    _startCountdown();
  }

  /// 카운트다운 처리
  void _startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (_countdownSeconds > 0) {
        _countdownSeconds--;
        _safeNotifyListeners();

        if (_countdownSeconds == 0) {
          timer.cancel();
          activateEmergency();
        }
      } else {
        timer.cancel();
      }
    });
  }

  /// 긴급신고 활성화 (실제 전화 연결)
  Future<void> activateEmergency() async {
    if (_isDisposed) return;

    _countdownTimer?.cancel();
    _status = EmergencyStatus.active;

    await updateCurrentLocation();

    if (_currentEmergency != null) {
      _currentEmergency = EmergencyData.fromPosition(
        emergency_id: _currentEmergency!.emergency_id,
        mmsi: _currentEmergency!.mmsi,
        ship_nm: _currentEmergency!.ship_nm,
        position: _currentPosition,
        reg_dt: DateTime.now(),
        status: EmergencyStatus.active,
        phone_no: _currentEmergency!.phone_no,
        additional_info: _currentEmergency!.additional_info,
      );

      await _saveEmergencyData(_currentEmergency!);

      final success = await _makeEmergencyCall('122');

      if (success) {
        _currentEmergency = _currentEmergency!.copyWith(
          emergency_status: EmergencyStatus.completed.name,
        );

        final message = _generateEmergencyMessage(_currentEmergency!);
        await _sendEmergencySMS(phoneNumber: '122', message: message);
      } else {
        _errorMessage = ErrorMessages.emergencyCallFailed;
      }

      await loadEmergencyHistory();
    }

    _safeNotifyListeners();
    AppLogger.d(SuccessMessages.emergencyActivated);

    Future.delayed(const Duration(seconds: 3), () {
      if (!_isDisposed) {
        resetEmergency();
      }
    });
  }

  /// 긴급신고 취소
  void cancelEmergency() {
    if (_isDisposed) return;

    _countdownTimer?.cancel();
    _countdownSeconds = 0;

    if (_currentEmergency != null) {
      _currentEmergency = _currentEmergency!.copyWith(
        emergency_status: EmergencyStatus.cancelled.name,
      );
      _saveEmergencyData(_currentEmergency!);
    }

    _status = EmergencyStatus.cancelled;
    _safeNotifyListeners();

    AppLogger.d(SuccessMessages.emergencyCancelled);

    Future.delayed(const Duration(seconds: 2), () {
      if (!_isDisposed) {
        resetEmergency();
      }
    });
  }

  /// 상태 초기화
  void resetEmergency() {
    if (_isDisposed) return;

    _countdownTimer?.cancel();
    _status = EmergencyStatus.idle;
    _countdownSeconds = 0;
    _currentEmergency = null;
    _errorMessage = null;
    _safeNotifyListeners();

    AppLogger.d(SuccessMessages.emergencyReset);
  }

  // ============================================
  // 전화/SMS 기능
  // ============================================

  Future<bool> _makeEmergencyCall(String phoneNumber) async {
    try {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );

      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
        AppLogger.d('${SuccessMessages.emergencyCallConnected}: $phoneNumber');
        return true;
      } else {
        AppLogger.e(
            '${ErrorMessages.emergencyCallConnectionFailed}: $phoneNumber');
        return false;
      }
    } catch (e) {
      AppLogger.e('${ErrorMessages.emergencyCallError}: $e');
      return false;
    }
  }

  Future<bool> _sendEmergencySMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        AppLogger.d('${SuccessMessages.smsSent}: $phoneNumber');
        return true;
      } else {
        AppLogger.w(ErrorMessages.smsSendFailed);
        return false;
      }
    } catch (e) {
      AppLogger.e('${ErrorMessages.smsError}: $e');
      return false;
    }
  }

  String _generateEmergencyMessage(EmergencyData data) {
    String message = '🚨 긴급신고\n';

    if (data.ship_nm != null && data.ship_nm!.isNotEmpty) {
      message += '선박명: ${data.ship_nm}\n';
    }

    if (data.mmsi != null) {
      message += 'MMSI: ${data.mmsi}\n';
    }

    if (data.lttd != null && data.lntd != null) {
      message += '위치: 북위 ${data.lttd!.toStringAsFixed(4)}° ';
      message += '동경 ${data.lntd!.toStringAsFixed(4)}°\n';
    }

    message += '시간: ${_formatDateTime(data.reg_dt)}';

    return message;
  }

  // ============================================
  // 데이터 저장/로드
  // ============================================

  Future<void> _saveEmergencyData(EmergencyData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_lastEmergencyKey, jsonEncode(data.toJson()));

      List<String> history = prefs.getStringList(_emergencyHistoryKey) ?? [];

      history.insert(0, jsonEncode(data.toJson()));

      if (history.length > _maxHistoryCount) {
        history = history.sublist(0, _maxHistoryCount);
      }

      await prefs.setStringList(_emergencyHistoryKey, history);

      AppLogger.d(
          '${SuccessMessages.emergencyDataSaved}: ${data.emergency_id}');
    } catch (e) {
      AppLogger.e('${ErrorMessages.emergencyDataSaveFailed}: $e');
    }
  }

  Future<void> loadEmergencyHistory() async {
    if (_isDisposed) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? history = prefs.getStringList(_emergencyHistoryKey);

      if (history != null) {
        _emergencyHistory = history.map((jsonStr) {
          return EmergencyData.fromJson(jsonDecode(jsonStr));
        }).toList();

        AppLogger.d(
            '${InfoMessages.emergencyHistoryLoaded}: ${_emergencyHistory.length}개');
      } else {
        _emergencyHistory = [];
      }

      _safeNotifyListeners();
    } catch (e) {
      AppLogger.e('${ErrorMessages.emergencyHistoryLoadFailed}: $e');
      _emergencyHistory = [];
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emergencyHistoryKey);
      await prefs.remove(_lastEmergencyKey);

      _emergencyHistory = [];
      _safeNotifyListeners();

      AppLogger.d(SuccessMessages.emergencyHistoryCleared);
    } catch (e) {
      AppLogger.e('${ErrorMessages.emergencyHistoryClearFailed}: $e');
    }
  }

  // ============================================
  // Helper 메서드들
  // ============================================

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }

  // ============================================
  // Dispose
  // ============================================

  @override
  void dispose() {
    if (_isDisposed) {
      AppLogger.w('EmergencyProvider already disposed');
      return;
    }

    _isDisposed = true;
    AppLogger.d('Disposing EmergencyProvider...');

    _countdownTimer?.cancel();
    _countdownTimer = null;

    stopLocationTracking();

    _locationHistory.clear();
    _emergencyHistory.clear();

    _currentEmergency = null;
    _currentPosition = null;
    _errorMessage = null;

    AppLogger.d('EmergencyProvider disposed');
    super.dispose();
  }
}
