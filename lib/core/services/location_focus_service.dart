import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';

/// 위치 포커스 관리 서비스
class LocationFocusService {
  static const String _firstAutoFocusKey = 'first_auto_focus';
  static const LatLng defaultLocation = LatLng(35.374509, 126.132268);
  
  /// 자동 위치 포커스
  static Future<LatLng?> autoFocusToMyLocation({
    required BuildContext context,
    required bool forceAutoFocus,
  }) async {
    try {
      AppLogger.d('🎯 자동 위치 포커스 시작...');
      
      // SharedPreferences 확인
      final prefs = await SharedPreferences.getInstance();
      final isFirstAutoFocus = prefs.getBool(_firstAutoFocusKey) ?? true;
      
      // 첫 로그인이 아니고 강제 포커스도 아니면 스킵
      if (!isFirstAutoFocus && !forceAutoFocus) {
        AppLogger.d('자동 포커스 스킵 (첫 로그인 아님)');
        return null;
      }
      
      // 위치 권한 확인
      final permission = await _checkAndRequestPermission();
      if (permission == null) {
        if (context.mounted) {
          showTopSnackBar(context, '위치 권한을 허용해주세요.');
        }
        return null;
      }
      
      // 위치 서비스 확인
      if (!await _checkLocationService(context)) {
        return defaultLocation;
      }
      
      // 현재 위치 가져오기
      final position = await _getCurrentPosition();
      if (position == null) {
        AppLogger.e('위치를 가져올 수 없음');
        if (context.mounted) {
          showTopSnackBar(context, '현재 위치를 가져올 수 없습니다.');
        }
        return defaultLocation;
      }
      
      final currentLocation = LatLng(position.latitude, position.longitude);
      
      // 첫 자동 포커스 완료 표시
      await prefs.setBool(_firstAutoFocusKey, false);
      
      if (context.mounted) {
        showTopSnackBar(context, '현재 위치로 이동했습니다.');
      }
      
      AppLogger.d('✅ 위치 포커스 성공: $currentLocation');
      return currentLocation;
      
    } catch (e) {
      AppLogger.e('❌ 자동 위치 포커스 오류: $e');
      return defaultLocation;
    }
  }
  
  /// 위치 권한 확인 및 요청
  static Future<LocationPermission?> _checkAndRequestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.d('❌ 위치 권한 거부됨');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        AppLogger.d('❌ 위치 권한이 영구 거부됨');
        return null;
      }
      
      return permission;
    } catch (e) {
      AppLogger.e('권한 확인 실패: $e');
      return null;
    }
  }
  
  /// 위치 서비스 활성화 확인
  static Future<bool> _checkLocationService(BuildContext context) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.d('❌ 위치 서비스가 비활성화됨');
        if (context.mounted) {
          showTopSnackBar(context, '위치 서비스를 활성화해주세요.');
        }
        return false;
      }
      return true;
    } catch (e) {
      AppLogger.e('위치 서비스 확인 실패: $e');
      return false;
    }
  }
  
  /// 현재 위치 가져오기
  static Future<Position?> _getCurrentPosition() async {
    try {
      AppLogger.d('📍 현재 위치 가져오는 중...');
      
      // 타임아웃 설정으로 안전하게 처리
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      AppLogger.d('✅ 위치 획득 - 위도: ${position.latitude}, 경도: ${position.longitude}');
      return position;
      
    } catch (e) {
      AppLogger.e('위치 획득 실패: $e');
      
      // 타임아웃 시 마지막 알려진 위치 시도
      try {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          AppLogger.d('마지막 알려진 위치 사용');
          return lastPosition;
        }
      } catch (_) {
        // 마지막 위치도 실패
      }
      
      return null;
    }
  }
}
