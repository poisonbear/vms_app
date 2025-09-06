#!/bin/bash

# main_screen.dart 단계별 분리 스크립트
# 작성일: 2025-01-06
# 목적: 안전하게 하나씩 기능을 분리

echo "======================================"
echo "📂 main_screen.dart 단계별 분리"
echo "======================================"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 프로젝트 루트 확인
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Flutter 프로젝트 루트에서 실행해주세요.${NC}"
    exit 1
fi

# 백업 생성
BACKUP_DIR="lib/presentation/screens/main/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp lib/presentation/screens/main/main_screen.dart "$BACKUP_DIR/"
echo -e "${GREEN}✅ 백업 완료: $BACKUP_DIR${NC}"

# 디렉토리 생성
mkdir -p lib/presentation/screens/main/utils
mkdir -p lib/presentation/screens/main/widgets
mkdir -p lib/presentation/screens/main/handlers

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 1: GeoJSON 유틸리티 분리${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# 1. GeoJSON 파싱 함수 분리
cat > lib/presentation/screens/main/utils/geo_utils.dart << 'EOF'
import 'dart:convert';
import 'package:latlong2/latlong.dart';

/// GeoJSON 파싱 유틸리티
class GeoUtils {
  /// GeoJSON LineString을 LatLng 리스트로 변환
  static List<LatLng> parseGeoJsonLineString(String geoJsonStr) {
    try {
      final decodedOnce = jsonDecode(geoJsonStr);
      final geoJson = decodedOnce is String ? jsonDecode(decodedOnce) : decodedOnce;
      final coords = geoJson['coordinates'] as List;
      return coords.map<LatLng>((c) {
        final lon = double.tryParse(c[0].toString());
        final lat = double.tryParse(c[1].toString());
        if (lat == null || lon == null) throw const FormatException();
        return LatLng(lat, lon);
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
EOF

echo -e "${GREEN}✅ geo_utils.dart 생성 완료${NC}"

# main_screen.dart에 import 추가 안내
echo -e "\n${YELLOW}📝 TODO: main_screen.dart 수정${NC}"
echo "1. 상단에 추가:"
echo "   import 'utils/geo_utils.dart';"
echo ""
echo "2. 함수 호출 변경:"
echo "   parseGeoJsonLineString → GeoUtils.parseGeoJsonLineString"

# Flutter analyze 실행
echo -e "\n${BLUE}Flutter analyze 실행 중...${NC}"
flutter analyze lib/presentation/screens/main/utils/geo_utils.dart

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 2: 위치 서비스 분리${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# 2. LocationService와 UpdatePoint 분리
cat > lib/presentation/screens/main/utils/location_utils.dart << 'EOF'
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:vms_app/core/utils/app_logger.dart';

/// 위치 서비스 유틸리티
class LocationService {
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
class UpdatePoint {
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
EOF

echo -e "${GREEN}✅ location_utils.dart 생성 완료${NC}"

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 3: 선박 정보 테이블 위젯 분리${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# 3. 선박 정보 테이블 위젯 분리
cat > lib/presentation/screens/main/widgets/vessel_info_table.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';

/// 선박 정보 테이블 위젯
class VesselInfoTable extends StatelessWidget {
  final String? shipName;
  final int? mmsi;
  final String? vesselType;
  final double? draft;
  final double? sog;
  final double? cog;

  const VesselInfoTable({
    super.key,
    this.shipName,
    this.mmsi,
    this.vesselType,
    this.draft,
    this.sog,
    this.cog,
  });

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(80),
        1: FlexColumnWidth(),
      },
      children: [
        _buildInfoRow('선박명', shipName ?? '-'),
        _buildInfoRow('MMSI', mmsi?.toString() ?? '-'),
        _buildInfoRow('선종', vesselType ?? '-'),
        _buildInfoRow('흘수', draft != null ? '${draft} m' : '-'),
        _buildInfoRow('대지속도', sog != null ? '${sog} kn' : '-'),
        _buildInfoRow('대지침로', cog != null ? '${cog}°' : '-'),
      ],
    );
  }

  TableRow _buildInfoRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: getSize10().toDouble()),
          child: Text(
            label,
            style: TextStyle(
              fontSize: DesignConstants.fontSizeS,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: getSize10().toDouble()),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: DesignConstants.fontSizeL,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
EOF

echo -e "${GREEN}✅ vessel_info_table.dart 생성 완료${NC}"

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 4: 경고 버튼 위젯 분리${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# 4. 경고 버튼 위젯 분리
cat > lib/presentation/screens/main/widgets/warning_button.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vms_app/core/constants/constants.dart';
import 'package:vms_app/core/network/dio_client.dart';
import 'package:vms_app/presentation/widgets/common/common_widgets.dart';

/// 경고 팝업 버튼 위젯
class WarningPopButton extends StatelessWidget {
  final String svgPath;
  final Color color;
  final int widthSize;
  final int heightSize;
  final String labelText;
  final int widthSizeLine;
  final String title;
  final Color titleColor;
  final String detail;
  final Color detailColor;
  final String alarmIcon;
  final Color shadowColor;

  const WarningPopButton({
    super.key,
    required this.svgPath,
    required this.color,
    required this.widthSize,
    required this.heightSize,
    required this.labelText,
    required this.widthSizeLine,
    required this.title,
    required this.titleColor,
    required this.detail,
    required this.detailColor,
    required this.alarmIcon,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: getSize12().toDouble()),
      child: GestureDetector(
        onTap: () {
          warningPop(
            context,
            title,
            titleColor,
            detail,
            detailColor,
            alarmIcon,
            shadowColor,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: widthSizeLine.toDouble(),
              height: heightSize.toDouble(),
            ),
            Positioned(
              left: getSize0().toDouble(),
              child: Container(
                width: widthSize.toDouble(),
                height: heightSize.toDouble(),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  svgPath,
                  width: getSize24().toDouble(),
                  height: getSize24().toDouble(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 상세 경고 팝업 버튼 위젯
class WarningPopDetailButton extends StatelessWidget {
  final String svgPath;
  final Color color;
  final int widthSize;
  final int heightSize;
  final String labelText;
  final int widthSizeLine;
  final String title;
  final Color titleColor;
  final String detail;
  final Color detailColor;
  final String alarmIcon;
  final Color shadowColor;

  const WarningPopDetailButton({
    super.key,
    required this.svgPath,
    required this.color,
    required this.widthSize,
    required this.heightSize,
    required this.labelText,
    required this.widthSizeLine,
    required this.title,
    required this.titleColor,
    required this.detail,
    required this.detailColor,
    required this.alarmIcon,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: getSize12().toDouble()),
      child: GestureDetector(
        onTap: () {
          warningPopdetail(
            context,
            title,
            titleColor,
            detail,
            detailColor,
            '',
            alarmIcon,
            shadowColor,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: widthSizeLine.toDouble(),
              height: heightSize.toDouble(),
            ),
            Positioned(
              left: getSize0().toDouble(),
              child: Container(
                width: widthSize.toDouble(),
                height: heightSize.toDouble(),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  svgPath,
                  width: getSize24().toDouble(),
                  height: getSize24().toDouble(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
EOF

echo -e "${GREEN}✅ warning_button.dart 생성 완료${NC}"

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${YELLOW}Step 5: 각 파일 검증${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# 각 파일 개별 검증
echo -e "\n${BLUE}생성된 파일 검증:${NC}"
for file in lib/presentation/screens/main/utils/*.dart lib/presentation/screens/main/widgets/*.dart; do
    if [ -f "$file" ]; then
        LINES=$(wc -l < "$file")
        FILENAME=$(basename "$file")
        echo -e "  • $FILENAME: ${GREEN}$LINES${NC}줄"
        
        # 각 파일 개별 analyze
        flutter analyze "$file" 2>/dev/null | grep -E "error|warning" | head -2
    fi
done

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ 단계별 분리 준비 완료!${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}📝 다음 단계 (수동 작업):${NC}"
echo ""
echo "1. main_screen.dart 상단에 import 추가:"
echo "   ${BLUE}import 'utils/geo_utils.dart';${NC}"
echo "   ${BLUE}import 'utils/location_utils.dart';${NC}"
echo "   ${BLUE}import 'widgets/vessel_info_table.dart';${NC}"
echo "   ${BLUE}import 'widgets/warning_button.dart';${NC}"
echo ""
echo "2. 함수 호출 변경:"
echo "   • parseGeoJsonLineString() → GeoUtils.parseGeoJsonLineString()"
echo "   • _infoRow() 제거 → VesselInfoTable 위젯 사용"
echo "   • _warningPopOn() 제거 → WarningPopButton 위젯 사용"
echo "   • _warningPopOnDetail() 제거 → WarningPopDetailButton 위젯 사용"
echo ""
echo "3. 각 단계마다 확인:"
echo "   ${BLUE}flutter analyze${NC}"
echo "   ${BLUE}flutter run${NC}"

echo -e "\n${GREEN}완료!${NC}"
