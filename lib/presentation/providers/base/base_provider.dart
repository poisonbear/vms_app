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
