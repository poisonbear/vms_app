import 'package:vms_app/core/infrastructure/network_client.dart';
import 'package:vms_app/core/exceptions/result.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/exceptions/error_handler.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/data/models/terms_model.dart';

import 'package:vms_app/core/constants/constants.dart';

/// 약관 정보 데이터소스 (기존 CmdSource)
class TermsDataSource {
  final dioRequest = DioRequest();

  /// 약관 목록 조회
  Future<Result<List<TermsModel>, AppException>> getCmdList() async {
    try {
      final String apiUrl = ApiConfig.termsList;

      if (apiUrl.isEmpty) {
        return const Failure(
            GeneralAppException('API URL이 설정되지 않았습니다', 'NO_API_URL'));
      }

      final response = await dioRequest.dio.get(apiUrl);

      // 프로덕션에서는 로그 레벨 조정 필요
      AppLogger.d('[API Call] Terms list fetched successfully');

      final list = (response.data as List)
          .map<TermsModel>((json) => TermsModel.fromJson(json))
          .toList();

      return Success(list);
    } catch (e) {
      AppLogger.e('Terms API Error: $e');
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef CmdSource = TermsDataSource;
