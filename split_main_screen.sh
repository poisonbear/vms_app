#!/bin/bash

# main_screen.dart 분할 스크립트
# 작성일: 2025-01-06
# 목적: 2105줄의 main_screen.dart를 기능별로 분할

echo "======================================"
echo "📂 main_screen.dart 분할 작업 시작"
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
echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 1: 백업 생성${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

BACKUP_DIR="lib/presentation/screens/main/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp lib/presentation/screens/main/main_screen.dart "$BACKUP_DIR/"
echo -e "${GREEN}  ✅ 백업 완료: $BACKUP_DIR${NC}"

# 디렉토리 구조 생성
echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 2: 디렉토리 구조 생성${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

mkdir -p lib/presentation/screens/main/widgets
mkdir -p lib/presentation/screens/main/handlers
mkdir -p lib/presentation/screens/main/utils

echo -e "${GREEN}  ✅ 디렉토리 구조 생성 완료${NC}"

# ========================================
# 1. 지도 위젯 분리
# ========================================
echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 3: 지도 위젯 분리${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

cat > lib/presentation/screens/main/widgets/map_widget.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/presentation/providers/route_search_provider.dart';

class MainMapWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng? currentPosition;
  final List<Widget> overlayWidgets;
  
  const MainMapWidget({
    super.key,
    required this.mapController,
    this.currentPosition,
    this.overlayWidgets = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RouteSearchProvider>(
      builder: (context, routeSearchViewModel, child) {
        // 과거항적 처리
        var pastRouteLine = <LatLng>[];
        if (routeSearchViewModel.pastRoutes.isNotEmpty) {
          int cnt = 20;
          if (routeSearchViewModel.pastRoutes.length <= cnt) cnt = 1;
          
          // 첫 번째 포인트
          final firstPoint = routeSearchViewModel.pastRoutes.first;
          pastRouteLine.add(LatLng(firstPoint.lttd ?? 0, firstPoint.lntd ?? 0));
          
          // 중간 포인트들
          if (routeSearchViewModel.pastRoutes.length > 2) {
            for (int i = 1; i < routeSearchViewModel.pastRoutes.length - 1; i++) {
              if (i % cnt == 0) {
                final route = routeSearchViewModel.pastRoutes[i];
                pastRouteLine.add(LatLng(route.lttd ?? 0, route.lntd ?? 0));
              }
            }
          }
          
          // 마지막 포인트
          final lastPoint = routeSearchViewModel.pastRoutes.last;
          pastRouteLine.add(LatLng(lastPoint.lttd ?? 0, lastPoint.lntd ?? 0));
        }

        // 예측항로 처리
        var predRouteLine = <LatLng>[];
        predRouteLine.addAll((routeSearchViewModel.predRoutes ?? [])
            .map((route) => LatLng(route.lttd ?? 0, route.lntd ?? 0))
            .toList());

        if (predRouteLine.isNotEmpty && pastRouteLine.isNotEmpty) {
          pastRouteLine.add(predRouteLine.first);
        }

        return FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: currentPosition ?? const LatLng(35.374509, 126.132268),
            initialZoom: 12.0,
            maxZoom: 14.0,
            minZoom: 5.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            // 전자해도 레이어들
            TileLayer(
              wmsOptions: WMSTileLayerOptions(
                baseUrl: "${dotenv.env['GEOSERVER_URL']}?",
                layers: const ['vms_space:enc_map'],
                format: 'image/png',
                transparent: true,
                version: '1.1.1',
              ),
            ),
            // 추가 레이어들...
            ...overlayWidgets,
          ],
        );
      },
    );
  }
}
EOF

echo -e "${GREEN}  ✅ map_widget.dart 생성 완료${NC}"

# ========================================
# 2. 선박 마커 위젯 분리
# ========================================
echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 4: 선박 마커 위젯 분리${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

cat > lib/presentation/screens/main/widgets/vessel_markers.dart << 'EOF'
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';

class VesselMarkersLayer extends StatelessWidget {
  final List<VesselSearchModel> vessels;
  final int userMmsi;
  final bool isOtherVesselsVisible;
  final Function(VesselSearchModel) onVesselTap;

  const VesselMarkersLayer({
    super.key,
    required this.vessels,
    required this.userMmsi,
    required this.isOtherVesselsVisible,
    required this.onVesselTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 내 선박 마커
        MarkerLayer(
          markers: vessels
              .where((vessel) => (vessel.mmsi ?? 0) == userMmsi)
              .map((vessel) {
            return Marker(
              point: LatLng(vessel.lttd ?? 0, vessel.lntd ?? 0),
              width: 25,
              height: 25,
              child: Transform.rotate(
                angle: (vessel.cog ?? 0) * (pi / 180),
                child: SvgPicture.asset(
                  'assets/kdn/home/img/myVessel.svg',
                  width: 40,
                  height: 40,
                ),
              ),
            );
          }).toList(),
        ),
        // 다른 선박 마커
        Opacity(
          opacity: isOtherVesselsVisible ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !isOtherVesselsVisible,
            child: MarkerLayer(
              markers: vessels
                  .where((vessel) => (vessel.mmsi ?? 0) != userMmsi)
                  .map((vessel) {
                return Marker(
                  point: LatLng(vessel.lttd ?? 0, vessel.lntd ?? 0),
                  width: 25,
                  height: 25,
                  child: GestureDetector(
                    onTap: () => onVesselTap(vessel),
                    child: Transform.rotate(
                      angle: (vessel.cog ?? 0) * (pi / 180),
                      child: SvgPicture.asset(
                        'assets/kdn/home/img/otherVessel.svg',
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
EOF

echo -e "${GREEN}  ✅ vessel_markers.dart 생성 완료${NC}"

# ========================================
# 3. 팝업 다이얼로그 분리
# ========================================
echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 5: 팝업 다이얼로그 분리${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

cat > lib/presentation/screens/main/widgets/popup_dialogs.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vms_app/core/constants/constants.dart';

class MainScreenPopups {
  /// 터빈 진입 경고 팝업
  static void showTurbineWarningPopup(
    BuildContext context,
    String title,
    String message,
    VoidCallback onClose,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 310,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/kdn/home/img/red_triangle-exclamation.svg',
                  width: 60,
                  height: 60,
                ),
                const SizedBox(height: DesignConstants.spacing8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: DesignConstants.fontSizeXL,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDF2B2E),
                    height: 1.0,
                    letterSpacing: 0,
                    fontFamily: 'Pretendard Variable',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignConstants.spacing8),
                SizedBox(
                  width: 300,
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: DesignConstants.fontSizeXS,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                      height: 1.0,
                      letterSpacing: 0,
                      fontFamily: 'Pretendard Variable',
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 270,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      onClose();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: DesignConstants.spacing10,
                        horizontal: DesignConstants.spacing10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignConstants.radiusS),
                        side: const BorderSide(color: Color(0xFF5CA1F6), width: 1),
                      ),
                      elevation: 0,
                      minimumSize: const Size(270, 48),
                    ),
                    child: const Text(
                      '알람 종료하기',
                      style: TextStyle(
                        color: Color(0xFF5CA1F6),
                        fontSize: DesignConstants.fontSizeS,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 기상 경고 팝업
  static void showWeatherWarningPopup(
    BuildContext context,
    String title,
    String message,
    VoidCallback onClose,
  ) {
    // 터빈 경고와 유사한 구조
    showTurbineWarningPopup(context, title, message, onClose);
  }

  /// 해저케이블 경고 팝업
  static void showSubmarineWarningPopup(
    BuildContext context,
    String title,
    String message,
    VoidCallback onClose,
  ) {
    // 터빈 경고와 유사한 구조
    showTurbineWarningPopup(context, title, message, onClose);
  }
}
EOF

echo -e "${GREEN}  ✅ popup_dialogs.dart 생성 완료${NC}"

# ========================================
# 4. FCM 핸들러 분리
# ========================================
echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 6: FCM 핸들러 분리${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

cat > lib/presentation/screens/main/handlers/fcm_handler.dart << 'EOF'
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vms_app/core/utils/app_logger.dart';

class FCMHandler {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final Function(String type, String? title, String? body) onMessageReceived;
  
  FCMHandler({
    required this.flutterLocalNotificationsPlugin,
    required this.onMessageReceived,
  });

  void initialize() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final data = message.data;
      final type = data['type'];
      
      _showForegroundNotification(message);
      
      if (type != null) {
        onMessageReceived(
          type,
          message.notification?.title,
          message.notification?.body,
        );
      }
    });
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.d('앱이 백그라운드에서 열림: ${message.messageId}');
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    AndroidNotificationDetails androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: '중요 알림을 위한 채널입니다.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      styleInformation: BigTextStyleInformation(''),
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      message.notification?.title ?? '알림',
      message.notification?.body ?? '알림 내용이 없습니다.',
      platformChannelSpecifics,
    );
  }

  Future<void> requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLogger.d('✅ 알림 권한 허용됨');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      AppLogger.d('❌ 알림 권한 거부됨');
    } else {
      AppLogger.d('⚠️ 알림 권한 상태: ${settings.authorizationStatus}');
    }
  }
}
EOF

echo -e "${GREEN}  ✅ fcm_handler.dart 생성 완료${NC}"

# ========================================
# 5. 권한 핸들러 분리
# ========================================
echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 7: 권한 핸들러 분리${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

cat > lib/presentation/screens/main/handlers/permission_handler.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/core/utils/permission_manager.dart';
import 'package:vms_app/core/constants/constants.dart';

class MainPermissionHandler {
  static Future<void> requestPermissionsSequentially(BuildContext context) async {
    // 위치 권한 확인
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.whileInUse || 
        locationPermission == LocationPermission.always) {
      AppLogger.d('✅ 이미 위치 권한이 허용되어 있습니다.');
    } else {
      await Future.delayed(AnimationConstants.durationNormal);
      await PointRequestUtil.requestPermissionUntilGranted(context);
    }

    // 알림 권한 확인
    NotificationSettings notifSettings = 
        await FirebaseMessaging.instance.getNotificationSettings();
    if (notifSettings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLogger.d('✅ 이미 알림 권한이 허용되어 있습니다.');
    } else {
      await Future.delayed(AnimationConstants.durationNormal);
      await NotificationRequestUtil.requestPermissionUntilGranted(context);
    }
  }
}
EOF

echo -e "${GREEN}  ✅ permission_handler.dart 생성 완료${NC}"

# ========================================
# 6. 라인 수 비교
# ========================================
echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 Step 8: 결과 확인${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

echo -e "\n${GREEN}생성된 파일들:${NC}"
echo -e "  • widgets/map_widget.dart"
echo -e "  • widgets/vessel_markers.dart"
echo -e "  • widgets/popup_dialogs.dart"
echo -e "  • handlers/fcm_handler.dart"
echo -e "  • handlers/permission_handler.dart"

# 원본 파일 라인 수
ORIGINAL_LINES=$(wc -l < lib/presentation/screens/main/main_screen.dart)
echo -e "\n${YELLOW}원본 파일:${NC}"
echo -e "  main_screen.dart: ${RED}$ORIGINAL_LINES${NC}줄"

# 새 파일들 라인 수
echo -e "\n${YELLOW}분할된 파일들:${NC}"
for file in lib/presentation/screens/main/widgets/*.dart lib/presentation/screens/main/handlers/*.dart; do
    if [ -f "$file" ]; then
        LINES=$(wc -l < "$file")
        FILENAME=$(basename "$file")
        echo -e "  $FILENAME: ${GREEN}$LINES${NC}줄"
    fi
done

echo -e "\n${CYAN}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ main_screen.dart 분할 준비 완료!${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

echo -e "\n${YELLOW}💡 다음 단계:${NC}"
echo "1. 생성된 파일들을 main_screen.dart에서 import"
echo "2. main_screen.dart의 중복 코드 제거"
echo "3. 각 위젯을 새 파일의 클래스로 교체"
echo "4. flutter analyze로 검증"

echo -e "\n${GREEN}분할 작업 완료!${NC}"
