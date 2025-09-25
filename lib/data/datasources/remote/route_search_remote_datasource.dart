import 'package:vms_app/core/constants/api_endpoints.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:vms_app/core/infrastructure/network_client.dart';
import 'package:vms_app/core/exceptions/result.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/exceptions/error_handler.dart';
import 'package:vms_app/data/models/navigation/route_search_model.dart';
import 'package:vms_app/data/models/navigation/vessel_route_model.dart';

class RouteSearchSource {
  final dioRequest = DioRequest();

  Future<Result<VesselRouteResponse, AppException>> getVesselRoute({
    String? regDt,
    int? mmsi,
  }) async {
    try {
      final String apiUrl = ApiEndpoints.vesselRoute;

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
        List<PastRouteSearchModel> list = (response.data as List)
            .map((json) => PastRouteSearchModel.fromJson(json))
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
