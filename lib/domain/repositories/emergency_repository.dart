import 'package:vms_app/data/models/emergency_model.dart';

/// 긴급 상황 저장소 인터페이스
abstract class EmergencyRepository {
  /// 긴급 상황 데이터 저장
  Future<bool> saveEmergencyData(EmergencyData data);

  /// 긴급 히스토리 로드
  Future<List<EmergencyData>> loadEmergencyHistory();

  /// 마지막 긴급 상황 로드
  Future<EmergencyData?> loadLastEmergency();

  /// 긴급 히스토리 삭제
  Future<bool> clearHistory();

  /// 위치 추적 데이터 저장
  Future<bool> saveLocationTracking(List<LocationTrackingData> locations);

  /// 위치 추적 데이터 로드
  Future<List<LocationTrackingData>> loadLocationTracking();
}
