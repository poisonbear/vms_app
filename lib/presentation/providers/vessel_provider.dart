// lib/presentation/providers/vessel_provider.dart
import 'package:vms_app/core/infrastructure/injection.dart';
import 'package:vms_app/core/exceptions/app_exceptions.dart';
import 'package:vms_app/core/utils/app_logger.dart';
import 'package:vms_app/data/models/vessel_model.dart';
import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/presentation/providers/base_provider.dart';

/// 선박 정보 Provider
class VesselProvider extends BaseProvider {
  late final VesselRepository _vesselRepository;

  List<VesselSearchModel> _vessels = [];

  // Getters
  List<VesselSearchModel> get vessels => _vessels;

  VesselProvider() {
    _vesselRepository = getIt<VesselRepository>();
  }

  /// 선박 목록 조회
  Future<void> getVesselList({String? regDt, int? mmsi}) async {
    await executeAsync<void>(
          () async {
        _vessels = await _vesselRepository.getVesselList(
          regDt: regDt,
          mmsi: mmsi,
        );
        safeNotifyListeners();
      },
      errorMessage: '선박 목록을 불러오는 중 오류가 발생했습니다',
      onError: (error) {
        if (error is AuthException) {
          setError('다시 로그인해주세요');
        }
      },
    );
  }

  /// 선박 목록 초기화
  void clearVessels() {
    executeSafe(() {
      _vessels = [];
      safeNotifyListeners();
    });
  }

  /// 특정 MMSI 선박 찾기
  VesselSearchModel? findVesselByMmsi(int mmsi) {
    try {
      return _vessels.firstWhere((vessel) => vessel.mmsi == mmsi);
    } catch (e) {
      AppLogger.w('MMSI $mmsi 선박을 찾을 수 없음');
      return null;
    }
  }

  /// 선박 개수
  int get vesselCount => _vessels.length;

  /// 선박 목록이 비어있는지 확인
  bool get isEmpty => _vessels.isEmpty;

  /// 선박 목록이 있는지 확인
  bool get isNotEmpty => _vessels.isNotEmpty;

  @override
  void dispose() {
    _vessels.clear();
    AppLogger.d('VesselProvider disposed');
    super.dispose();
  }
}