import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/data/models/emergency_model.dart';

/// 긴급 상황 관리 Provider
/// EmergencyService 기능을 통합한 단일 Provider
class EmergencyProvider extends ChangeNotifier {
  // Constants
  static const String _emergencyHistoryKey = 'emergency_history';
  static const String _lastEmergencyKey = 'last_emergency';
  static const int _maxHistoryCount = 50;
  static const int _maxLocationHistory = 100;

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
  List<LocationTrackingData> get locationHistory => List.unmodifiable(_locationHistory);

  // 초기화
  EmergencyProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadEmergencyHistory();
    await updateCurrentLocation();
  }

  // ============================================
  // 위치 관련 메서드들 (기존 Service 기능)
  // ============================================

  /// 현재 위치 가져오기
  Future<void> updateCurrentLocation() async {
    try {
      _errorMessage = null;

      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = '위치 서비스가 비활성화되어 있습니다. 설정에서 GPS를 활성화해주세요.';
        notifyListeners();
        return;
      }

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = '위치 권한이 거부되었습니다. 설정에서 권한을 허용해주세요.';
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = '위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.';
        notifyListeners();
        return;
      }

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = position;
      _addLocationToHistory(position);

      notifyListeners();
      AppLogger.d('위치 업데이트: ${position.latitude}, ${position.longitude}');

    } catch (e) {
      _errorMessage = '위치 정보를 가져올 수 없습니다: $e';
      AppLogger.e('위치 업데이트 실패: $e');
      notifyListeners();
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
    if (_isLocationTracking) return;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // 10미터마다 업데이트
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
          (Position position) {
        _currentPosition = position;
        _addLocationToHistory(position);
        notifyListeners();
        AppLogger.d('위치 업데이트: ${position.latitude}, ${position.longitude}');
      },
      onError: (error) {
        AppLogger.e('위치 추적 오류: $error');
        _errorMessage = '위치 추적 중 오류가 발생했습니다';
        notifyListeners();
      },
    );

    _isLocationTracking = true;
    notifyListeners();
    AppLogger.d('실시간 위치 추적 시작');
  }

  /// 실시간 위치 추적 중지
  void stopLocationTracking() {
    if (!_isLocationTracking) return;

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isLocationTracking = false;
    notifyListeners();
    AppLogger.d('실시간 위치 추적 중지');
  }

  /// 위치 히스토리에 추가
  void _addLocationToHistory(Position position) {
    _locationHistory.add(LocationTrackingData.fromPosition(
      position: position,
      reg_dt: DateTime.now(),
    ));

    // 최대 개수 초과시 오래된 데이터 삭제
    if (_locationHistory.length > _maxLocationHistory) {
      _locationHistory.removeAt(0);
    }
  }

  // ============================================
  // 긴급신고 기능 (기존 Service 기능)
  // ============================================

  /// 긴급신고 시작 (카운트다운)
  void startEmergency({
    required int? mmsi,
    required String? ship_nm,
    int countdownSeconds = 5,
  }) {
    if (_status == EmergencyStatus.preparing || _status == EmergencyStatus.active) {
      AppLogger.w('이미 긴급 상황이 진행중입니다');
      return;
    }

    _status = EmergencyStatus.preparing;
    _countdownSeconds = countdownSeconds;
    _errorMessage = null;

    // 긴급 데이터 생성
    _currentEmergency = EmergencyData.fromPosition(
      emergency_id: DateTime.now().millisecondsSinceEpoch.toString(),
      mmsi: mmsi,
      ship_nm: ship_nm,
      position: _currentPosition,
      reg_dt: DateTime.now(),
      status: EmergencyStatus.preparing,
      phone_no: '122',
    );

    // 위치 추적 시작
    if (!_isLocationTracking) {
      startLocationTracking();
    }

    notifyListeners();
    _startCountdown();
  }

  /// 카운트다운 처리
  void _startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        _countdownSeconds--;
        notifyListeners();

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
    _countdownTimer?.cancel();
    _status = EmergencyStatus.active;

    // 최신 위치 업데이트
    await updateCurrentLocation();

    if (_currentEmergency != null) {
      // 상태 업데이트
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

      // 데이터 저장
      await _saveEmergencyData(_currentEmergency!);

      // 전화 걸기
      final success = await _makeEmergencyCall('122');

      if (success) {
        _currentEmergency = _currentEmergency!.copyWith(
          emergency_status: EmergencyStatus.completed.name,
        );

        // SMS 발송 시도 (선택적)
        final message = _generateEmergencyMessage(_currentEmergency!);
        await _sendEmergencySMS(phoneNumber: '122', message: message);
      } else {
        _errorMessage = '긴급 전화 연결에 실패했습니다';
      }

      // 히스토리 업데이트
      await loadEmergencyHistory();
    }

    notifyListeners();
    AppLogger.d('긴급신고 활성화');

    // 3초 후 상태 초기화
    Future.delayed(const Duration(seconds: 3), () {
      resetEmergency();
    });
  }

  /// 긴급신고 취소
  void cancelEmergency() {
    _countdownTimer?.cancel();
    _countdownSeconds = 0;

    if (_currentEmergency != null) {
      _currentEmergency = _currentEmergency!.copyWith(
        emergency_status: EmergencyStatus.cancelled.name,
      );

      // 취소된 데이터도 저장
      _saveEmergencyData(_currentEmergency!);
    }

    _status = EmergencyStatus.cancelled;
    notifyListeners();

    AppLogger.d('긴급신고 취소');

    // 2초 후 초기화
    Future.delayed(const Duration(seconds: 2), () {
      resetEmergency();
    });
  }

  /// 상태 초기화
  void resetEmergency() {
    _countdownTimer?.cancel();
    _status = EmergencyStatus.idle;
    _countdownSeconds = 0;
    _currentEmergency = null;
    _errorMessage = null;
    notifyListeners();

    AppLogger.d('긴급 상태 초기화');
  }

  // ============================================
  // 전화/SMS 기능 (기존 Service 기능)
  // ============================================

  /// 긴급신고 전화 걸기
  Future<bool> _makeEmergencyCall(String phoneNumber) async {
    try {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: phoneNumber,
      );

      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
        AppLogger.d('긴급 전화 연결: $phoneNumber');
        return true;
      } else {
        AppLogger.e('전화 연결 실패: $phoneNumber');
        return false;
      }
    } catch (e) {
      AppLogger.e('긴급 전화 오류: $e');
      return false;
    }
  }

  /// SMS 발송
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
        AppLogger.d('긴급 SMS 발송: $phoneNumber');
        return true;
      } else {
        AppLogger.w('SMS 발송 불가');
        return false;
      }
    } catch (e) {
      AppLogger.e('SMS 발송 오류: $e');
      return false;
    }
  }

  /// 긴급 정보 문자열 생성
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
  // 데이터 저장/로드 (기존 Service 기능)
  // ============================================

  /// 긴급 상황 데이터 저장
  Future<void> _saveEmergencyData(EmergencyData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 현재 긴급 상황 저장
      await prefs.setString(_lastEmergencyKey, jsonEncode(data.toJson()));

      // 히스토리에 추가
      List<String> history = prefs.getStringList(_emergencyHistoryKey) ?? [];
      history.insert(0, jsonEncode(data.toJson()));

      // 최대 개수 유지
      if (history.length > _maxHistoryCount) {
        history = history.take(_maxHistoryCount).toList();
      }

      await prefs.setStringList(_emergencyHistoryKey, history);
      AppLogger.d('긴급 상황 데이터 저장 완료');
    } catch (e) {
      AppLogger.e('긴급 상황 데이터 저장 오류: $e');
    }
  }

  /// 긴급 히스토리 로드
  Future<void> loadEmergencyHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> history = prefs.getStringList(_emergencyHistoryKey) ?? [];

      _emergencyHistory = history.map((jsonStr) {
        try {
          return EmergencyData.fromJson(jsonDecode(jsonStr));
        } catch (e) {
          AppLogger.e('히스토리 항목 파싱 오류: $e');
          return null;
        }
      }).whereType<EmergencyData>().toList();

      notifyListeners();
      AppLogger.d('긴급 히스토리 로드: ${_emergencyHistory.length}건');
    } catch (e) {
      AppLogger.e('히스토리 로드 실패: $e');
    }
  }

  /// 긴급 히스토리 삭제
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emergencyHistoryKey);
      await prefs.remove(_lastEmergencyKey);
      _emergencyHistory = [];
      notifyListeners();
      AppLogger.d('긴급 히스토리 삭제 완료');
    } catch (e) {
      AppLogger.e('히스토리 삭제 실패: $e');
    }
  }

  // ============================================
  // 유틸리티 메서드
  // ============================================

  /// 날짜 포맷
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 오류 메시지 지우기
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _locationHistory.clear();
    super.dispose();
  }
}