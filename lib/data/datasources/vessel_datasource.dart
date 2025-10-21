import 'package:dio/dio.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/infrastructure/network_client.dart';
import 'package:vms_app/core/exceptions/result.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/exceptions/error_handler.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/data/models/vessel_model.dart';

/// 선박 및 항로 데이터소스
class VesselDataSource {
  final dioRequest = DioRequest();

  /// 선박 목록 조회
  Future<Result<List<VesselModel>, AppException>> getVesselList({
    String? regDt,
    int? mmsi,
  }) async {
    try {
      final String apiUrl = ApiConfig.vesselList;

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

      List<VesselModel> vessels = [];

      if (response.data is Map) {
        final List items = response.data['mmsi'] ?? [];
        vessels = items
            .map<VesselModel>((json) => VesselModel.fromJson(json))
            .toList();
      } else if (response.data is List) {
        vessels = (response.data as List)
            .map<VesselModel>((json) => VesselModel.fromJson(json))
            .toList();
      }

      AppLogger.d('Vessel list fetched: ${vessels.length} items');
      return Success(vessels);
    } catch (e) {
      AppLogger.e('Vessel API Error: $e');
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }

  /// 선박 항로 조회 (과거 + 예측)
  Future<Result<VesselRouteResponse, AppException>> getVesselRoute({
    String? regDt,
    int? mmsi,
  }) async {
    try {
      final String apiUrl = ApiConfig.vesselRoute;

      if (apiUrl.isEmpty) {
        return const Failure(
          GeneralAppException('API URL이 설정되지 않았습니다', 'NO_API_URL'),
        );
      }

      final Map<String, dynamic> queryParams = {
        'mmsi': mmsi,
        'reg_dt': regDt,
      };

      final options = Options(
        receiveTimeout: const Duration(seconds: 100),
      );

      final response = await dioRequest.dio.get(
        apiUrl,
        data: queryParams,
        options: options,
      );

      AppLogger.d('[API Call] Vessel route fetched successfully');

      VesselRouteResponse vesselRoute;

      if (response.data is Map) {
        vesselRoute = VesselRouteResponse.fromJson(response.data);
      } else if (response.data is List) {
        List<PastRouteModel> list = (response.data as List)
            .map((json) => PastRouteModel.fromJson(json))
            .toList();
        vesselRoute = VesselRouteResponse(pred: [], past: list);
      } else {
        vesselRoute = VesselRouteResponse(pred: [], past: []);
      }

      return Success(vesselRoute);
    } catch (e) {
      AppLogger.e('Vessel Route API Error', e);
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }
}
