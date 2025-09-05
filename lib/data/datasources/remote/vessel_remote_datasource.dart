import 'package:vms_app/core/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';
import 'package:vms_app/core/errors/result.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';
import 'package:vms_app/core/errors/error_handler.dart';
import 'package:vms_app/core/constants/app_durations.dart';

class VesselSearchSource {
  final dioRequest = DioRequest();

  Future<Result<List<VesselSearchModel>, AppException>> getVesselList({
    String? regDt,
    int? mmsi,
  }) async {
    try {
      final String apiUrl = dotenv.env['kdn_gis_select_vessel_List'] ?? '';

      if (apiUrl.isEmpty) {
        return const Failure(
          GeneralAppException('API URL이 설정되지 않았습니다', 'NO_API_URL'),
        );
      }

      final Map<String, dynamic> queryParams = {
        if (mmsi != null) 'mmsi': mmsi,
        if (regDt != null) 'reg_dt': regDt,
      };

      final options = DioRequest.createOptions(
        timeout: AppDurations.apiLongTimeout,
      );

      final response = await dioRequest.dio.get(
        apiUrl,
        data: queryParams,
        options: options,
      );

      List<VesselSearchModel> vessels = [];

      if (response.data is Map) {
        final List items = response.data['mmsi'] ?? [];
        vessels = items
            .map<VesselSearchModel>((json) => VesselSearchModel.fromJson(json))
            .toList();
      } else if (response.data is List) {
        vessels = (response.data as List)
            .map<VesselSearchModel>((json) => VesselSearchModel.fromJson(json))
            .toList();
      }

      logger.d('Vessel list fetched: ${vessels.length} items');
      return Success(vessels);
    } catch (e) {
      logger.e('Vessel API Error: $e');
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }
}
