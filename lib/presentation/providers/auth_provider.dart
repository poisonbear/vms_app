import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vms_app/core/constants/constants.dart';

class UserState with ChangeNotifier {
  String _role = StringConstants.emptyString;
  int? _mmsi;

  String get role => _role;
  int? get mmsi => _mmsi;

  void setRole(String newRole) async {
    _role = newRole;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StringConstants.userRoleKey, newRole);
  }

  void setMmsi(int? newMmsi) async {
    _mmsi = newMmsi;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (newMmsi != null) {
      await prefs.setInt(StringConstants.userMmsiKey, newMmsi);
    } else {
      await prefs.remove(StringConstants.userMmsiKey); // null일 경우 기존 저장 값 제거
    }
  }

  Future<void> loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    _role = prefs.getString(StringConstants.userRoleKey) ?? StringConstants.emptyString;
    _mmsi = prefs.getInt(StringConstants.userMmsiKey);
    notifyListeners();
  }
}
