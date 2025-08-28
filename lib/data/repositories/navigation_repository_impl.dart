import 'package:vms_app/data/datasources/remote/navigation_remote_datasource.dart';
import 'package:vms_app/data/models/navigation/navigation_model.dart';
import 'package:vms_app/domain/repositories/navigation_repository.dart';

class NavigationRepositoryImpl implements NavigationRepository {
  final RosSource _dataSource;

  NavigationRepositoryImpl(this._dataSource);

  // 기존 메서드 유지 (UseCase에서 사용)
  @override
  Future<List<RosModel>> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) {
    return _dataSource.getRosList(
      startDate: startDate,
      endDate: endDate,
      mmsi: mmsi,
      shipName: shipName,
    );
  }

  // 누락된 getNavigationHistory 메서드 구현 (인터페이스에서 요구)
  @override
  Future<List<dynamic>> getNavigationHistory({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) {
    // getRosList와 동일한 구현 (하위 호환성)
    return getRosList(
      startDate: startDate,
      endDate: endDate,
      mmsi: mmsi,
      shipName: shipName,
    ).then((list) => list.cast<dynamic>());
  }

  // 추가 메서드들
  @override
  Future<WeatherInfo?> getWeatherInfo() {
    return _dataSource.getWeatherInfo();
  }

  @override
  Future<List<String>?> getNavigationWarnings() {
    return _dataSource.getNavigationWarnings();
  }
}
