import 'package:vms_app/data/datasources/remote/navigation_remote_datasource.dart';
import 'package:vms_app/data/models/navigation/navigation_model.dart';
import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/core/utils/app_logger.dart';

class NavigationRepositoryImpl implements NavigationRepository {
  final RosSource _dataSource;

  NavigationRepositoryImpl(this._dataSource);

  @override
  Future<List<RosModel>> getRosList({
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
      onSuccess: (list) => list,
      onFailure: (error) {
        AppLogger.e('Navigation Repository Error: $error');
        return [];
      },
    );
  }

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

  @override
  Future<List<String>> getNavigationWarnings() async {
    final result = await _dataSource.getNavigationWarnings();
    
    return result.fold(
      onSuccess: (warnings) => warnings,
      onFailure: (error) {
        AppLogger.e('Navigation Warnings Repository Error: $error');
        return [];
      },
    );
  }
}
