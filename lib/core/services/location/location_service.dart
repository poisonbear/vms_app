import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';

/// 위치 서비스 관리자
class LocationService {
  static LocationService? _instance;

  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  final _locationController = StreamController<Position>.broadcast();

  // 위치 업데이트 설정
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // 10미터마다 업데이트
  );

  LocationService._();

  factory LocationService() {
    _instance ??= LocationService._();
    return _instance!;
  }

  /// 현재 위치 가져오기
  Position? get currentPosition => _currentPosition;

  /// 위치 스트림
  Stream<Position> get positionStream => _locationController.stream;

  /// 권한 확인
  Future<bool> checkPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.w('Location services are disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.w('Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.e('Location permissions are permanently denied');
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.e('Error checking location permission: $e');
      return false;
    }
  }

  /// 위치 추적 시작
  Future<void> startLocationTracking() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        throw const LocationException('위치 권한이 거부되었습니다');
      }

      // 현재 위치 먼저 가져오기
      _currentPosition = await Geolocator.getCurrentPosition();
      _locationController.add(_currentPosition!);

      // 위치 스트림 구독
      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: _locationSettings,
      ).listen(
        (Position position) {
          _currentPosition = position;
          _locationController.add(position);
          AppLogger.d(
              'Location updated: ${position.latitude}, ${position.longitude}');
        },
        onError: (e) {
          AppLogger.e('Location stream error: $e');
        },
      );

      AppLogger.i('Location tracking started');
    } catch (e) {
      AppLogger.e('Failed to start location tracking: $e');
      throw const LocationException('위치 추적을 시작할 수 없습니다');
    }
  }

  /// 위치 추적 중지
  void stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    AppLogger.i('Location tracking stopped');
  }

  /// 단일 위치 가져오기
  Future<Position> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        throw const LocationException('위치 권한이 거부되었습니다');
      }

      final position = await Geolocator.getCurrentPosition();
      _currentPosition = position;
      return position;
    } catch (e) {
      AppLogger.e('Failed to get current location: $e');
      throw const LocationException('현재 위치를 가져올 수 없습니다');
    }
  }

  /// 두 지점 간 거리 계산 (미터)
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// 방위각 계산
  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// 리소스 정리
  void dispose() {
    stopLocationTracking();
    _locationController.close();
  }
}
