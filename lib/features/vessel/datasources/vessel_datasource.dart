import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/logger.dart';
import '../models/vessel_model.dart';
import '../models/vessel_route_model.dart';

/// 선박 데이터 소스
class VesselDatasource {
  const VesselDatasource({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 선박 목록 조회
  Future<List<VesselModel>> getVesselList({
    String? regDt,
    int? mmsi,
  }) async {
    try {
      final String apiUrl = dotenv.env['kdn_gis_select_vessel_List'] ?? '';

      final Map<String, dynamic> queryParams = {
        'mmsi': mmsi,
        'reg_dt': regDt,
      };

      final options = Options(
        receiveTimeout: const Duration(seconds: 100),
      );

      final response = await _apiClient.dio.get(
        apiUrl,
        data: queryParams,
        options: options,
      );

      logger.d("[API URL] : $apiUrl");
      logger.d("[Response] : ${response.data}");

      // Map일 경우 (mmsi 키로 래핑된 경우)
      if (response.data is Map) {
        final List items = response.data['mmsi'] ?? [];
        return items.map<VesselModel>((json) => VesselModel.fromJson(json)).toList();
      }

      // List일 경우 (직접 배열)
      if (response.data is List) {
        return (response.data as List)
            .map<VesselModel>((json) => VesselModel.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      logger.e("Error in getVesselList: $e");
      return [];
    }
  }

  /// 선박 항로 조회
  Future<VesselRouteResponse> getVesselRoute({
    String? regDt,
    int? mmsi,
  }) async {
    try {
      final String apiUrl = dotenv.env['kdn_gis_select_vessel_Route'] ?? '';

      final Map<String, dynamic> queryParams = {
        'mmsi': mmsi,
        'reg_dt': regDt,
      };

      final options = Options(
        receiveTimeout: const Duration(seconds: 100),
      );

      final response = await _apiClient.dio.get(
        apiUrl,
        data: queryParams,
        options: options,
      );

      logger.d("[API URL] : $apiUrl");
      logger.d("[param] : $queryParams");
      logger.d("[Response] : ${response.data}");

      // 응답 데이터가 Map인 경우
      if (response.data is Map) {
        return VesselRouteResponse.fromJson(response.data);
      }

      // List 형태로 온다면, 임시로 past에 담고 pred는 빈 리스트로 처리
      if (response.data is List) {
        List<PastRouteModel> list = (response.data as List)
            .map((json) => PastRouteModel.fromJson(json))
            .toList();
        return VesselRouteResponse(pred: [], past: list);
      }

      return const VesselRouteResponse(pred: [], past: []);
    } catch (e) {
      logger.e("Error in getVesselRoute: $e");
      return const VesselRouteResponse(pred: [], past: []);
    }
  }
}