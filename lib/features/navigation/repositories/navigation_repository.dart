// lib/features/navigation/repositories/navigation_repository.dart
import '../datasources/navigation_datasource.dart';
import '../models/navigation_history_model.dart';
import '../models/navigation_warning_model.dart';
import '../../weather/models/weather_model.dart';

/// 항행 관련 데이터 저장소
class NavigationRepository {
  const NavigationRepository({
    required NavigationDatasource datasource,
  }) : _datasource = datasource;

  final NavigationDatasource _datasource;

  /// 항행 이력 조회
  Future<List<NavigationHistoryModel>> getNavigationHistory({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) {
    return _datasource.getNavigationHistory(
      startDate: startDate,
      endDate: endDate,
      mmsi: mmsi,
      shipName: shipName,
    );
  }

  /// 날씨 정보 조회 (파고, 시정)
  Future<WeatherInfoModel?> getWeatherInfo() {
    return _datasource.getWeatherInfo();
  }

  /// 항행경보 조회
  Future<NavigationWarningModel?> getNavigationWarnings() {
    return _datasource.getNavigationWarnings();
  }

  /// 기상정보 목록 조회
  Future<List<WeatherModel>> getWeatherList() {
    return _datasource.getWeatherList();
  }

  /// 실시간 기상 데이터 조회
  Future<WeatherModel?> getCurrentWeather({
    double? latitude,
    double? longitude,
  }) {
    return _datasource.getCurrentWeather(
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// 특정 기간의 항행 이력 통계
  Future<Map<String, dynamic>> getNavigationStatistics({
    required String startDate,
    required String endDate,
    int? mmsi,
  }) async {
    try {
      final history = await getNavigationHistory(
        startDate: startDate,
        endDate: endDate,
        mmsi: mmsi,
      );

      // 기본 통계 계산
      final totalRecords = history.length;
      final uniqueShips = history.map((h) => h.mmsi).toSet().length;
      final dateRange = _calculateDateRange(history);

      return {
        'total_records': totalRecords,
        'unique_ships': uniqueShips,
        'date_range': dateRange,
        'records_per_ship': totalRecords > 0 ? (totalRecords / uniqueShips).toStringAsFixed(1) : '0',
      };
    } catch (e) {
      return {
        'total_records': 0,
        'unique_ships': 0,
        'date_range': {},
        'records_per_ship': '0',
        'error': e.toString(),
      };
    }
  }

  /// 날짜 범위 계산 헬퍼 메서드
  Map<String, String> _calculateDateRange(List<NavigationHistoryModel> history) {
    if (history.isEmpty) {
      return {'start': '', 'end': ''};
    }

    // regDt를 기준으로 정렬
    final sortedHistory = List<NavigationHistoryModel>.from(history)
      ..sort((a, b) => (a.regDt ?? 0).compareTo(b.regDt ?? 0));

    final startDate = sortedHistory.first.regDt;
    final endDate = sortedHistory.last.regDt;

    return {
      'start': startDate != null ? _formatDate(startDate) : '',
      'end': endDate != null ? _formatDate(endDate) : '',
    };
  }

  /// 날짜 포맷팅 헬퍼 메서드
  String _formatDate(int timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp.toString();
    }
  }
}