import 'package:flutter/material.dart';
import 'package:vms_app/core/errors/app_exceptions.dart';
import 'package:vms_app/core/utils/error_handler.dart';
import 'package:vms_app/data/repositories/navigation_repository_with_result.dart';
import 'package:vms_app/data/models/navigation/navigation_model.dart';

/// Result 패턴을 사용하는 Provider 예시
class NavigationProviderWithResult extends ChangeNotifier {
  final NavigationRepositoryWithResult _repository =
      NavigationRepositoryWithResult();

  List<RosModel> _rosList = [];
  bool _isLoading = false;
  AppException? _error;

  List<RosModel> get rosList => _rosList;
  bool get isLoading => _isLoading;
  String? get errorMessage =>
      _error != null ? ErrorHandler.getUserMessage(_error!) : null;
  bool get hasError => _error != null;

  Future<void> loadNavigationHistory({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getRosList(
      startDate: startDate,
      endDate: endDate,
      mmsi: mmsi,
      shipName: shipName,
    );

    result.fold(
      onSuccess: (data) {
        _rosList = data;
        _error = null;
      },
      onFailure: (error) {
        _rosList = [];
        _error = error;
      },
    );

    _isLoading = false;
    notifyListeners();
  }
}
