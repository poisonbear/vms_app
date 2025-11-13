import 'package:vms_app/data/datasources/emergency_datasource.dart';
import 'package:vms_app/data/models/emergency_model.dart';
import 'package:vms_app/domain/repositories/emergency_repository.dart'
    as domain;
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 긴급 상황 저장소 구현
class EmergencyRepository implements domain.EmergencyRepository {
  final EmergencyDataSource _dataSource;

  EmergencyRepository(this._dataSource);

  /// 긴급 상황 데이터 저장
  @override
  Future<bool> saveEmergencyData(EmergencyData data) async {
    final result = await _dataSource.saveEmergencyData(data);

    return result.fold(
      onSuccess: (success) => success,
      onFailure: (error) {
        AppLogger.e('Emergency Repository Save Error: $error');
        return false;
      },
    );
  }

  /// 긴급 히스토리 로드
  @override
  Future<List<EmergencyData>> loadEmergencyHistory() async {
    final result = await _dataSource.loadEmergencyHistory();

    return result.fold(
      onSuccess: (history) => history,
      onFailure: (error) {
        AppLogger.e('Emergency Repository Load Error: $error');
        return [];
      },
    );
  }

  /// 마지막 긴급 상황 로드
  @override
  Future<EmergencyData?> loadLastEmergency() async {
    final result = await _dataSource.loadLastEmergency();

    return result.fold(
      onSuccess: (data) => data,
      onFailure: (error) {
        AppLogger.e('Emergency Repository Load Last Error: $error');
        return null;
      },
    );
  }

  /// 긴급 히스토리 삭제
  @override
  Future<bool> clearHistory() async {
    final result = await _dataSource.clearHistory();

    return result.fold(
      onSuccess: (success) => success,
      onFailure: (error) {
        AppLogger.e('Emergency Repository Clear Error: $error');
        return false;
      },
    );
  }

  /// 위치 추적 데이터 저장
  @override
  Future<bool> saveLocationTracking(
      List<LocationTrackingData> locations) async {
    final result = await _dataSource.saveLocationTracking(locations);

    return result.fold(
      onSuccess: (success) => success,
      onFailure: (error) {
        AppLogger.e('Emergency Repository Location Save Error: $error');
        return false;
      },
    );
  }

  /// 위치 추적 데이터 로드
  @override
  Future<List<LocationTrackingData>> loadLocationTracking() async {
    final result = await _dataSource.loadLocationTracking();

    return result.fold(
      onSuccess: (locations) => locations,
      onFailure: (error) {
        AppLogger.e('Emergency Repository Location Load Error: $error');
        return [];
      },
    );
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef EmergencyRepositoryImpl = EmergencyRepository;
