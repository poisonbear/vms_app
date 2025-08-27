#!/bin/bash
# apply_duplicate_removal.sh

echo "🔧 중복 코드 정리 시작..."

# 1. 디렉토리 생성
mkdir -p lib/presentation/providers/base
mkdir -p lib/presentation/widgets/common
mkdir -p lib/core/constants

# 2. BaseProvider 생성
echo "Creating BaseProvider..."
cat > lib/presentation/providers/base/base_provider.dart << 'EOF'
import 'package:flutter/material.dart';

/// 모든 Provider의 기본 클래스
abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';

  // 공통 Getter
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  /// 로딩 상태 설정
  @protected
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 에러 메시지 설정
  @protected
  void setError(String message) {
    if (_errorMessage != message) {
      _errorMessage = message;
      notifyListeners();
    }
  }

  /// 에러 클리어
  @protected
  void clearError() {
    if (_errorMessage.isNotEmpty) {
      _errorMessage = '';
      notifyListeners();
    }
  }

  /// 비동기 작업 실행 래퍼
  @protected
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) {
        _isLoading = true;
        _errorMessage = '';
        notifyListeners();
      }

      final result = await operation();

      if (showLoading) {
        _isLoading = false;
        notifyListeners();
      }

      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = errorMessage ?? e.toString();
      notifyListeners();
      return null;
    }
  }

  /// 동기 작업 실행 래퍼
  @protected
  T? executeSafe<T>(
    T Function() operation, {
    String? errorMessage,
  }) {
    try {
      clearError();
      return operation();
    } catch (e) {
      _errorMessage = errorMessage ?? e.toString();
      notifyListeners();
      return null;
    }
  }
}
EOF

# 3. 공통 위젯 생성
echo "Creating common widgets..."
cat > lib/presentation/widgets/common/loading_container.dart << 'EOF'
import 'package:flutter/material.dart';

/// 로딩 상태를 표시하는 공통 컨테이너
class LoadingContainer extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Widget? loadingWidget;
  
  const LoadingContainer({
    Key? key,
    required this.isLoading,
    required this.child,
    this.loadingWidget,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ?? 
        const Center(
          child: CircularProgressIndicator(),
        );
    }
    return child;
  }
}
EOF

cat > lib/presentation/widgets/common/error_message_widget.dart << 'EOF'
import 'package:flutter/material.dart';

/// 에러 메시지를 표시하는 공통 위젯
class ErrorMessageWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  
  const ErrorMessageWidget({
    Key? key,
    required this.message,
    this.onRetry,
  }) : super(key: key);
  
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

# 4. 상수 파일 생성
echo "Creating constants..."
cat > lib/core/constants/app_constants.dart << 'EOF'
class AppConstants {
  // API 설정
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetryCount = 3;
  
  // 지도 설정
  static const double mapDefaultZoom = 13.0;
  static const double mapMinZoom = 5.0;
  static const double mapMaxZoom = 18.0;
  
  // 페이지네이션
  static const int defaultPageSize = 20;
  
  // 캐시
  static const Duration cacheExpiration = Duration(hours: 1);
}
EOF

cat > lib/core/constants/app_strings.dart << 'EOF'
class AppStrings {
  // 에러 메시지
  static const String networkError = '네트워크 연결을 확인해주세요';
  static const String serverError = '서버 오류가 발생했습니다';
  static const String unknownError = '알 수 없는 오류가 발생했습니다';
  static const String emptySearchQuery = '검색어를 입력해주세요';
  
  // 성공 메시지
  static const String saveSuccess = '저장되었습니다';
  static const String deleteSuccess = '삭제되었습니다';
  
  // 버튼 텍스트
  static const String retry = '다시 시도';
  static const String confirm = '확인';
  static const String cancel = '취소';
}
EOF

# 5. 분석
flutter analyze

echo "✅ 중복 코드 정리 완료!"
