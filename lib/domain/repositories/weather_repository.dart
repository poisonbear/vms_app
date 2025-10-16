import 'package:vms_app/data/models/weather_model.dart';

/// 날씨 정보 저장소 인터페이스
abstract class WeatherRepository {
  /// 날씨 정보 목록 조회
  Future<List<WeatherModel>> getWidList();
}
