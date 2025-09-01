#!/bin/bash

# VMS App - Flutter Analyze 에러 수정 스크립트
# 실행 방법: Git Bash에서 프로젝트 루트 디렉토리에서 실행
# chmod +x fix_analyze_errors.sh && ./fix_analyze_errors.sh

echo "========================================="
echo "VMS App - Flutter Analyze 에러 수정"
echo "========================================="

# 1. vessel_repository_impl.dart 수정 (Result 패턴 제거 - 기존 인터페이스 유지)
echo ""
echo "📝 vessel_repository_impl.dart 수정 중..."

cat > lib/data/repositories/vessel_repository_impl.dart << 'EOF'
import 'package:vms_app/data/datasources/remote/vessel_remote_datasource.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';
import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/core/utils/logger.dart';

class VesselRepositoryImpl implements VesselRepository {
  final VesselSearchSource _vesselSearchSource;

  VesselRepositoryImpl(this._vesselSearchSource);

  @override
  Future<List<VesselSearchModel>> getVesselList({String? regDt, int? mmsi}) async {
    try {
      // DataSource는 Result를 반환하지만, Repository는 기존 인터페이스 유지
      final result = await _vesselSearchSource.getVesselList(
        regDt: regDt,
        mmsi: mmsi,
      );
      
      return result.fold(
        onSuccess: (vessels) => vessels,
        onFailure: (error) {
          logger.e('Vessel Repository Error: $error');
          // 에러 발생 시 빈 리스트 반환 (기존 동작 유지)
          // 또는 에러를 throw하려면: throw error;
          return [];
        },
      );
    } catch (e) {
      logger.e('Vessel Repository Error: $e');
      return [];
    }
  }
}
EOF

echo "✅ vessel_repository_impl.dart 수정 완료"

# 2. vessel_repository.dart 인터페이스 확인 및 수정
echo ""
echo "📝 vessel_repository.dart 인터페이스 확인 중..."

cat > lib/domain/repositories/vessel_repository.dart << 'EOF'
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';

abstract class VesselRepository {
  Future<List<VesselSearchModel>> getVesselList({String? regDt, int? mmsi});
}
EOF

echo "✅ vessel_repository.dart 인터페이스 유지"

# 3. warningPop 함수 정의 추가 (dio_client.dart에 추가)
echo ""
echo "📝 warningPop 함수 정의 추가 중..."

# dio_client.dart 백업
cp lib/core/network/dio_client.dart lib/core/network/dio_client.dart.backup

# warningPop 함수가 포함된 dio_client.dart 재생성
cat > lib/core/network/dio_client.dart << 'EOF'
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/constants/app_durations.dart';
import 'package:vms_app/core/constants/network_constants.dart';
import 'package:vms_app/core/utils/logger.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';

/// Dio HTTP 클라이언트 래퍼
class DioRequest {
  late final Dio _dio;
  
  Dio get dio => _dio;

  DioRequest() {
    _dio = Dio(_createBaseOptions());
    _setupInterceptors();
  }

  /// 기본 옵션 생성
  BaseOptions _createBaseOptions() {
    return BaseOptions(
      contentType: Headers.jsonContentType,
      connectTimeout: AppDurations.apiTimeout,
      receiveTimeout: AppDurations.apiTimeout,
      headers: {
        'User-Agent': NetworkConstants.userAgent,
        ...NetworkConstants.defaultHeaders,
      },
    );
  }

  /// 인터셉터 설정
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          logger.d('API Request: ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          logger.d('API Response: ${response.statusCode}');
          handler.next(response);
        },
        onError: (DioException error, handler) {
          logger.e('API Error: ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  /// 옵션 생성 헬퍼 메서드
  static Options createOptions({
    Duration? timeout,
    Map<String, dynamic>? headers,
  }) {
    return Options(
      receiveTimeout: timeout ?? AppDurations.apiTimeout,
      headers: headers,
    );
  }
}

/// 페이지 전환 애니메이션
Route createSlideTransition(
  Widget page, {
  Offset begin = const Offset(1.0, 0.0),
}) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: curve),
      );
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
    transitionDuration: AppDurations.animationNormal,
  );
}

