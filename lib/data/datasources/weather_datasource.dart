import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/infrastructure/network_client.dart';
import 'package:vms_app/core/exceptions/result.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/exceptions/error_handler.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/data/models/weather_model.dart';

/// 날씨 정보 데이터소스 (기존 WidSource)
class WeatherDataSource {
  final dioRequest = DioRequest();

  /// 날씨 정보 목록 조회
  Future<Result<List<WeatherModel>, AppException>> getWidList() async {
    try {
      final String apiUrl = dotenv.env['kdn_wid_select_weather_Info'] ?? '';

      if (apiUrl.isEmpty) {
        return const Failure(
          GeneralAppException('API URL이 설정되지 않았습니다', 'NO_API_URL'),
        );
      }

      final response = await dioRequest.dio.get(apiUrl);

      AppLogger.d('[API Call] Weather list fetched successfully');

      List<WeatherModel> weatherList = [];

      if (response.data is Map) {
        final List items = response.data['ts'] ?? [];
        weatherList = items.map<WeatherModel>((json) => WeatherModel.fromJson(json)).toList();
      } else if (response.data is List) {
        weatherList = (response.data as List)
            .map<WeatherModel>((json) => WeatherModel.fromJson(json))
            .toList();
      }

      return Success(weatherList);
    } catch (e) {
      AppLogger.e('Weather API Error', e);
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef WidSource = WeatherDataSource;