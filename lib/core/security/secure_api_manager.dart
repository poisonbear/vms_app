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
