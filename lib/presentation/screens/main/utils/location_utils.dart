import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

/// 위치 서비스 유틸리티
class MainLocationService {
  /// 현재 위치 가져오기
  Future<Position?> getCurrentPosition() async {
    try {
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.d('위치 권한이 거부되었습니다.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.d('위치 권한이 영구적으로 거부되었습니다.');
        return null;
      }

      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.d('위치 서비스가 비활성화되어 있습니다.');
        return null;
      }

      // 현재 위치 가져오기
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      AppLogger.e('위치 가져오기 실패: $e');
      return null;
    }
  }
}

/// 위치 업데이트 스트림 제공
class MainUpdatePoint {
  StreamSubscription<Position>? _positionStreamSubscription;

  /// 위치 스트림 토글
  Stream<Position> toggleListening() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  /// 스트림 구독 취소
  void dispose() {
    _positionStreamSubscription?.cancel();
  }
}
