// weather_model.dart의 extension
import 'package:vms_app/data/models/weather/weather_model.dart';

extension WidModelExtension on WidModel {
  /// JSON 변환을 위한 toJson 메서드
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
  
  /// 날씨 상태 텍스트
  String get weatherText {
    if (weather_condition == null) return '정보 없음';
    // 날씨 코드에 따른 텍스트 변환 (필요시 수정)
    switch (weather_condition) {
      case 'sunny':
        return '맑음';
      case 'cloudy':
        return '흐림';
      case 'rainy':
        return '비';
      default:
        return weather_condition!;
    }
  }
  
  /// 온도 텍스트 (섭씨)
  String get temperatureText {
    if (current_temp == null) return '-';
    return '${current_temp!.toStringAsFixed(1)}°C';
  }
  
  /// 파고 텍스트
  String get waveHeightText {
    if (wave_height == null) return '-';
    return '${wave_height!.toStringAsFixed(1)}m';
  }
  
  /// 위험 레벨 (간단한 예시)
  String get dangerLevel {
    if (wave_height == null) return '정보 없음';
    if (wave_height! > 3.0) return '위험';
    if (wave_height! > 2.0) return '주의';
    return '안전';
  }
}
