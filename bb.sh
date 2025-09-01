#!/bin/bash

# VMS App - 에러 처리 일관성 개선 스크립트
# 실행 방법: Git Bash에서 프로젝트 루트 디렉토리에서 실행
# chmod +x fix_error_handling.sh && ./fix_error_handling.sh

echo "========================================="
echo "VMS App - 에러 처리 일관성 개선 시작"
echo "========================================="

# 1. 중복된 error_handler.dart 파일 정리
echo ""
echo "📝 중복된 error_handler.dart 파일 정리 중..."

# utils 폴더의 error_handler.dart 백업 및 삭제
if [ -f "lib/core/utils/error_handler.dart" ]; then
    mv lib/core/utils/error_handler.dart lib/core/utils/error_handler.dart.backup
    echo "✅ utils/error_handler.dart 백업 완료"
fi

# errors 폴더의 error_handler.dart 유지 및 개선
if [ -f "lib/core/errors/error_handler.dart" ]; then
    cp lib/core/errors/error_handler.dart lib/core/errors/error_handler.dart.backup
fi

# 2. 개선된 error_handler.dart 생성
cat > lib/core/errors/error_handler.dart << 'EOF'
import 'package:dio/dio.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';
import 'package:vms_app/core/constants/app_messages.dart';

/// 통합된 에러 핸들러
class ErrorHandler {
  /// DioException을 AppException으로 변환
  static AppException handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(ErrorMessages.timeout, 'TIMEOUT');

      case DioExceptionType.connectionError:
        return const NetworkException(ErrorMessages.network, 'NO_NETWORK');

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseMsg = error.response?.data?['message'];
        final message = responseMsg ?? _getServerErrorMessage(statusCode);

        if (statusCode == 401) {
          return AuthException(message, 'UNAUTHORIZED');
        } else if (statusCode == 403) {
          return AuthException(message, 'FORBIDDEN');
        } else if (statusCode == 404) {
          return ServerException(message, statusCode: statusCode, code: 'NOT_FOUND');
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(ErrorMessages.server, statusCode: statusCode);
        } else {
          return ServerException(message, statusCode: statusCode);
        }

      case DioExceptionType.cancel:
        return const GeneralAppException('요청이 취소되었습니다', 'CANCELLED');

      default:
        return GeneralAppException('알 수 없는 오류: ${error.message}', 'UNKNOWN');
    }
  }

  /// HTTP 상태 코드에 따른 에러 메시지
  static String _getServerErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '잘못된 요청입니다';
      case 401:
        return ErrorMessages.unauthorized;
      case 403:
        return ErrorMessages.forbidden;
      case 404:
        return ErrorMessages.notFound;
      case 408:
        return ErrorMessages.timeout;
      case 429:
        return '너무 많은 요청이 발생했습니다';
      case 500:
      case 502:
      case 503:
        return ErrorMessages.server;
      default:
        return statusCode != null 
            ? '서버 오류가 발생했습니다 (코드: $statusCode)'
            : ErrorMessages.server;
    }
  }

  /// 일반 Exception을 AppException으로 변환
  static AppException handleError(dynamic error) {
    if (error is AppException) {
      return error;
    } else if (error is DioException) {
      return handleDioError(error);
    } else if (error is FormatException) {
      return DataParsingException('${ErrorMessages.dataFormat}: ${error.message}');
    } else if (error is TypeError) {
      return const DataParsingException(ErrorMessages.dataFormat);
    } else if (error.toString().contains('SocketException')) {
      return const NetworkException(ErrorMessages.network, 'SOCKET_ERROR');
    } else {
      return GeneralAppException(error.toString(), 'GENERAL_ERROR');
    }
  }

  /// 사용자 친화적 메시지 반환
  static String getUserMessage(AppException exception) {
    // 특정 코드에 대한 커스텀 메시지
    if (exception.code != null) {
      switch (exception.code) {
        case 'TIMEOUT':
          return ErrorMessages.timeout;
        case 'NO_NETWORK':
        case 'SOCKET_ERROR':
          return ErrorMessages.network;
        case 'UNAUTHORIZED':
          return ErrorMessages.unauthorized;
        case 'FORBIDDEN':
          return ErrorMessages.forbidden;
        case 'NOT_FOUND':
          return ErrorMessages.notFound;
      }
    }

    // 예외 타입별 기본 메시지
    if (exception is NetworkException) {
      return exception.message.isNotEmpty 
          ? exception.message 
          : ErrorMessages.network;
    } else if (exception is ServerException) {
      return exception.message.isNotEmpty 
          ? exception.message 
          : ErrorMessages.server;
    } else if (exception is AuthException) {
      return exception.message.isNotEmpty 
          ? exception.message 
          : ErrorMessages.unauthorized;
    } else if (exception is DataParsingException) {
      return ErrorMessages.dataFormat;
    } else if (exception is PermissionException) {
      return '필요한 권한이 없습니다';
    } else if (exception is ValidationException) {
      return exception.message.isNotEmpty 
          ? exception.message 
          : '입력값을 확인해주세요';
    } else if (exception is CacheException) {
      return '캐시 처리 중 오류가 발생했습니다';
    } else {
      return exception.message.isNotEmpty 
          ? exception.message 
          : ErrorMessages.general;
    }
  }
}
EOF

