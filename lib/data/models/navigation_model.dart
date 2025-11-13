import 'package:latlong2/latlong.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 항행 이력 데이터 모델
class NavigationModel {
  int? mmsi;
  int? reg_dt;
  int? odb_reg_date;
  String? shipName;
  String? ship_kdn;
  String? psng_auth;
  String? psng_auth_cd;
  double? lntd;
  double? lttd;
  double? sog;
  double? cog;

  NavigationModel({
    this.mmsi,
    this.reg_dt,
    this.odb_reg_date,
    this.shipName,
    this.ship_kdn,
    this.psng_auth,
    this.psng_auth_cd,
    this.lntd,
    this.lttd,
    this.sog,
    this.cog,
  });

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  factory NavigationModel.fromJson(Map<String, dynamic> json) {
    return NavigationModel(
      mmsi: json['mmsi'] != null ? int.tryParse(json['mmsi'].toString()) : null,
      reg_dt: json['reg_dt'] != null
          ? int.tryParse(json['reg_dt'].toString())
          : null,
      odb_reg_date: json['odb_reg_date'] != null
          ? int.tryParse(json['odb_reg_date'].toString())
          : null,
      shipName: json['ship_nm']?.toString(),
      ship_kdn: json['ship_kdn']?.toString(),
      psng_auth: json['psng_auth']?.toString(),
      psng_auth_cd: json['psng_auth_cd']?.toString(),
      lntd: _parseDouble(json['rcv_loc_lntd']),
      lttd: _parseDouble(json['rcv_loc_lttd']),
      sog: _parseDouble(json['sog']),
      cog: _parseDouble(json['cog']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mmsi': mmsi,
      'reg_dt': reg_dt,
      'odb_reg_date': odb_reg_date,
      'ship_nm': shipName,
      'ship_kdn': ship_kdn,
      'psng_auth': psng_auth,
      'psng_auth_cd': psng_auth_cd,
      'rcv_loc_lntd': lntd,
      'rcv_loc_lttd': lttd,
      'sog': sog,
      'cog': cog,
    };
  }
}

/// 파고와 시정 데이터 정보
class WeatherInfo {
  final double wave;
  final double visibility;
  final double walm1;
  final double walm2;
  final double walm3;
  final double walm4;
  final double valm1;
  final double valm2;
  final double valm3;
  final double valm4;

  WeatherInfo({
    required this.wave,
    required this.visibility,
    this.walm1 = 0.0,
    this.walm2 = 0.0,
    this.walm3 = 0.0,
    this.walm4 = 0.0,
    this.valm1 = 0.0,
    this.valm2 = 0.0,
    this.valm3 = 0.0,
    this.valm4 = 0.0,
  });

  static double _safeParseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    AppLogger.d('WeatherInfo parsing started...');
    AppLogger.d('Raw JSON: $json');

    double wave = 0.0;
    double visibility = 0.0;
    double walm1 = 1.0;
    double walm2 = 2.0;
    double walm3 = 3.0;
    double walm4 = 4.0;
    double valm1 = 5000.0;
    double valm2 = 3000.0;
    double valm3 = 1000.0;
    double valm4 = 500.0;

