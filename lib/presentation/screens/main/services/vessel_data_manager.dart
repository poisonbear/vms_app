import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/presentation/providers/auth_provider.dart';
import 'package:vms_app/presentation/providers/vessel_provider.dart';

/// 선박 데이터 관리 서비스
class VesselDataManager {
  /// 선박 데이터 로드 및 맵 업데이트
  Future<void> loadVesselDataAndUpdateMap(BuildContext context) async {
    if (!context.mounted) return;
    
    try {
      final mmsi = context.read<UserState>().mmsi ?? 0;
      final role = context.read<UserState>().role;
      
      if (role == 'ROLE_USER') {
        await context.read<VesselProvider>().getVesselList(mmsi: mmsi);
      } else {
        await context.read<VesselProvider>().getVesselList(mmsi: 0);
      }
    } catch (e) {
      AppLogger.d('[loadVesselDataAndUpdateMap] error: $e');
    }
  }
}
