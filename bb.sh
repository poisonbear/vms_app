#!/bin/bash

echo "=== 보안 강화 오류 수정 시작 ==="

# 1. app_logger.dart 파일이 실제로 생성되었는지 확인
echo "[1/6] app_logger.dart 파일 확인 및 생성..."
if [ ! -f "lib/core/utils/app_logger.dart" ]; then
    echo "app_logger.dart 파일이 없습니다. 생성 중..."
    mkdir -p lib/core/utils
    cat > lib/core/utils/app_logger.dart << 'EOF'
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// 앱 전체 로그 관리 클래스
class AppLogger {
  static const String _appName = 'VMS_APP';
  
  static const int _verbose = 0;
  static const int _debug = 1;
  static const int _info = 2;
  static const int _warning = 3;
  static const int _error = 4;
  
  static int get _currentLevel => kReleaseMode ? _error : _debug;
  
  static void v(String message, [dynamic error]) {
    if (_currentLevel <= _verbose) {
      _log('VERBOSE', message, error);
    }
  }
  
  static void d(String message, [dynamic error]) {
    if (_currentLevel <= _debug) {
      _log('DEBUG', message, error);
    }
  }
  
  static void i(String message, [dynamic error]) {
    if (_currentLevel <= _info) {
      _log('INFO', message, error);
    }
  }
  
  static void w(String message, [dynamic error]) {
    if (_currentLevel <= _warning) {
      _log('WARNING', message, error);
    }
  }
  
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_currentLevel <= _error) {
      _log('ERROR', message, error);
      if (stackTrace != null && !kReleaseMode) {
        developer.log(
          stackTrace.toString(),
          name: '$_appName:STACK',
        );
      }
    }
  }
  
  static void _log(String level, String message, [dynamic error]) {
    if (kReleaseMode && level != 'ERROR') {
      return;
    }
    
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$level] $message';
    
    developer.log(
      logMessage,
      time: DateTime.now(),
      name: _appName,
      error: error,
    );
  }
  
  static void api(String method, String url, [dynamic data]) {
    if (!kReleaseMode) {
      d('API [$method] $url${data != null ? ' - Data: $data' : ''}');
    }
  }
  
  static String maskSensitive(String value, {int visibleChars = 4}) {
    if (value.length <= visibleChars) {
      return '*' * value.length;
    }
    final visible = value.substring(0, visibleChars);
    final masked = '*' * (value.length - visibleChars);
    return '$visible$masked';
  }
}
EOF
fi

# 2. secure_api_manager.dart 파일 생성
echo "[2/6] secure_api_manager.dart 파일 생성..."
mkdir -p lib/core/security
cat > lib/core/security/secure_api_manager.dart << 'EOF'
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SecureApiManager {
  static const _storage = FlutterSecureStorage();
  
  static final _key = Key.fromBase64(_generateKey());
  static final _iv = IV.fromLength(16);
  static final _encrypter = Encrypter(AES(_key));
  
  static final SecureApiManager _instance = SecureApiManager._internal();
  factory SecureApiManager() => _instance;
  SecureApiManager._internal();
  
  static String _generateKey() {
    const seed = 'VMS_APP_KDN_2025_SECURE_KEY_SEED';
    var bytes = utf8.encode(seed);
    var digest = sha256.convert(bytes);
    return base64.encode(digest.bytes).substring(0, 44);
  }
  
  Future<void> initializeSecureEndpoints() async {
    final endpoints = {
      'login_api': 'http://118.40.116.129:8080/mob/usm/loginForm.do',
      'role_api': 'http://118.40.116.129:8080/mob/usm/selectRoleData.do',
      'terms_api': 'http://118.40.116.129:8080/mob/usm/selectMobileCmdList.do',
      'vessel_list_api': 'http://118.40.116.129:8080/api/gis/vesselList',
      'vessel_route_api': 'http://118.40.116.129:8080/api/ros/vesselRoute',
      'weather_api': 'http://118.40.116.129:8080/api/wid/Weather',
      'navigation_api': 'http://118.40.116.129:8080/api/ros/navigation',
      'member_info_api': 'http://118.40.116.129:8080/mob/usm/selectMemberInfoData.do',
      'update_member_api': 'http://118.40.116.129:8080/mob/usm/updateMobileMembership.do',
      'register_api': 'http://118.40.116.129:8080/mob/usm/insertMobileMembership.do',
    };
    
    for (var entry in endpoints.entries) {
      final encrypted = _encrypt(entry.value);
      await _storage.write(key: entry.key, value: encrypted);
    }
    
    await _storage.write(
      key: 'firebase_project_id', 
      value: _encrypt('vms-app-8ff6d')
    );
  }
  
  String _encrypt(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }
  
  String _decrypt(String encryptedText) {
    final encrypted = Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }
  
  Future<String> getSecureEndpoint(String key) async {
    try {
      final encryptedValue = await _storage.read(key: key);
      if (encryptedValue == null) return '';
      return _decrypt(encryptedValue);
    } catch (e) {
      print('Error getting secure endpoint: $e');
      return '';
    }
  }
  
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
  
  Future<bool> hasKey(String key) async {
    final value = await _storage.read(key: key);
    return value != null;
  }
}
EOF

# 3. app_initializer.dart 파일 생성
echo "[3/6] app_initializer.dart 파일 생성..."
cat > lib/core/security/app_initializer.dart << 'EOF'
import 'package:vms_app/core/security/secure_api_manager.dart';
import 'package:vms_app/core/utils/app_logger.dart';

class AppInitializer {
  static Future<void> initializeSecurity() async {
    try {
      AppLogger.i('Initializing security...');
      
      final secureManager = SecureApiManager();
      
      if (!(await secureManager.hasKey('login_api'))) {
        await secureManager.initializeSecureEndpoints();
        AppLogger.d('Secure endpoints initialized');
      }
      
      AppLogger.i('Security initialization complete');
    } catch (e) {
      AppLogger.e('Security initialization failed', e);
    }
  }
}
EOF

# 4. 잘못된 print -> AppLogger 변환 되돌리기
echo "[4/6] 잘못 변환된 로그 수정..."
# print('...')를 print('...')로 복원 (잘못 변환된 것)
find lib -name "*.dart" -type f -exec sed -i "s/AppLogger\.d('/print('/g" {} \;

# 실제 디버그 로그만 AppLogger로 변경
find lib -name "*.dart" -type f -exec sed -i "s/developer\.log(/AppLogger.d(/g" {} \;

# 5. 필요한 import 추가
echo "[5/6] import 문 추가..."

# main.dart에 import 추가 (이미 있으면 중복 방지)
if ! grep -q "import 'package:vms_app/core/utils/app_logger.dart';" lib/main.dart; then
    sed -i "1i import 'package:vms_app/core/utils/app_logger.dart';" lib/main.dart
fi

if ! grep -q "import 'package:vms_app/core/security/app_initializer.dart';" lib/main.dart; then
    sed -i "1i import 'package:vms_app/core/security/app_initializer.dart';" lib/main.dart
fi

# 6. 불필요한 템플릿 파일 제거
echo "[6/6] 템플릿 파일 제거..."
rm -f lib/data/datasources/remote/secure_datasource_template.dart
rm -f lib/presentation/screens/auth/login_screen_secure.dart

echo ""
echo "=== ✅ 오류 수정 완료 ==="
echo ""
echo "남은 작업:"
echo "1. flutter pub get 실행"
echo "2. flutter clean"
echo "3. flutter run 테스트"
