import 'package:equatable/equatable.dart';

/// 날씨 정보 모델
class WeatherModel extends Equatable {
  const WeatherModel({
    this.weatherCondition,
    this.currentTemp,
    this.past3hPrecipSurface,
    this.windUSurface,
    this.windVSurface,
    this.gustSurface,
    this.waveHeight,
    this.ptypeSurface,
    this.ts,
    this.regDt,
  });

  final String? weatherCondition;
  final double? currentTemp;
  final double? past3hPrecipSurface;
  final double? windUSurface;
  final double? windVSurface;
  final double? gustSurface;
  final double? waveHeight;
  final double? ptypeSurface;
  final DateTime? ts;
  final DateTime? regDt;

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      weatherCondition: json['weathercondition'],
      currentTemp: json['currenttemp']?.toDouble(),
      past3hPrecipSurface: json['past3hprecipsurface']?.toDouble(),
      windUSurface: json['windusurface']?.toDouble(),
      windVSurface: json['windvsurface']?.toDouble(),
      gustSurface: json['gustsurface']?.toDouble(),
      waveHeight: json['waveheight']?.toDouble(),
      ptypeSurface: json['ptypesurface']?.toDouble(),
      ts: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      regDt: json['regdt'] != null ? DateTime.parse(json['regdt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'weathercondition': weatherCondition,
    'currenttemp': currentTemp,
    'past3hprecipsurface': past3hPrecipSurface,
    'windusurface': windUSurface,
    'windvsurface': windVSurface,
    'gustsurface': gustSurface,
    'waveheight': waveHeight,
    'ptypesurface': ptypeSurface,
    'timestamp': ts?.toIso8601String(),
    'regdt': regDt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    weatherCondition,
    currentTemp,
    past3hPrecipSurface,
    windUSurface,
    windVSurface,
    gustSurface,
    waveHeight,
    ptypeSurface,
    ts,
    regDt,
  ];
}

/// 날씨 정보 (파고, 시정) 모델
class WeatherInfoModel extends Equatable {
  const WeatherInfoModel({
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

  final double wave;
  final double visibility;

  // 파고 알람 데이터 (4개)
  final double walm1;
  final double walm2;
  final double walm3;
  final double walm4;

  // 시정 알람 데이터 (4개)
  final double valm1;
  final double valm2;
  final double valm3;
  final double valm4;

  factory WeatherInfoModel.fromJson(Map<String, dynamic> json) {
    double wave = 0.0;
    double visibility = 0.0;
    double walm1 = 0.0, walm2 = 0.0, walm3 = 0.0, walm4 = 0.0;
    double valm1 = 0.0, valm2 = 0.0, valm3 = 0.0, valm4 = 0.0;

    if (json.containsKey('data')) {
      Map<String, dynamic> data = json['data'];

      // 현재 파고, 시정 데이터 추출
      if (data.containsKey('nowData')) {
        var nowData = data['nowData'];
        if (nowData != null && nowData is Map) {
          wave = double.tryParse(nowData['wvhgt_surf']?.toString() ?? '0') ?? 0.0;
          visibility = double.tryParse(nowData['vdst']?.toString() ?? '0') ?? 0.0;
        }
      }

      // 파고 알람 데이터 추출
      if (data.containsKey('waveData')) {
        var waveData = data['waveData'];
        if (waveData != null && waveData is Map) {
          walm1 = double.tryParse(waveData['alm_a_val']?.toString() ?? '0') ?? 0.0;
          walm2 = double.tryParse(waveData['alm_b_val']?.toString() ?? '0') ?? 0.0;
          walm3 = double.tryParse(waveData['alm_c_val']?.toString() ?? '0') ?? 0.0;
          walm4 = double.tryParse(waveData['alm_d_val']?.toString() ?? '0') ?? 0.0;
        }
      }

      // 시정 알람 데이터 추출
      if (data.containsKey('visibilityData')) {
        var visibilityData = data['visibilityData'];
        if (visibilityData != null && visibilityData is Map) {
          valm1 = double.tryParse(visibilityData['alm_a_val']?.toString() ?? '0') ?? 0.0;
          valm2 = double.tryParse(visibilityData['alm_b_val']?.toString() ?? '0') ?? 0.0;
          valm3 = double.tryParse(visibilityData['alm_c_val']?.toString() ?? '0') ?? 0.0;
          valm4 = double.tryParse(visibilityData['alm_d_val']?.toString() ?? '0') ?? 0.0;
        }
      }
    }

    return WeatherInfoModel(
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

  Map<String, dynamic> toJson() => {
    'wave': wave,
    'visibility': visibility,
    'walm1': walm1,
    'walm2': walm2,
    'walm3': walm3,
    'walm4': walm4,
    'valm1': valm1,
    'valm2': valm2,
    'valm3': valm3,
    'valm4': valm4,
  };

  @override
  List<Object?> get props => [
    wave,
    visibility,
    walm1,
    walm2,
    walm3,
    walm4,
    valm1,
    valm2,
    valm3,
    valm4,
  ];
}