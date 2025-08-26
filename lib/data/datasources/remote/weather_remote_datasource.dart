import 'package:vms_app/core/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/data/models/weather/weather_model.dart';

class WidSource {
  final dioRequest = DioRequest();

  Future<List<WidModel>> getWidList() async {
    try {
      final String apiUrl = dotenv.env['kdn_wid_select_weather_Info'] ?? '';
      final response = await dioRequest.dio.get(apiUrl);

      // 로그 출력
      logger.d('[API URL] : $apiUrl');
      logger.d('[Response] : ${response.data}');

      if (response.data is Map) {
        final List items = response.data['ts'] ?? [];
        return items.map<WidModel>((json) => WidModel.fromJson(json)).toList();
      }

      if (response.data is List) {
        return (response.data as List)
            .map<WidModel>((json) => WidModel.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      // 예외 처리
      logger.e('Error occurred: $e');
      return [];
    }
  }
}