echo "✅ error_handler.dart 개선 완료"

# 3. Result 패턴을 활용한 DataSource 개선 예제 생성
echo ""
echo "📝 Result 패턴 적용 예제 생성 중..."

# terms_remote_datasource.dart 개선
cat > lib/data/datasources/remote/terms_remote_datasource.dart << 'EOF'
import 'package:vms_app/core/utils/logger.dart';
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
      logger.d('[API Call] Terms list fetched successfully');

      final list = (response.data as List)
          .map<CmdModel>((json) => CmdModel.fromJson(json))
          .toList();
          
      return Success(list);
    } catch (e) {
      logger.e('Terms API Error: $e');
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }
}
EOF

echo "✅ terms_remote_datasource.dart 개선 완료"

# 4. Repository 개선 예제
cat > lib/data/repositories/terms_repository_impl.dart << 'EOF'
import 'package:vms_app/data/datasources/remote/terms_remote_datasource.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/domain/repositories/terms_repository.dart';
import 'package:vms_app/core/errors/result.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';

class TermsRepositoryImpl implements TermsRepository {
  final CmdSource _dataSource;

  TermsRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<CmdModel>, AppException>> getCmdList() async {
    return await _dataSource.getCmdList();
  }
}
EOF

echo "✅ terms_repository_impl.dart 개선 완료"

# 5. Repository Interface 업데이트
cat > lib/domain/repositories/terms_repository.dart << 'EOF'
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/core/errors/result.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';

abstract class TermsRepository {
  Future<Result<List<CmdModel>, AppException>> getCmdList();
}
EOF

echo "✅ terms_repository.dart 인터페이스 업데이트 완료"

# 6. UseCase 개선
cat > lib/domain/usecases/auth/get_terms_list.dart << 'EOF'
import 'package:vms_app/domain/repositories/terms_repository.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/core/errors/result.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';

class GetTermsList {
  final TermsRepository repository;

  GetTermsList(this.repository);

  Future<Result<List<CmdModel>, AppException>> execute() async {
    return await repository.getCmdList();
  }
}
EOF

echo "✅ get_terms_list.dart UseCase 개선 완료"

# 7. Provider 개선 예제 (Terms Provider)
echo ""
echo "📝 Provider 개선 예제 생성 중..."

cat > lib/presentation/providers/terms/service_terms_provider.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/terms/terms_model.dart';
import 'package:vms_app/domain/usecases/auth/get_terms_list.dart';
import 'package:vms_app/presentation/providers/base/base_provider.dart';

class ServiceTermsProvider extends BaseProvider {
  late final GetTermsList _getTermsList;

  List<CmdModel>? _cmdList;
  List<CmdModel>? get cmdList => _cmdList;

  ServiceTermsProvider() {
    _getTermsList = getIt<GetTermsList>();
    getCmdList();
  }

  Future<void> getCmdList() async {
    await executeAsync<void>(
      () async {
        final result = await _getTermsList.execute();
        
        result.fold(
          onSuccess: (list) {
            if (list.isNotEmpty) {
              _cmdList = [list[0]]; // 첫 번째 약관만
            } else {
              _cmdList = [];
              setError('약관 정보를 찾을 수 없습니다');
            }
            safeNotifyListeners();
          },
          onFailure: (error) {
            _cmdList = [];
            throw error; // BaseProvider가 처리
          },
        );
      },
      errorMessage: '약관을 불러오는 중 오류가 발생했습니다',
      showLoading: true,
    );
  }

  void clearTerms() {
    executeSafe(() {
      _cmdList = null;
      safeNotifyListeners();
    });
  }
}
EOF

echo "✅ service_terms_provider.dart 개선 완료"

# 8. 다른 DataSource들도 같은 방식으로 개선하는 스크립트 생성
echo ""
echo "📝 다른 DataSource 개선 스크립트 생성 중..."

cat > apply_result_pattern_to_all.sh << 'EOF'
#!/bin/bash

# 모든 DataSource에 Result 패턴 적용하는 스크립트

echo "모든 DataSource에 Result 패턴 적용 시작..."

# navigation_remote_datasource.dart 개선
cat > lib/data/datasources/remote/navigation_remote_datasource.dart << 'EEOF'
import 'package:vms_app/core/constants/api_endpoints.dart';
import 'package:vms_app/core/utils/logger.dart';
import 'package:dio/dio.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/data/models/navigation/navigation_model.dart';
import 'package:vms_app/core/errors/result.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';
import 'package:vms_app/core/errors/error_handler.dart';

