import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/exceptions/result.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/data/models/emergency_model.dart';

/// 긴급 상황 로컬 데이터소스
class EmergencyDataSource {
  static const String _emergencyHistoryKey = 'emergency_history';
  static const String _lastEmergencyKey = 'last_emergency';
  static const int _maxHistoryCount = 50;

  /// 긴급 상황 데이터 저장
  Future<Result<bool, AppException>> saveEmergencyData(
      EmergencyData data) async {
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

      return const Success(true);
    } catch (e) {
      AppLogger.e('긴급 상황 데이터 저장 오류: $e');
      return const Failure(
        GeneralAppException('데이터 저장 실패', 'SAVE_ERROR'),
      );
    }
  }

  /// 긴급 히스토리 로드
  Future<Result<List<EmergencyData>, AppException>>
      loadEmergencyHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> history =
          prefs.getStringList(_emergencyHistoryKey) ?? [];

      final emergencyHistory = history
          .map((jsonStr) {
            try {
              return EmergencyData.fromJson(jsonDecode(jsonStr));
            } catch (e) {
              AppLogger.e('히스토리 항목 파싱 오류: $e');
              return null;
            }
          })
          .whereType<EmergencyData>()
          .toList();

      AppLogger.d('긴급 히스토리 로드: ${emergencyHistory.length}건');
      return Success(emergencyHistory);
    } catch (e) {
      AppLogger.e('히스토리 로드 실패: $e');
      return const Failure(
        GeneralAppException('히스토리 로드 실패', 'LOAD_ERROR'),
      );
    }
  }

  /// 마지막 긴급 상황 로드
  Future<Result<EmergencyData?, AppException>> loadLastEmergency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? lastEmergencyJson = prefs.getString(_lastEmergencyKey);

      if (lastEmergencyJson == null) {
        return const Success(null);
      }

      final lastEmergency =
          EmergencyData.fromJson(jsonDecode(lastEmergencyJson));
      return Success(lastEmergency);
    } catch (e) {
      AppLogger.e('마지막 긴급 상황 로드 실패: $e');
      return const Failure(
        GeneralAppException('데이터 로드 실패', 'LOAD_ERROR'),
      );
    }
  }

  /// 긴급 히스토리 삭제
  Future<Result<bool, AppException>> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_emergencyHistoryKey);
      await prefs.remove(_lastEmergencyKey);

      AppLogger.d('긴급 히스토리 삭제 완료');
      return const Success(true);
    } catch (e) {
      AppLogger.e('히스토리 삭제 실패: $e');
      return const Failure(
        GeneralAppException('히스토리 삭제 실패', 'DELETE_ERROR'),
      );
    }
  }

  /// 위치 추적 데이터 저장
  Future<Result<bool, AppException>> saveLocationTracking(
    List<LocationTrackingData> locations,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final jsonList =
          locations.map((loc) => jsonEncode(loc.toJson())).toList();
      await prefs.setStringList('location_tracking', jsonList);

      AppLogger.d('위치 추적 데이터 저장: ${locations.length}건');
      return const Success(true);
    } catch (e) {
      AppLogger.e('위치 추적 데이터 저장 오류: $e');
      return const Failure(
        GeneralAppException('위치 데이터 저장 실패', 'SAVE_ERROR'),
      );
    }
  }

  /// 위치 추적 데이터 로드
  Future<Result<List<LocationTrackingData>, AppException>>
      loadLocationTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList('location_tracking');

      if (jsonList == null) {
        return const Success([]);
      }

      final locations = jsonList
          .map((jsonStr) {
            try {
              return LocationTrackingData.fromJson(jsonDecode(jsonStr));
            } catch (e) {
              AppLogger.e('위치 데이터 파싱 오류: $e');
              return null;
            }
          })
          .whereType<LocationTrackingData>()
          .toList();

      AppLogger.d('위치 추적 데이터 로드: ${locations.length}건');
      return Success(locations);
    } catch (e) {
      AppLogger.e('위치 추적 데이터 로드 실패: $e');
      return const Failure(
        GeneralAppException('위치 데이터 로드 실패', 'LOAD_ERROR'),
      );
    }
  }
}
