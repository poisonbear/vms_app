import 'package:vms_app/data/datasources/navigation_datasource.dart';
import 'package:vms_app/data/models/navigation_model.dart';
import 'package:vms_app/domain/repositories/navigation_repository.dart'
    as domain;
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 항행 정보 저장소 구현
class NavigationRepository implements domain.NavigationRepository {
  final NavigationDataSource _dataSource;

  NavigationRepository(this._dataSource);

  /// 항행 이력 조회
  @override
  Future<List<NavigationModel>> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    final result = await _dataSource.getRosList(
      startDate: startDate,
      endDate: endDate,
      mmsi: mmsi,
      shipName: shipName,
    );

    return result.fold(
      onSuccess: (list) {
        AppLogger.d(
            'NavigationRepository: Returning ${list.length} NavigationModel items');
        return list;
      },
      onFailure: (error) {
        AppLogger.e('Navigation Repository Error: $error');
        return [];
      },
    );
  }

  /// 날씨 정보 조회 (시정/파고)
  @override
  Future<WeatherInfo?> getWeatherInfo() async {
    final result = await _dataSource.getWeatherInfo();

    return result.fold(
      onSuccess: (info) => info,
      onFailure: (error) {
        AppLogger.e('Weather Info Repository Error: $error');
        return null;
      },
    );
  }

  /// 항행 경보 조회
  @override
  Future<List<String>?> getNavigationWarnings() async {
    final result = await _dataSource.getNavigationWarnings();

    return result.fold(
      onSuccess: (warnings) => warnings,
      onFailure: (error) {
        AppLogger.e('Navigation Warnings Repository Error: $error');
        return [];
      },
    );
  }

  /// 항행 경보 상세 데이터 조회 (지도 표시용)
  @override
  Future<List<NavigationWarningModel>> getNavigationWarningDetails() async {
    final result = await _dataSource.getNavigationWarningDetails();

    return result.fold(
      onSuccess: (warnings) {
        AppLogger.d(
            'NavigationRepository: Returning ${warnings.length} NavigationWarningModel items');
        return warnings;
      },
      onFailure: (error) {
        AppLogger.e('Navigation Warning Details Repository Error: $error');
        return [];
      },
    );
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef NavigationRepositoryImpl = NavigationRepository;
