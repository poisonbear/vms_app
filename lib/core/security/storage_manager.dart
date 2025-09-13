import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'dart:convert';

/// 스토리지 관리자 (shared_preferences 기반)
/// flutter_secure_storage 대체용
class StorageManager {
  static StorageManager? _instance;
  late SharedPreferences _prefs;
  
  factory StorageManager() {
    _instance ??= StorageManager._internal();
    return _instance!;
  }
  
  StorageManager._internal();
  
  /// 초기화
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    AppLogger.d('StorageManager initialized');
  }
  
  /// 문자열 저장
  Future<bool> saveString(String key, String value) async {
    try {
      // 간단한 Base64 인코딩 (최소한의 보안)
      final encoded = base64.encode(utf8.encode(value));
      return await _prefs.setString(key, encoded);
    } catch (e) {
      AppLogger.e('Failed to save string: $e');
      return false;
    }
  }
  
  /// 문자열 읽기
  String? getString(String key) {
    try {
      final encoded = _prefs.getString(key);
      if (encoded == null) return null;
      
      // Base64 디코딩
      final decoded = utf8.decode(base64.decode(encoded));
      return decoded;
    } catch (e) {
      AppLogger.e('Failed to get string: $e');
      return null;
    }
  }
  
  /// JSON 저장
  Future<bool> saveJson(String key, Map<String, dynamic> json) async {
    try {
      final jsonString = jsonEncode(json);
      return await saveString(key, jsonString);
    } catch (e) {
      AppLogger.e('Failed to save JSON: $e');
      return false;
    }
  }
  
  /// JSON 읽기
  Map<String, dynamic>? getJson(String key) {
    try {
      final jsonString = getString(key);
      if (jsonString == null) return null;
      
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.e('Failed to get JSON: $e');
      return null;
    }
  }
  
  /// 키 삭제
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }
  
  /// 모든 데이터 삭제
  Future<bool> clear() async {
    return await _prefs.clear();
  }
  
  /// 키 존재 확인
  bool hasKey(String key) {
    return _prefs.containsKey(key);
  }
}