    try {
      // data 필드가 있는지 확인
      if (json.containsKey('data')) {
        final data = json['data'];
        AppLogger.d('Found data field, type: ${data.runtimeType}');

        if (data is Map) {
          final dataMap = data as Map<String, dynamic>;
          AppLogger.d('Data keys: ${dataMap.keys.toList()}');

          // nowData에서 현재 파고/시정 추출
          if (dataMap.containsKey('nowData')) {
            var nowData = dataMap['nowData'];
            AppLogger.d('nowData found: $nowData');

            if (nowData is Map) {
              // 파고 데이터
              if (nowData.containsKey('wvhgt_surf')) {
                wave = _safeParseDouble(nowData['wvhgt_surf'], 0.0);
                AppLogger.d('Wave (wvhgt_surf): ${wave}m');
              }

              // 시정 데이터
              if (nowData.containsKey('vdst')) {
                visibility = _safeParseDouble(nowData['vdst'], 0.0);
                AppLogger.d('Visibility (vdst): ${visibility}m');
              }
            }
          }

          // waveData에서 파고 알람 임계값 추출
          if (dataMap.containsKey('waveData')) {
            var waveData = dataMap['waveData'];
            AppLogger.d(' waveData found: $waveData');

            if (waveData is Map) {
              walm1 = _safeParseDouble(waveData['alm_a_val'], 1.0);
              walm2 = _safeParseDouble(waveData['alm_b_val'], 2.0);
              walm3 = _safeParseDouble(waveData['alm_c_val'], 3.0);
              walm4 = _safeParseDouble(waveData['alm_d_val'], 4.0);
              AppLogger.d('Wave alarms: [$walm1, $walm2, $walm3, $walm4]');
            }
          }

          // visibilityData에서 시정 알람 임계값 추출
          if (dataMap.containsKey('visibilityData')) {
            var visibilityData = dataMap['visibilityData'];
            AppLogger.d('visibilityData found: $visibilityData');

            if (visibilityData is Map) {
              valm1 = _safeParseDouble(visibilityData['alm_a_val'], 5000.0);
              valm2 = _safeParseDouble(visibilityData['alm_b_val'], 3000.0);
              valm3 = _safeParseDouble(visibilityData['alm_c_val'], 1000.0);
              valm4 = _safeParseDouble(visibilityData['alm_d_val'], 500.0);
              AppLogger.d(
                  'Visibility alarms: [$valm1, $valm2, $valm3, $valm4]');
            }
          }
        }
      } else {
        AppLogger.w('No data field found in JSON');
      }

      AppLogger.d('Final parsed values:');
      AppLogger.d('   Wave: ${wave}m');
      AppLogger.d('  Visibility: ${visibility}m');
    } catch (e, stackTrace) {
      AppLogger.e('WeatherInfo parsing error: $e');
      AppLogger.e('Stack trace: $stackTrace');
    }

    return WeatherInfo(
      wave: wave,
      visibility: visibility,
      walm1: walm1,
      walm2: walm2,
      walm3: walm3,
      walm4: walm4,
      valm1: valm1,
      valm2: valm2,
      valm3: valm3,
      valm4: valm4,
    );
  }
}

/// 항행경보 알림 데이터 정보
class NavigationWarnings {
  final List<String> warnings;

  NavigationWarnings({required this.warnings});

  factory NavigationWarnings.fromJson(Map<String, dynamic> json) {
    List<dynamic> data = json['data'] ?? [];
    List<String> warningList = data.map((item) => item.toString()).toList();
    return NavigationWarnings(warnings: warningList);
  }

  bool get hasWarnings => warnings.isNotEmpty;
  String get combinedWarnings => warnings.join(' | ');
}

/// 항행경보 상세 데이터 모델 (지도 표시용)
class NavigationWarningModel {
  final String areaNm; // 구역명
  final String ntiYmd; // 경보 날짜
  final String locInfo; // 위치 정보
  final String locInfoExpl; // 위치 설명
  final String ntiHh; // 경보 시간
  final String alarmCl; // 경보 분류 (접근금지/항행정보)
  final String aprchCl; // 접근 분류 (해상사격/장애물 등)
  final String message; // 메시지

  NavigationWarningModel({
    required this.areaNm,
    required this.ntiYmd,
    required this.locInfo,
    required this.locInfoExpl,
    required this.ntiHh,
    required this.alarmCl,
    required this.aprchCl,
    required this.message,
  });

  factory NavigationWarningModel.fromJson(Map<String, dynamic> json) {
    return NavigationWarningModel(
      areaNm: json['area_nm'] ?? '',
      ntiYmd: json['nti_ymd'] ?? '',
      locInfo: json['loc_info'] ?? '',
      locInfoExpl: json['loc_info_expl'] ?? '',
      ntiHh: json['nti_hh'] ?? '',
      alarmCl: json['alarm_cl'] ?? '',
      aprchCl: json['aprch_cl'] ?? '',
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'area_nm': areaNm,
      'nti_ymd': ntiYmd,
      'loc_info': locInfo,
      'loc_info_expl': locInfoExpl,
      'nti_hh': ntiHh,
      'alarm_cl': alarmCl,
      'aprch_cl': aprchCl,
      'message': message,
    };
  }

