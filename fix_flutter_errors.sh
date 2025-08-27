#!/bin/bash

echo "🔧 Flutter 프로젝트 에러 수정 시작..."

# 에러 1: vessel_provider.dart - SearchVesselParams 타입 에러 수정
echo "📝 [1/5] vessel_provider.dart 수정 중..."
cat > lib/presentation/providers/vessel_provider_fix.dart << 'EOF'
import 'package:flutter/cupertino.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';
import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/domain/usecases/vessel/search_vessel.dart';

class VesselProvider with ChangeNotifier {
  late final VesselRepository _vesselRepository;
  late final SearchVessel _searchVessel;

  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<VesselSearchModel> _vessels = [];
  List<VesselSearchModel> get vessels => _vessels;

  VesselProvider() {
    // ✅ DI 컨테이너에서 주입
    _vesselRepository = getIt<VesselRepository>();
    _searchVessel = getIt<SearchVessel>();
  }

  Future<void> getVesselList({String? regDt, int? mmsi}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Repository 직접 호출 (UseCase 패턴 제거 - 현재는 단순 구조 유지)
      _vessels = await _vesselRepository.getVesselList(regDt: regDt, mmsi: mmsi);
      
      // 또는 UseCase 패턴을 사용하려면:
      // final params = SearchVesselParams(regDt: regDt, mmsi: mmsi);
      // _vessels = await _searchVessel.execute(params);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
EOF

# 에러 2: main_screen.dart - FCM 토큰 타입 에러 수정
echo "📝 [2/5] FCM 토큰 타입 에러 수정 중..."
sed -i '346s/fcmToken = token!;/if (token != null) { fcmToken = token; }/' lib/presentation/screens/main/main_screen.dart 2>/dev/null || \
sed -i '' '346s/fcmToken = token!;/if (token != null) { fcmToken = token; }/' lib/presentation/screens/main/main_screen.dart

# 에러 3: main_screen.dart - 이중 null 체크 에러 수정
echo "📝 [3/5] 이중 null 체크 에러 수정 중..."
sed -i '386s/if (vessel?.mmsi != null != null) {/if (vessel?.mmsi != null) {/' lib/presentation/screens/main/main_screen.dart 2>/dev/null || \
sed -i '' '386s/if (vessel?.mmsi != null != null) {/if (vessel?.mmsi != null) {/' lib/presentation/screens/main/main_screen.dart

# 에러 4: main_screen.dart - where 절 타입 에러 수정 (1472번 라인)
echo "📝 [4/5] where 절 타입 에러 수정 중 (1472번 라인)..."
sed -i '1472s/.where((vessel) => vessel?.mmsi ?? 0 == mmsi)/.where((vessel) => (vessel.mmsi ?? 0) == mmsi)/' lib/presentation/screens/main/main_screen.dart 2>/dev/null || \
sed -i '' '1472s/.where((vessel) => vessel?.mmsi ?? 0 == mmsi)/.where((vessel) => (vessel.mmsi ?? 0) == mmsi)/' lib/presentation/screens/main/main_screen.dart

# 에러 5: main_screen.dart - where 절 타입 에러 수정 (1499번 라인)
echo "📝 [5/5] where 절 타입 에러 수정 중 (1499번 라인)..."
sed -i '1499s/.where((vessel) => vessel?.mmsi ?? 0 != mmsi)/.where((vessel) => (vessel.mmsi ?? 0) != mmsi)/' lib/presentation/screens/main/main_screen.dart 2>/dev/null || \
sed -i '' '1499s/.where((vessel) => vessel?.mmsi ?? 0 != mmsi)/.where((vessel) => (vessel.mmsi ?? 0) != mmsi)/' lib/presentation/screens/main/main_screen.dart

# vessel_provider.dart 파일 교체
echo "📝 vessel_provider.dart 파일 교체 중..."
mv lib/presentation/providers/vessel_provider.dart lib/presentation/providers/vessel_provider.backup
mv lib/presentation/providers/vessel_provider_fix.dart lib/presentation/providers/vessel_provider.dart

echo "✅ 모든 에러 수정 완료!"
echo ""
echo "📊 수정 내역:"
echo "  1. vessel_provider.dart - SearchVesselParams 타입 문제 해결"
echo "  2. main_screen.dart:346 - FCM 토큰 null safety 처리"
echo "  3. main_screen.dart:386 - 이중 null 체크 수정"
echo "  4. main_screen.dart:1472 - where 절 타입 캐스팅 수정"
echo "  5. main_screen.dart:1499 - where 절 타입 캐스팅 수정"
echo ""
echo "🔍 검증 실행..."
flutter analyze | grep -e 'error' || echo "✨ 모든 에러가 해결되었습니다!"#!/bin/bash

echo "🔧 Flutter 프로젝트 에러 수정 시작..."

# 에러 1: vessel_provider.dart - SearchVesselParams 타입 에러 수정
echo "📝 [1/5] vessel_provider.dart 수정 중..."
cat > lib/presentation/providers/vessel_provider_fix.dart << 'EOF'
import 'package:flutter/cupertino.dart';
import 'package:vms_app/core/di/injection.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';
import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/domain/usecases/vessel/search_vessel.dart';

class VesselProvider with ChangeNotifier {
  late final VesselRepository _vesselRepository;
  late final SearchVessel _searchVessel;

  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<VesselSearchModel> _vessels = [];
  List<VesselSearchModel> get vessels => _vessels;

  VesselProvider() {
    // ✅ DI 컨테이너에서 주입
    _vesselRepository = getIt<VesselRepository>();
    _searchVessel = getIt<SearchVessel>();
  }

  Future<void> getVesselList({String? regDt, int? mmsi}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Repository 직접 호출 (UseCase 패턴 제거 - 현재는 단순 구조 유지)
      _vessels = await _vesselRepository.getVesselList(regDt: regDt, mmsi: mmsi);
      
      // 또는 UseCase 패턴을 사용하려면:
      // final params = SearchVesselParams(regDt: regDt, mmsi: mmsi);
      // _vessels = await _searchVessel.execute(params);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