/// 경고 팝업
Future<void> warningPop(
  BuildContext context,
  String title,
  Color titleColor,
  String detail,
  Color detailColor,
  String alarmIcon,
  Color shadowColor,
) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      return Stack(
        children: [
          // 배경
          Positioned.fill(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    shadowColor.withOpacity(0.1),
                    shadowColor.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
          // 팝업 내용
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 아이콘
                    if (alarmIcon.isNotEmpty)
                      SvgPicture.asset(
                        alarmIcon,
                        width: 48,
                        height: 48,
                        colorFilter: ColorFilter.mode(titleColor, BlendMode.srcIn),
                      ),
                    const SizedBox(height: 16),
                    // 제목
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // 상세 내용
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 14,
                        color: detailColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // 확인 버튼
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: titleColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// 상세 경고 팝업
Future<void> warningPopdetail(
  BuildContext context,
  String title,
  Color titleColor,
  String detail,
  Color detailColor,
  String additionalInfo,
  String alarmIcon,
  Color shadowColor,
) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      return Stack(
        children: [
          // 배경
          Positioned.fill(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    shadowColor.withOpacity(0.1),
                    shadowColor.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
          // 팝업 내용
          Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 아이콘
                    if (alarmIcon.isNotEmpty)
                      SvgPicture.asset(
                        alarmIcon,
                        width: 48,
                        height: 48,
                        colorFilter: ColorFilter.mode(titleColor, BlendMode.srcIn),
                      ),
                    const SizedBox(height: 16),
                    // 제목
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // 상세 내용
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 14,
                        color: detailColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (additionalInfo.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          additionalInfo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // 버튼들
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 취소 버튼
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            '취소',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        // 확인 버튼
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: titleColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '확인',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
EOF

echo "✅ warningPop 함수 추가 완료"

# 4. error_message_widget.dart import 수정
echo ""
echo "📝 error_message_widget.dart import 수정 중..."

cat > lib/presentation/widgets/common/error_message_widget.dart << 'EOF'
import 'package:flutter/material.dart';

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
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '다시 시도',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
EOF

echo "✅ error_message_widget.dart import 수정 완료"

# 5. AppDurations 상수 파일이 없으면 생성
if [ ! -f "lib/core/constants/app_durations.dart" ]; then
echo ""
echo "📝 app_durations.dart 생성 중..."

cat > lib/core/constants/app_durations.dart << 'EOF'
/// 시간 관련 상수
class AppDurations {
  AppDurations._();

  // API 타임아웃
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration apiLongTimeout = Duration(seconds: 60);
  static const Duration apiShortTimeout = Duration(seconds: 10);
  
  // 애니메이션
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationLong = Duration(milliseconds: 500);
  
  // 디바운스
  static const Duration debounceSearch = Duration(milliseconds: 500);
  static const Duration debounceInput = Duration(milliseconds: 300);
  
  // 스낵바
  static const Duration snackbarShort = Duration(seconds: 2);
  static const Duration snackbarNormal = Duration(seconds: 3);
  static const Duration snackbarLong = Duration(seconds: 5);
}
EOF

echo "✅ app_durations.dart 생성 완료"
fi

# 6. NetworkConstants 상수 파일이 없으면 생성
if [ ! -f "lib/core/constants/network_constants.dart" ]; then
echo ""
echo "📝 network_constants.dart 생성 중..."

cat > lib/core/constants/network_constants.dart << 'EOF'
/// 네트워크 관련 상수
class NetworkConstants {
  NetworkConstants._();

  // User-Agent
  static const String userAgent = 'VMS-App/1.0';
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'ngrok-skip-browser-warning': '100',
  };
  
  // Retry
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
EOF

echo "✅ network_constants.dart 생성 완료"
fi

# 7. 검증 스크립트
echo ""
echo "📝 검증 스크립트 생성 중..."

cat > verify_fixes.sh << 'EOF'
#!/bin/bash

echo "========================================="
echo "에러 수정 검증 중..."
echo "========================================="

# Flutter analyze 실행
echo ""
echo "Flutter analyze 실행 중..."
flutter analyze | grep -e "error"

if [ $? -eq 0 ]; then
    echo ""
    echo "⚠️  아직 에러가 남아있습니다."
else
    echo ""
    echo "✅ 모든 에러가 해결되었습니다!"
fi

# Warning 확인
echo ""
echo "Warning 확인 중..."
flutter analyze | grep -e "warning" | head -5

echo ""
echo "========================================="
echo "검증 완료"
echo "========================================="
EOF

chmod +x verify_fixes.sh

echo "✅ verify_fixes.sh 생성 완료"

echo ""
echo "========================================="
echo "✅ Flutter Analyze 에러 수정 완료!"
echo "========================================="
echo ""
echo "📌 수정된 파일:"
echo "  - lib/data/repositories/vessel_repository_impl.dart"
echo "  - lib/domain/repositories/vessel_repository.dart"
echo "  - lib/core/network/dio_client.dart (warningPop 함수 추가)"
echo "  - lib/presentation/widgets/common/error_message_widget.dart"
echo ""
echo "📌 생성된 파일:"
echo "  - lib/core/constants/app_durations.dart"
echo "  - lib/core/constants/network_constants.dart"
echo ""
echo "🔧 다음 단계:"
echo "  1. 수정 검증:"
echo "     ./verify_fixes.sh"
echo ""
echo "  2. Flutter 재빌드:"
echo "     flutter pub get"
echo "     flutter clean"
echo "     flutter pub get"
echo "     flutter run"
echo ""
echo "💡 해결된 에러:"
echo "  ✅ vessel_repository_impl.dart - 반환 타입 불일치"
echo "  ✅ warningPop 함수 미정의"
echo "  ✅ warningPopdetail 함수 미정의"
echo "  ✅ 사용하지 않는 import 제거"
