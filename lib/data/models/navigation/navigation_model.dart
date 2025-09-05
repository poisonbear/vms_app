import 'package:vms_app/core/utils/app_logger.dart';

// RosModel - 항행이력 데이터 모델
class RosModel {
  int? mmsi;
  int? reg_dt;
  int? odb_reg_date; // navigation_tab에서 사용하는 필드
  String? shipName;
  String? ship_kdn;
  String? psng_auth;
  String? psng_auth_cd;
  double? lntd; // 위도
  double? lttd; // 경도
  double? sog; // 속도
  String? cog; // 침로

  RosModel({
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

  factory RosModel.fromJson(Map<String, dynamic> json) {
    return RosModel(
      mmsi: json['mmsi'],
      reg_dt: json['reg_dt'],
      odb_reg_date: json['odb_reg_date'],
      shipName: json['ship_nm'],
      ship_kdn: json['ship_kdn'],
      psng_auth: json['psng_auth'],
      psng_auth_cd: json['psng_auth_cd'],
      lntd: json['rcv_loc_lntd'],
      lttd: json['rcv_loc_lttd'],
      sog: json['sog'],
      cog: json['cog'],
    );
  }
}

// 파고와 시정 데이터 정보
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
          // 현재 파고 값 추출
          if (nowData.containsKey('wvhgt_surf')) {
            try {
              wave = double.parse(nowData['wvhgt_surf'].toString());
            } catch (e) {
              // TODO: Handle error
              AppLogger.e("Error: $e");
            }
          }

          // 현재 시정 값 추출
          if (nowData.containsKey('vdst')) {
            try {
              visibility = double.parse(nowData['vdst'].toString());
            } catch (e) {
              // TODO: Handle error
              AppLogger.e("Error: $e");
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
              // TODO: Handle error
              AppLogger.e("Error: $e");
            }
          }
          if (waveData.containsKey('alm_b_val')) {
            try {
              walm2 = double.parse(waveData['alm_b_val'].toString());
            } catch (e) {
              // TODO: Handle error
              AppLogger.e("Error: $e");
            }
          }
          if (waveData.containsKey('alm_c_val')) {
            try {
              walm3 = double.parse(waveData['alm_c_val'].toString());
            } catch (e) {
              // TODO: Handle error
              AppLogger.e("Error: $e");
            }
          }
          if (waveData.containsKey('alm_d_val')) {
            try {
              walm4 = double.parse(waveData['alm_d_val'].toString());
            } catch (e) {
              // TODO: Handle error
              AppLogger.e("Error: $e");
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
              // TODO: Handle error
              AppLogger.e("Error: $e");
            }
          }
          if (visibilityData.containsKey('alm_b_val')) {
            try {
              valm2 = double.parse(visibilityData['alm_b_val'].toString());
            } catch (e) {
              // TODO: Handle error
              AppLogger.e("Error: $e");
            }
          }
          if (visibilityData.containsKey('alm_c_val')) {
            try {
              valm3 = double.parse(visibilityData['alm_c_val'].toString());
            } catch (e) {
              // TODO: Handle error
              AppLogger.e("Error: $e");
            }
          }
          if (visibilityData.containsKey('alm_d_val')) {
            try {
              valm4 = double.parse(visibilityData['alm_d_val'].toString());
            } catch (e) {
              // TODO: Handle error
              AppLogger.e("Error: $e");
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

// 항행경보 알림 데이터 정보 (이전에 추가한 구분자 포함 버전)
class NavigationWarnings {
  final List<String> warnings;

  NavigationWarnings({required this.warnings});

  factory NavigationWarnings.fromJson(Map<String, dynamic> json) {
    List<dynamic> data = json['data'] ?? [];

    // API 데이터를 정제하여 구분자 포함 문자열로 변환
    List<String> processedWarnings = [];
    for (var item in data) {
      String warningText = '';
      String category = '';
      String message = '';
      String dateTime = '';

      // item이 Map인 경우 구분자와 메시지 추출
      if (item is Map<String, dynamic>) {
        // 구분자/카테고리 추출
        if (item.containsKey('category')) {
          category = item['category'].toString();
        } else if (item.containsKey('type')) {
          category = _convertTypeToKorean(item['type'].toString());
        } else if (item.containsKey('warning_type')) {
          category = _convertTypeToKorean(item['warning_type'].toString());
        } else if (item.containsKey('warn_type')) {
          category = _convertTypeToKorean(item['warn_type'].toString());
        }

        // 메시지 추출
        if (item.containsKey('message')) {
          message = item['message'].toString();
        } else if (item.containsKey('content')) {
          message = item['content'].toString();
        } else if (item.containsKey('text')) {
          message = item['text'].toString();
        } else if (item.containsKey('description')) {
          message = item['description'].toString();
        } else if (item.containsKey('warning')) {
          message = item['warning'].toString();
        }

        // 날짜/시간 정보 추출
        if (item.containsKey('date_time')) {
          dateTime = ' ${item['date_time']}';
        } else if (item.containsKey('datetime')) {
          dateTime = ' ${item['datetime']}';
        } else if (item.containsKey('period')) {
          dateTime = ' ${item['period']}';
        } else if (item.containsKey('start_time') &&
            item.containsKey('end_time')) {
          dateTime = ' ${item['start_time']} ~ ${item['end_time']}';
        }

        // 위치 정보 추가 (있는 경우)
        String location = '';
        if (item.containsKey('location')) {
          location = item['location'].toString();
          if (location.isNotEmpty) {
            location = ' $location';
          }
        } else if (item.containsKey('area')) {
          location = item['area'].toString();
          if (location.isNotEmpty) {
            location = ' $location';
          }
        }

        // 카테고리가 없으면 기본값 설정
        if (category.isEmpty) {
          category = '항행경보';
        }

        // 메시지가 없으면 모든 텍스트 필드 결합
        if (message.isEmpty) {
          List<String> textValues = [];
          item.forEach((key, value) {
            if (![
              'id',
              'code',
              'type',
              'category',
              'warning_type',
              'warn_type',
              'status',
              'created_at',
              'updated_at',
              'date_time',
              'datetime',
              'period',
              'start_time',
              'end_time',
              'location',
              'area'
            ].contains(key.toLowerCase())) {
              if (value != null && value.toString().isNotEmpty) {
                textValues.add(value.toString());
              }
            }
          });
          message = textValues.join(' ');
        }

        // 최종 포맷: [구분자] 위치 메시지 시간
        warningText =
            '[$category]$location${location.isNotEmpty && message.isNotEmpty ? ' ' : ''}$message$dateTime';
      } else if (item is String) {
        // item이 이미 문자열인 경우
        warningText = '[항행경보] $item';
      } else {
        // 기타 타입
        warningText = '[항행경보] ${item.toString()}';
      }

      // 빈 문자열이 아닌 경우만 추가
      if (warningText.trim().isNotEmpty &&
          warningText != '[항행경보]' &&
          warningText != '[]') {
        processedWarnings.add(warningText.trim());
      }
    }

    return NavigationWarnings(warnings: processedWarnings);
  }

  // 영문 타입을 한글로 변환하는 헬퍼 메서드
  static String _convertTypeToKorean(String type) {
    final typeMap = {
      'shooting': '해상사격',
      'naval_shooting': '해상사격',
      'exercise': '군사훈련',
      'military_exercise': '군사훈련',
      'navigation': '항행주의',
      'navigation_warning': '항행주의',
      'weather': '기상특보',
      'weather_warning': '기상특보',
      'storm': '풍랑주의',
      'storm_warning': '풍랑주의',
      'accident': '해상사고',
      'marine_accident': '해상사고',
      'construction': '해상공사',
      'marine_construction': '해상공사',
      'restricted': '통항제한',
      'restricted_area': '통항제한',
      'submarine': '잠수함작전',
      'submarine_operation': '잠수함작전',
      'fishing': '어로작업',
      'fishing_operation': '어로작업',
      'cable': '케이블작업',
      'cable_work': '케이블작업',
      'salvage': '인양작업',
      'salvage_operation': '인양작업',
      'survey': '해양조사',
      'marine_survey': '해양조사',
      'drill': '시추작업',
      'drilling': '시추작업',
      'dredging': '준설작업',
      'dredge': '준설작업',
    };

    return typeMap[type.toLowerCase()] ?? type;
  }

  // 경고 메시지가 있는지 확인하는 헬퍼 메서드
  bool get hasWarnings => warnings.isNotEmpty;

  // 경고 메시지를 하나의 문자열로 연결 (Marquee용)
  String get combinedWarnings => warnings.join('   ●   ');
}