  /// 구역 형태 타입 판별
  String get shapeType {
    final coords = _parseCoordinates();
    if (coords.length == 1) {
      return MapConstants.warningShapeCircle;
    } else if (coords.length >= 3) {
      return MapConstants.warningShapePolygon;
    }
    return MapConstants.warningShapeCircle;
  }

  /// 원형 구역의 반경 (NM) 추출
  double get radiusNM {
    final match = RegExp(r'반경\s*(\d+(?:\.\d+)?)\s*NM').firstMatch(locInfoExpl);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }
    return 0.0;
  }

  /// 좌표 파싱 (DMS -> 십진법 변환)
  List<LatLng> _parseCoordinates() {
    final coords = <LatLng>[];

    // "36-40-39.3N,126-10-03.7E 36-41-11.3N,126-11-59.7E" 형태의 연속된 좌표 파싱
    final coordPattern =
        RegExp(r'(\d+)-(\d+)-([\d.]+)([NS]),(\d+)-(\d+)-([\d.]+)([EW])');

    final matches = coordPattern.allMatches(locInfo);

    for (final match in matches) {
      try {
        final latDeg = int.parse(match.group(1)!);
        final latMin = int.parse(match.group(2)!);
        final latSec = double.parse(match.group(3)!);
        final latDir = match.group(4)!;

        final lonDeg = int.parse(match.group(5)!);
        final lonMin = int.parse(match.group(6)!);
        final lonSec = double.parse(match.group(7)!);
        final lonDir = match.group(8)!;

        double lat = latDeg + latMin / 60.0 + latSec / 3600.0;
        double lon = lonDeg + lonMin / 60.0 + lonSec / 3600.0;

        if (latDir == 'S') lat = -lat;
        if (lonDir == 'W') lon = -lon;

        coords.add(LatLng(lat, lon));
      } catch (e) {
        AppLogger.e('좌표 파싱 오류: $e, match: ${match.group(0)}');
        continue;
      }
    }

    AppLogger.d('파싱된 좌표 개수: ${coords.length}');
    if (coords.isNotEmpty) {
      AppLogger.d('첫 좌표: ${coords.first.latitude}, ${coords.first.longitude}');
    }

    return coords;
  }

  /// 다각형 좌표 반환
  List<LatLng> get polygonPoints {
    if (shapeType == MapConstants.warningShapePolygon) {
      return _parseCoordinates();
    }
    return [];
  }

  /// 원형 중심 좌표 반환
  LatLng? get circleCenter {
    if (shapeType == MapConstants.warningShapeCircle) {
      final coords = _parseCoordinates();
      if (coords.isNotEmpty) {
        return coords.first;
      }
    }
    return null;
  }

  /// 경보 색상 (경보 분류에 따라)
  int get warningColor {
    if (alarmCl.contains(MapConstants.alarmTypeProhibited)) {
      return MapConstants.warningColorRed;
    } else if (alarmCl.contains(MapConstants.alarmTypeInfo)) {
      return MapConstants.warningColorOrange;
    }
    return MapConstants.warningColorYellow;
  }

  /// 라벨 중심 좌표
  LatLng? get labelCenter {
    if (shapeType == MapConstants.warningShapeCircle) {
      return circleCenter;
    } else if (shapeType == MapConstants.warningShapePolygon) {
      final points = polygonPoints;
      if (points.isEmpty) return null;

      // 다각형의 중심점 계산
      double sumLat = 0;
      double sumLon = 0;
      for (final point in points) {
        sumLat += point.latitude;
        sumLon += point.longitude;
      }
      return LatLng(sumLat / points.length, sumLon / points.length);
    }
    return null;
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef RosModel = NavigationModel;
