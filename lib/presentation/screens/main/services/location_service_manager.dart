import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/presentation/widgets/widgets.dart';
import '../utils/location_utils.dart';

/// 위치 관련 서비스 관리
class LocationServiceManager {
  final MainLocationService _locationService = MainLocationService();
  
  /// 현재 위치 가져오기
  Future<LatLng?> getCurrentLocation() async {
    Position? position = await _locationService.getCurrentPosition();
    if (position != null) {
      return LatLng(position.latitude, position.longitude);
    }
    return null;
  }
  
  /// 자동 위치 포커스
  Future<LatLng?> autoFocusToMyLocation(
    BuildContext context, {
    bool autoFocusLocation = false,
  }) async {
    try {
      AppLogger.d('🎯 자동 위치 포커스 시작...');
      
      final prefs = await SharedPreferences.getInstance();
      final isFirstAutoFocus = prefs.getBool('first_auto_focus') ?? true;
      
      if (!isFirstAutoFocus && !autoFocusLocation) {
        return null;
      }
      
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
        if (context.mounted) {
          showTopSnackBar(context, '설정에서 위치 권한을 허용해주세요.');
        }
        return null;
      }
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.d('❌ 위치 서비스가 비활성화됨');
        if (context.mounted) {
          showTopSnackBar(context, '위치 서비스를 활성화해주세요.');
        }
        return null;
      }
      
      AppLogger.d('📍 현재 위치 가져오는 중...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      AppLogger.d('✅ 위치 획득 - 위도: ${position.latitude}, 경도: ${position.longitude}');
      
      LatLng currentLocation = LatLng(position.latitude, position.longitude);
      
      await prefs.setBool('first_auto_focus', false);
      
      if (context.mounted) {
        showTopSnackBar(context, '현재 위치로 이동했습니다.');
      }
      
      return currentLocation;
    } catch (e) {
      AppLogger.e('❌ 자동 위치 포커스 오류: $e');
      return const LatLng(35.374509, 126.132268); // 기본 위치
    }
  }
  
  /// 위치 권한 체크 및 요청
  Future<bool> checkAndRequestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      AppLogger.d('✅ 이미 위치 권한이 허용되어 있습니다.');
      return true;
    }
    
    permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }
}
