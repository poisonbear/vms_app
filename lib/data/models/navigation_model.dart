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

  factory NavigationModel.fromJson(Map<String, dynamic> json) {
    return NavigationModel(
      mmsi: json['mmsi'] != null ? int.tryParse(json['mmsi'].toString()) : null,
      reg_dt: json['reg_dt'] != null ? int.tryParse(json['reg_dt'].toString()) : null,
      odb_reg_date: json['odb_reg_date'] != null ? int.tryParse(json['odb_reg_date'].toString()) : null,
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

/// 🔧 수정: 파고와 시정 데이터 정보 - 원본 필드명 사용
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

  /// 🔧 수정: 원본 필드명을 사용한 robust한 JSON 파싱
  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    AppLogger.d('🔍 WeatherInfo parsing started...');

    double wave = 0.0;
    double visibility = 0.0;
    double walm1 = 0.0;
    double walm2 = 0.0;
    double walm3 = 0.0;
    double walm4 = 0.0;
    double valm1 = 0.0;
    double valm2 = 0.0;
    double valm3 = 0.0;
    double valm4 = 0.0;

    try {
      // 🔧 수정: data 필드 확인 및 처리
      if (json.containsKey('data')) {
        Map<String, dynamic> data = json['data'];
        AppLogger.d('✅ Found data field');

        // 🔧 수정: nowData에서 현재 파고/시정 데이터 추출 (원본 필드명 사용)
        if (data.containsKey('nowData')) {
          var nowData = data['nowData'];
          if (nowData != null && nowData is Map) {
            AppLogger.d('📊 Processing nowData: $nowData');

            // 🌊 파고 데이터 - 원본 필드명: wvhgt_surf
            if (nowData.containsKey('wvhgt_surf')) {
              try {
                wave = double.parse(nowData['wvhgt_surf'].toString());
                AppLogger.d('✅ Wave found (wvhgt_surf): ${wave}m');
              } catch (e) {
                AppLogger.e('❌ Error parsing wvhgt_surf: $e');
              }
            }

            // 👁️ 시정 데이터 - 원본 필드명: vdst
            if (nowData.containsKey('vdst')) {
              try {
                visibility = double.parse(nowData['vdst'].toString());
                AppLogger.d('✅ Visibility found (vdst): ${visibility}m');
              } catch (e) {
                AppLogger.e('❌ Error parsing vdst: $e');
              }
            }
          }
        } else {
          AppLogger.w('⚠️ No nowData field found');
        }

        // 🔧 수정: waveData에서 파고 알람 임계값 추출
        if (data.containsKey('waveData')) {
          var waveData = data['waveData'];
          if (waveData != null && waveData is Map) {
            AppLogger.d('🌊 Processing waveData: $waveData');

            try {
              if (waveData.containsKey('alm_a_val')) {
                walm1 = double.parse(waveData['alm_a_val'].toString());
                AppLogger.d('✅ Wave alarm 1: ${walm1}m');
              }
              if (waveData.containsKey('alm_b_val')) {
                walm2 = double.parse(waveData['alm_b_val'].toString());
                AppLogger.d('✅ Wave alarm 2: ${walm2}m');
              }
              if (waveData.containsKey('alm_c_val')) {
                walm3 = double.parse(waveData['alm_c_val'].toString());
                AppLogger.d('✅ Wave alarm 3: ${walm3}m');
              }
              if (waveData.containsKey('alm_d_val')) {
                walm4 = double.parse(waveData['alm_d_val'].toString());
                AppLogger.d('✅ Wave alarm 4: ${walm4}m');
              }
            } catch (e) {
              AppLogger.e('❌ Error parsing wave alarms: $e');
              // 기본값 설정
              walm1 = 1.0; walm2 = 2.0; walm3 = 3.0; walm4 = 4.0;
            }
          }
        } else {
          AppLogger.w('⚠️ No waveData field found, using defaults');
          walm1 = 1.0; walm2 = 2.0; walm3 = 3.0; walm4 = 4.0;
        }

        // 🔧 수정: visibilityData에서 시정 알람 임계값 추출
        if (data.containsKey('visibilityData')) {
          var visibilityData = data['visibilityData'];
          if (visibilityData != null && visibilityData is Map) {
            AppLogger.d('👁️ Processing visibilityData: $visibilityData');

            try {
              if (visibilityData.containsKey('alm_a_val')) {
                valm1 = double.parse(visibilityData['alm_a_val'].toString());
                AppLogger.d('✅ Visibility alarm 1: ${valm1}m');
              }
              if (visibilityData.containsKey('alm_b_val')) {
                valm2 = double.parse(visibilityData['alm_b_val'].toString());
                AppLogger.d('✅ Visibility alarm 2: ${valm2}m');
              }
              if (visibilityData.containsKey('alm_c_val')) {
                valm3 = double.parse(visibilityData['alm_c_val'].toString());
                AppLogger.d('✅ Visibility alarm 3: ${valm3}m');
              }
              if (visibilityData.containsKey('alm_d_val')) {
                valm4 = double.parse(visibilityData['alm_d_val'].toString());
                AppLogger.d('✅ Visibility alarm 4: ${valm4}m');
              }
            } catch (e) {
              AppLogger.e('❌ Error parsing visibility alarms: $e');
              // 기본값 설정
              valm1 = 5000.0; valm2 = 3000.0; valm3 = 1000.0; valm4 = 500.0;
            }
          }
        } else {
          AppLogger.w('⚠️ No visibilityData field found, using defaults');
          valm1 = 5000.0; valm2 = 3000.0; valm3 = 1000.0; valm4 = 500.0;
        }
      } else {
        AppLogger.e('❌ No data field found in response');
        // 🔧 수정: data 필드가 없을 때 직접 필드 확인
        AppLogger.d('🔍 Checking for direct fields...');

        // 직접 필드에서 파고/시정 찾기
        final directWaveFields = ['wvhgt_surf', 'wave', 'nowWave'];
        for (final field in directWaveFields) {
          if (json.containsKey(field)) {
            try {
              wave = double.parse(json[field].toString());
              AppLogger.d('✅ Wave found in direct field "$field": ${wave}m');
              break;
            } catch (e) {
              AppLogger.w('⚠️ Failed to parse direct field "$field": $e');
            }
          }
        }

        final directVisibilityFields = ['vdst', 'visibility', 'nowVisibility'];
        for (final field in directVisibilityFields) {
          if (json.containsKey(field)) {
            try {
              visibility = double.parse(json[field].toString());
              AppLogger.d('✅ Visibility found in direct field "$field": ${visibility}m');
              break;
            } catch (e) {
              AppLogger.w('⚠️ Failed to parse direct field "$field": $e');
            }
          }
        }

        // 기본 알람값 설정
        walm1 = 1.0; walm2 = 2.0; walm3 = 3.0; walm4 = 4.0;
        valm1 = 5000.0; valm2 = 3000.0; valm3 = 1000.0; valm4 = 500.0;
      }

      AppLogger.d('✅ WeatherInfo parsing completed');
      AppLogger.d('  📊 Final values:');
      AppLogger.d('    🌊 Wave: ${wave}m');
      AppLogger.d('    👁️ Visibility: ${visibility}m');
      AppLogger.d('    🌊 Wave alarms: [$walm1, $walm2, $walm3, $walm4]');
      AppLogger.d('    👁️ Visibility alarms: [$valm1, $valm2, $valm3, $valm4]');

    } catch (e) {
      AppLogger.e('❌ WeatherInfo parsing error: $e');
      AppLogger.w('⚠️ Using default values due to parsing error');

      // 🔧 수정: 전체 파싱 실패 시 안전한 기본값
      wave = 0.0;
      visibility = 0.0;
      walm1 = 1.0; walm2 = 2.0; walm3 = 3.0; walm4 = 4.0;
      valm1 = 5000.0; valm2 = 3000.0; valm3 = 1000.0; valm4 = 500.0;
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

/// 🔧 수정: 항행경보 알림 데이터 정보 (원본 파싱 방식)
class NavigationWarnings {
  final List<String> warnings;

  NavigationWarnings({required this.warnings});

  /// 🔧 수정: 원본 코드와 동일한 단순한 파싱 로직
  factory NavigationWarnings.fromJson(Map<String, dynamic> json) {
    AppLogger.d('🔍 NavigationWarnings parsing started...');

    List<dynamic> data = json['data'] ?? [];
    AppLogger.d('📦 Found data list with ${data.length} items');

    // 🔧 수정: 원본처럼 단순하게 toString()으로 변환
    List<String> warningList = data.map((item) => item.toString()).toList();

    AppLogger.d('✅ NavigationWarnings parsed: ${warningList.length} warnings');
    if (warningList.isNotEmpty) {
      AppLogger.d('📋 Sample warnings: ${warningList.take(2).join(', ')}');
    }

    return NavigationWarnings(warnings: warningList);
  }

  bool get hasWarnings => warnings.isNotEmpty;

  String get combinedWarnings => warnings.join(' | ');
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef RosModel = NavigationModel;