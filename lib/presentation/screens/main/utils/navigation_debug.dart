import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/presentation/providers/route_provider.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';
import '../controllers/main_screen_controller.dart';

class NavigationDebugHelper {
  static int _callCount = 0;

  static void debugPrint(String message, {String? location}) {
    _callCount++;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    AppLogger.d(
        ' [$_callCount][$timestamp]${location != null ? "[$location]" : ""} $message');
  }

  static void checkProviderAccess(BuildContext context, String location) {
    debugPrint('=== Provider 체크 ===', location: location);

    // RouteSearchProvider 체크
    try {
      final routeProvider = Provider.of<RouteProvider>(context, listen: false);
      debugPrint(
          'RouteSearchProvider OK - past: ${routeProvider.pastRoutes.length}, pred: ${routeProvider.predRoutes.length}',
          location: location);
    } catch (e) {
      debugPrint('RouteSearchProvider 실패: $e', location: location);
    }

    // MapControllerProvider 체크
    try {
      final mapProvider =
          Provider.of<MapControllerProvider>(context, listen: false);
      debugPrint('MapControllerProvider OK', location: location);
      debugPrint('MapControllerProvider instance: $mapProvider',
          location: location);
    } catch (e) {
      debugPrint('MapControllerProvider 실패: $e', location: location);
    }

    // MainScreenController 체크
    try {
      final mainController =
          Provider.of<MainScreenController>(context, listen: false);
      debugPrint('MainScreenController OK', location: location);
      debugPrint('MainScreenController instance: $mainController',
          location: location);
    } catch (e) {
      debugPrint('MainScreenController 실패: $e', location: location);
    }
  }
}
