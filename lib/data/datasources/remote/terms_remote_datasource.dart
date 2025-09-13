import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/core/errors/result.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';
import 'package:vms_app/core/errors/error_handler.dart';

class CmdSource {
  final dioRequest = DioRequest();

  Future<Result<List<CmdModel>, AppException>> getCmdList() async {
    try {
      final String apiUrl = dotenv.env['kdn_usm_select_cmd_key'] ?? '';

      if (apiUrl.isEmpty) {
        return const Failure(GeneralAppException('API URL이 설정되지 않았습니다', 'NO_API_URL'));
      }

      final response = await dioRequest.dio.get(apiUrl);

      // 프로덕션에서는 로그 레벨 조정 필요
      AppLogger.d('[API Call] Terms list fetched successfully');

      final list = (response.data as List).map<CmdModel>((json) => CmdModel.fromJson(json)).toList();

      return Success(list);
    } catch (e) {
      AppLogger.e('Terms API Error: $e');
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }
}
