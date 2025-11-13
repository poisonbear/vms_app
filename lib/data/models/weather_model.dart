/// 날씨 정보 모델
class WeatherModel {
  String? weather_condition;
  double? current_temp;
  double? past3hprecip_surface;
  double? wind_u_surface;
  double? wind_v_surface;
  double? gust_surface;
  double? wave_height;
  double? ptype_surface;
  DateTime? ts;
  DateTime? reg_dt;

  WeatherModel({
    this.weather_condition,
    this.current_temp,
    this.past3hprecip_surface,
    this.wind_u_surface,
    this.wind_v_surface,
    this.gust_surface,
    this.wave_height,
    this.ptype_surface,
    this.ts,
    this.reg_dt,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      weather_condition: json['weathercondition'],
      current_temp: json['currenttemp'],
      past3hprecip_surface: json['past3hprecipsurface'],
      wind_u_surface: json['windusurface'],
      wind_v_surface: json['windvsurface'],
      gust_surface: json['gustsurface'],
      wave_height: json['waveheight'],
      ptype_surface: json['ptypesurface'],
      ts: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      reg_dt: json['regdt'] != null ? DateTime.parse(json['regdt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weathercondition': weather_condition,
      'currenttemp': current_temp,
      'past3hprecipsurface': past3hprecip_surface,
      'windusurface': wind_u_surface,
      'windvsurface': wind_v_surface,
      'gustsurface': gust_surface,
      'waveheight': wave_height,
      'ptypesurface': ptype_surface,
      'timestamp': ts?.toIso8601String(),
      'regdt': reg_dt?.toIso8601String(),
    };
  }
}

// ===== 하위 호환성을 위한 Type Alias =====
typedef WidModel = WeatherModel;
