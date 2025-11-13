import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import 'package:vms_app/presentation/providers/route_provider.dart';
import '../controllers/main_screen_controller.dart';

class NavigationDebugHelper {
  static void checkProviders(BuildContext context, String location) {
    AppLogger.d('=== Provider 체크 at $location ===');

    // RouteSearchProvider 체크
    try {
      final routeProvider = Provider.of<RouteProvider>(context, listen: false);
      AppLogger.d('RouteSearchProvider 접근 가능');
      AppLogger.d(' - pastRoutes: ${routeProvider.pastRoutes.length}');
      AppLogger.d(' - predRoutes: ${routeProvider.predRoutes.length}');
      AppLogger.d(
          ' - isNavigationHistoryMode: ${routeProvider.isNavigationHistoryMode}');
    } catch (e) {
      AppLogger.e('RouteSearchProvider 접근 불가: $e');
    }

    // MapControllerProvider 체크
    try {
      final mapProvider =
          Provider.of<MapControllerProvider>(context, listen: false);
      AppLogger.d('MapControllerProvider 접근 가능');
      AppLogger.d(' - mapController: ${mapProvider.mapController}');
    } catch (e) {
      AppLogger.e('MapControllerProvider 접근 불가: $e');
    }

    // MainScreenController 체크
    try {
      final mainController =
          Provider.of<MainScreenController>(context, listen: false);
      AppLogger.d('MainScreenController 접근 가능');
      AppLogger.d(' - isTrackingEnabled: ${mainController.isTrackingEnabled}');
      AppLogger.d(' - currentPosition: ${mainController.currentPosition}');
    } catch (e) {
      AppLogger.e('MainScreenController 접근 불가: $e');
    }

    AppLogger.d('=====================================');
  }
}
