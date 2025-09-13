import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/constants/app_durations.dart';
import 'package:vms_app/core/constants/network_constants.dart';
import 'package:vms_app/core/utils/app_logger.dart';

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
          AppLogger.d('API Request: ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.d('API Response: ${response.statusCode}');
          handler.next(response);
        },
        onError: (DioException error, handler) {
          AppLogger.e('API Error: ${error.message}');
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
                    shadowColor.withValues(alpha: 0.1),
                    shadowColor.withValues(alpha: 0.2),
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
                      color: shadowColor.withValues(alpha: 0.3),
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
                        colorFilter:
                            ColorFilter.mode(titleColor, BlendMode.srcIn),
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
                    shadowColor.withValues(alpha: 0.1),
                    shadowColor.withValues(alpha: 0.2),
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
                      color: shadowColor.withValues(alpha: 0.3),
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
                        colorFilter:
                            ColorFilter.mode(titleColor, BlendMode.srcIn),
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
