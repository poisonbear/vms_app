import 'package:vms_app/core/utils/app_logger.dart';

// ===== 공통 헬퍼 함수 =====
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// 항행 이력 데이터 모델 (기존 RosModel)
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
  double? cog;  // String에서 double로 변경

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

  factory NavigationModel.fromJson(Map<String, dynamic> json) {
    return NavigationModel(
      mmsi: json['mmsi'] != null ? int.tryParse(json['mmsi'].toString()) : null,
      reg_dt: json['reg_dt'] != null ? int.tryParse(json['reg_dt'].toString()) : null,
      odb_reg_date: json['odb_reg_date'] != null ? int.tryParse(json['odb_reg_date'].toString()) : null,
      shipName: json['ship_nm']?.toString(),
      ship_kdn: json['ship_kdn']?.toString(),
      psng_auth: json['psng_auth']?.toString(),
      psng_auth_cd: json['psng_auth_cd']?.toString(),
      lntd: _parseDouble(json['rcv_loc_lntd']),  // NavigationModel은 rcv_loc_lntd 사용
      lttd: _parseDouble(json['rcv_loc_lttd']),  // NavigationModel은 rcv_loc_lttd 사용
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
    required this.walm1,
    required this.walm2,
    required this.walm3,
    required this.walm4,
    required this.valm1,
    required this.valm2,
    required this.valm3,
    required this.valm4,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    double wave = 0;
    double visibility = 0;
    double walm1 = 0.0;
    double walm2 = 0.0;
    double walm3 = 0.0;
    double walm4 = 0.0;
    double valm1 = 0.0;
    double valm2 = 0.0;
    double valm3 = 0.0;
    double valm4 = 0.0;

    if (json.containsKey('data')) {
      var data = json['data'];

      // 현재 파고, 시정 데이터 추출
      if (data.containsKey('nowData')) {
        var nowData = data['nowData'];
        if (nowData != null && nowData is Map) {
          if (nowData.containsKey('nowWave')) {
            try {
              wave = double.parse(nowData['nowWave'].toString());
            } catch (e) {
              AppLogger.e("Error parsing nowWave: $e");
            }
          }
          if (nowData.containsKey('nowVisibility')) {
            try {
              visibility = double.parse(nowData['nowVisibility'].toString());
            } catch (e) {
              AppLogger.e("Error parsing nowVisibility: $e");
            }
          }
        }
      }

      // 파고 알람 데이터 추출
      if (data.containsKey('waveData')) {
        var waveData = data['waveData'];
        if (waveData != null && waveData is Map) {
          if (waveData.containsKey('alm_a_val')) {
            try {
              walm1 = double.parse(waveData['alm_a_val'].toString());
            } catch (e) {
              AppLogger.e("Error parsing walm1: $e");
            }
          }
          if (waveData.containsKey('alm_b_val')) {
            try {
              walm2 = double.parse(waveData['alm_b_val'].toString());
            } catch (e) {
              AppLogger.e("Error parsing walm2: $e");
            }
          }
          if (waveData.containsKey('alm_c_val')) {
            try {
              walm3 = double.parse(waveData['alm_c_val'].toString());
            } catch (e) {
              AppLogger.e("Error parsing walm3: $e");
            }
          }
          if (waveData.containsKey('alm_d_val')) {
            try {
              walm4 = double.parse(waveData['alm_d_val'].toString());
            } catch (e) {
              AppLogger.e("Error parsing walm4: $e");
            }
          }
        }
      }

      // 시정 알람 데이터 추출
      if (data.containsKey('visibilityData')) {
        var visibilityData = data['visibilityData'];
        if (visibilityData != null && visibilityData is Map) {
          if (visibilityData.containsKey('alm_a_val')) {
            try {
              valm1 = double.parse(visibilityData['alm_a_val'].toString());
            } catch (e) {
              AppLogger.e("Error parsing valm1: $e");
            }
          }
          if (visibilityData.containsKey('alm_b_val')) {
            try {
              valm2 = double.parse(visibilityData['alm_b_val'].toString());
            } catch (e) {
              AppLogger.e("Error parsing valm2: $e");
            }
          }
          if (visibilityData.containsKey('alm_c_val')) {
            try {
              valm3 = double.parse(visibilityData['alm_c_val'].toString());
            } catch (e) {
              AppLogger.e("Error parsing valm3: $e");
            }
          }
          if (visibilityData.containsKey('alm_d_val')) {
            try {
              valm4 = double.parse(visibilityData['alm_d_val'].toString());
            } catch (e) {
              AppLogger.e("Error parsing valm4: $e");
            }
          }
        }
      }
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

    List<String> warningList = [];
    for (var item in data) {
      if (item is Map<String, dynamic>) {
        String warning = '';

        // 항행경보 정보 추출
        if (item.containsKey('hang_warn_nm')) {
          warning = item['hang_warn_nm']?.toString() ?? '';
        } else if (item.containsKey('warning_message')) {
          warning = item['warning_message']?.toString() ?? '';
        } else if (item.containsKey('message')) {
          warning = item['message']?.toString() ?? '';
        } else {
          // 전체 Map을 문자열로 변환
          warning = item.toString();
        }

        if (warning.isNotEmpty) {
          warningList.add(warning);
        }
      } else if (item is String) {
        warningList.add(item);
      }
    }

    return NavigationWarnings(warnings: warningList);
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef RosModel = NavigationModel;