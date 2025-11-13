// lib/domain/repositories/navigation_repository.dart

import 'package:vms_app/data/models/navigation_model.dart';

/// 항행 정보 저장소 인터페이스
abstract class NavigationRepository {
  /// 항행 이력 조회
  Future<List<NavigationModel>> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  });

  /// 날씨 정보 조회 (시정/파고)
  Future<WeatherInfo?> getWeatherInfo();

  /// 항행 경보 메시지 조회
  Future<List<String>?> getNavigationWarnings();

  /// 항행 경보 상세 데이터 조회 (지도 표시용)
  Future<List<NavigationWarningModel>> getNavigationWarningDetails();
}
