import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/infrastructure/network_client.dart';
import 'package:vms_app/core/exceptions/result.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/exceptions/error_handler.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';
import 'package:vms_app/core/services/cache_service.dart';

class VesselSearchSourceCached {
  final dioRequest = DioRequest();

  Future<Result<List<VesselSearchModel>, AppException>> getVesselList({
    String? regDt,
    int? mmsi,
  }) async {
    try {
      // 캐시 키 생성
      final cacheKey = 'vessel_list_${mmsi ?? 'all'}_${regDt ?? 'latest'}';

      // 캐시 확인
      final cachedData = await CacheManager.getCache(cacheKey);
      if (cachedData != null) {
        AppLogger.d('Vessel list from cache');
        final vessels =
            (cachedData as List).map<VesselSearchModel>((json) => VesselSearchModel.fromJson(json)).toList();
        return Success(vessels);
      }

      // 캐시가 없으면 API 호출
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
        timeout: AppDurations.seconds60,
      );

      final response = await dioRequest.dio.get(
        apiUrl,
        data: queryParams,
        options: options,
      );

      List<VesselSearchModel> vessels = [];
      List<dynamic> dataToCache = [];

      if (response.data is Map) {
        final List items = response.data['mmsi'] ?? [];
        vessels = items.map<VesselSearchModel>((json) => VesselSearchModel.fromJson(json)).toList();
        dataToCache = items;
      } else if (response.data is List) {
        vessels = (response.data as List).map<VesselSearchModel>((json) => VesselSearchModel.fromJson(json)).toList();
        dataToCache = response.data;
      }

      // 응답을 캐시에 저장
      await CacheManager.saveCache(cacheKey, dataToCache);

      AppLogger.d('Vessel list fetched and cached: ${vessels.length} items');
      return Success(vessels);
    } catch (e) {
      AppLogger.e('Vessel API Error: $e');
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }
}
