import 'package:vms_app/domain/repositories/emergency_repository.dart';
import 'package:vms_app/data/models/emergency_model.dart';

/// 긴급 상황 데이터 저장 파라미터
class SaveEmergencyParams {
  final EmergencyData data;

  SaveEmergencyParams({required this.data});
}

/// 위치 추적 저장 파라미터
class SaveLocationTrackingParams {
  final List<LocationTrackingData> locations;

  SaveLocationTrackingParams({required this.locations});
}

/// 긴급 상황 관련 UseCase 모음
class EmergencyUseCases {
  final EmergencyRepository _repository;

  EmergencyUseCases(this._repository);

  /// 긴급 상황 데이터 저장
  Future<bool> saveEmergencyData(SaveEmergencyParams params) async {
    return await _repository.saveEmergencyData(params.data);
  }

  /// 긴급 히스토리 로드
  Future<List<EmergencyData>> loadEmergencyHistory() async {
    return await _repository.loadEmergencyHistory();
  }

  /// 마지막 긴급 상황 로드
  Future<EmergencyData?> loadLastEmergency() async {
    return await _repository.loadLastEmergency();
  }

  /// 긴급 히스토리 삭제
  Future<bool> clearHistory() async {
    return await _repository.clearHistory();
  }

  /// 위치 추적 데이터 저장
  Future<bool> saveLocationTracking(SaveLocationTrackingParams params) async {
    return await _repository.saveLocationTracking(params.locations);
  }

  /// 위치 추적 데이터 로드
  Future<List<LocationTrackingData>> loadLocationTracking() async {
    return await _repository.loadLocationTracking();
  }

  /// 활성 긴급 상황 확인
  Future<bool> hasActiveEmergency() async {
    final lastEmergency = await _repository.loadLastEmergency();
    if (lastEmergency == null) return false;

    return lastEmergency.emergency_status == 'active' ||
        lastEmergency.emergency_status == 'inProgress';
  }
}

// ===== 개별 UseCase 클래스들 =====

/// 긴급 상황 데이터 저장 UseCase
class SaveEmergencyData {
  final EmergencyRepository repository;

  SaveEmergencyData(this.repository);

  Future<bool> execute(SaveEmergencyParams params) async {
    return await repository.saveEmergencyData(params.data);
  }
}

/// 긴급 히스토리 로드 UseCase
class LoadEmergencyHistory {
  final EmergencyRepository repository;

  LoadEmergencyHistory(this.repository);

  Future<List<EmergencyData>> execute() async {
    return await repository.loadEmergencyHistory();
  }
}

/// 마지막 긴급 상황 로드 UseCase
class LoadLastEmergency {
  final EmergencyRepository repository;

  LoadLastEmergency(this.repository);

  Future<EmergencyData?> execute() async {
    return await repository.loadLastEmergency();
  }
}

/// 긴급 히스토리 삭제 UseCase
class ClearEmergencyHistory {
  final EmergencyRepository repository;

  ClearEmergencyHistory(this.repository);

  Future<bool> execute() async {
    return await repository.clearHistory();
  }
}

/// 위치 추적 데이터 저장 UseCase
class SaveLocationTracking {
  final EmergencyRepository repository;

  SaveLocationTracking(this.repository);

  Future<bool> execute(SaveLocationTrackingParams params) async {
    return await repository.saveLocationTracking(params.locations);
  }
}

/// 위치 추적 데이터 로드 UseCase
class LoadLocationTracking {
  final EmergencyRepository repository;

  LoadLocationTracking(this.repository);

  Future<List<LocationTrackingData>> execute() async {
    return await repository.loadLocationTracking();
  }
}

/// 활성 긴급 상황 확인 UseCase
class CheckActiveEmergency {
  final EmergencyRepository repository;

  CheckActiveEmergency(this.repository);

  Future<bool> execute() async {
    final lastEmergency = await repository.loadLastEmergency();
    if (lastEmergency == null) return false;

    return lastEmergency.emergency_status == 'active' ||
        lastEmergency.emergency_status == 'inProgress';
  }
}