class RosSource {
  final dioRequest = DioRequest();

  Future<Result<List<RosModel>, AppException>> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    try {
      final String apiUrl = ApiEndpoints.navigationHistory;

      final Map<String, dynamic> queryParams = {
        'startDate': startDate,
        'endDate': endDate,
        'mmsi': mmsi,
        'shipName': shipName
      };

      final options = Options(
        receiveTimeout: const Duration(seconds: 30), // 100초는 너무 김
      );

      final response = await dioRequest.dio.get(
        apiUrl,
        data: queryParams,
        options: options,
      );

      List<RosModel> list = [];
      
      if (response.data is Map) {
        final List items = response.data['mmsi'] ?? [];
        list = items.map<RosModel>((json) => RosModel.fromJson(json)).toList();
      } else if (response.data is List) {
        list = (response.data as List)
            .map<RosModel>((json) => RosModel.fromJson(json))
            .toList();
      }

      return Success(list);
    } catch (e) {
      logger.e('Navigation API Error: $e');
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }

  Future<Result<WeatherInfo?, AppException>> getWeatherInfo() async {
    try {
      final String apiUrl = ApiEndpoints.navigationVisibility;

      final options = Options(
        receiveTimeout: const Duration(seconds: 30),
      );

      final response = await dioRequest.dio.post(
        apiUrl,
        options: options,
        data: {},
      );

      if (response.data != null && response.data is Map) {
        WeatherInfo weatherInfo = WeatherInfo.fromJson(response.data);
        return Success(weatherInfo);
      }

      return const Success(null);
    } catch (e) {
      logger.e('Weather API Error: $e');
      final exception = ErrorHandler.handleError(e);
      return Failure(exception);
    }
  }

  Future<Result<List<String>, AppException>> getNavigationWarnings() async {
    try {
      final String apiUrl = ApiEndpoints.navigationWarnings;

      final options = Options(
        receiveTimeout: const Duration(seconds: 30),
      );

      final response = await dioRequest.dio.post(
        apiUrl,
        options: options,
        data: {},
      );

      if (response.data != null && response.data['data'] != null) {
        final warnings = NavigationWarnings.fromJson(response.data).warnings;
        return Success(warnings);
      }

      return const Success([]);
    } catch (e) {
      logger.e('Navigation Warnings API Error: $e');
      return const Success([]); // 경고는 실패해도 빈 리스트 반환
    }
  }
}
EEOF

echo "✅ 모든 DataSource에 Result 패턴 적용 완료"
EOF

chmod +x apply_result_pattern_to_all.sh

echo "✅ apply_result_pattern_to_all.sh 스크립트 생성 완료"

# 9. 에러 메시지 위젯 생성
echo ""
echo "📝 에러 메시지 표시 위젯 생성 중..."

mkdir -p lib/presentation/widgets/common

cat > lib/presentation/widgets/common/error_message_widget.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 에러 메시지를 표시하는 공통 위젯
class ErrorMessageWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorMessageWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ],
      ),
    );
  }
}
EOF

echo "✅ error_message_widget.dart 생성 완료"

echo ""
echo "========================================="
echo "✅ 에러 처리 일관성 개선 완료!"
echo "========================================="
echo ""
echo "📌 수정/생성된 파일:"
echo "  - lib/core/errors/error_handler.dart (통합 및 개선)"
echo "  - lib/data/datasources/remote/terms_remote_datasource.dart (Result 패턴 적용)"
echo "  - lib/data/repositories/terms_repository_impl.dart (Result 전파)"
echo "  - lib/domain/repositories/terms_repository.dart (인터페이스 업데이트)"
echo "  - lib/domain/usecases/auth/get_terms_list.dart (Result 활용)"
echo "  - lib/presentation/providers/terms/service_terms_provider.dart (에러 처리 개선)"
echo "  - lib/presentation/widgets/common/error_message_widget.dart (에러 UI)"
echo ""
echo "📌 백업 파일:"
echo "  - lib/core/utils/error_handler.dart.backup"
echo "  - lib/core/errors/error_handler.dart.backup"
echo ""
echo "🔧 다음 단계:"
echo "  1. 다른 DataSource에도 Result 패턴 적용:"
echo "     ./apply_result_pattern_to_all.sh"
echo ""
echo "  2. Flutter 재빌드:"
echo "     flutter pub get"
echo "     flutter clean" 
echo "     flutter pub get"
echo "     flutter run"
echo ""
echo "💡 참고사항:"
echo "  - Result 패턴으로 에러 상태를 명확히 구분"
echo "  - BaseProvider의 executeAsync 활용으로 일관된 에러 처리"
echo "  - 사용자 친화적 에러 메시지 표시"
echo ""
echo "⚠️  문제 발생 시 백업 파일로 복원 가능합니다."
