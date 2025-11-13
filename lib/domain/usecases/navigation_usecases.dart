import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/data/models/navigation_model.dart';

/// 항행 관련 UseCase 모음
class NavigationUseCases {
  final NavigationRepository _repository;

  NavigationUseCases(this._repository);

  /// 항행 이력 조회
  Future<List<NavigationModel>> getNavigationHistory({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    return await _repository.getRosList(
      startDate: startDate,
      endDate: endDate,
      mmsi: mmsi,
      shipName: shipName,
    );
  }

  /// 날씨 정보 조회 (시정/파고)
  Future<WeatherInfo?> getWeatherInfo() async {
    return await _repository.getWeatherInfo();
  }

  /// 항행 경보 조회
  Future<List<String>?> getNavigationWarnings() async {
    return await _repository.getNavigationWarnings();
  }

  /// 항행 경보 상세 데이터 조회 (지도 표시용)
  Future<List<NavigationWarningModel>> getNavigationWarningDetails() async {
    return await _repository.getNavigationWarningDetails();
  }
}

// ===== 개별 UseCase 클래스들 (기존 호환성 유지) =====

/// 항행 이력 조회 UseCase (기존 GetNavigationHistory)
class GetNavigationHistory {
  final NavigationRepository repository;

  GetNavigationHistory(this.repository);

  Future<List<NavigationModel>> execute({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    return await repository.getRosList(
      startDate: startDate,
      endDate: endDate,
      mmsi: mmsi,
      shipName: shipName,
    );
  }
}

/// 파고/시정 정보 조회 UseCase (기존 GetWeatherInfo)
/// NavigationRepository를 사용합니다 (WeatherRepository 아님!)
class GetWeatherInfo {
  final NavigationRepository repository;

  GetWeatherInfo(this.repository);

  Future<WeatherInfo?> execute() async {
    return await repository.getWeatherInfo();
  }
}

/// 항행 경보 조회 UseCase
class GetNavigationWarnings {
  final NavigationRepository repository;

  GetNavigationWarnings(this.repository);

  Future<List<String>?> execute() async {
    return await repository.getNavigationWarnings();
  }
}

/// 항행 경보 상세 데이터 조회 UseCase (지도 표시용)
class GetNavigationWarningDetails {
  final NavigationRepository repository;

  GetNavigationWarningDetails(this.repository);

  Future<List<NavigationWarningModel>> execute() async {
    return await repository.getNavigationWarningDetails();
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef GetRosList = GetNavigationHistory;
typedef GetVisibilityInfo = GetWeatherInfo;
typedef GetNavigationWarnInfo = GetNavigationWarnings;
