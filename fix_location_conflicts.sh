#!/bin/bash

echo "LocationService 충돌 해결 중..."

# 1. location_utils.dart 클래스명 변경
sed -i 's/class LocationService/class MainLocationService/g' \
    lib/presentation/screens/main/utils/location_utils.dart
    
sed -i 's/class UpdatePoint/class MainUpdatePoint/g' \
    lib/presentation/screens/main/utils/location_utils.dart

# 2. main_screen.dart에서 사용 부분 수정
sed -i 's/LocationService _locationService = LocationService()/MainLocationService _locationService = MainLocationService()/g' \
    lib/presentation/screens/main/main_screen.dart
    
sed -i 's/UpdatePoint _updatePoint = UpdatePoint()/MainUpdatePoint _updatePoint = MainUpdatePoint()/g' \
    lib/presentation/screens/main/main_screen.dart

# 3. parseGeoJsonLineString 모든 호출 수정
sed -i 's/parseGeoJsonLineString(/GeoUtils.parseGeoJsonLineString(/g' \
    lib/presentation/screens/main/main_screen.dart

echo "수정 완료!"
flutter analyze
