#!/bin/bash

# VMS App - 의존성 주입 수정 스크립트
# 실행 방법: Git Bash에서 프로젝트 루트 디렉토리에서 실행
# chmod +x fix_injection.sh && ./fix_injection.sh

echo "========================================="
echo "VMS App - 의존성 주입 수정 시작"
echo "========================================="

# 1. 기존 injection.dart 백업
if [ -f "lib/core/di/injection.dart" ]; then
    cp lib/core/di/injection.dart lib/core/di/injection.dart.backup
    echo "✅ 기존 파일 백업 완료: injection.dart.backup"
fi

# 2. 완성된 injection.dart 생성
cat > lib/core/di/injection.dart << 'EOF'
import 'package:get_it/get_it.dart';
// DataSources
import 'package:vms_app/data/datasources/remote/terms_remote_datasource.dart';
import 'package:vms_app/data/datasources/remote/navigation_remote_datasource.dart';
import 'package:vms_app/data/datasources/remote/vessel_remote_datasource.dart';
import 'package:vms_app/data/datasources/remote/route_search_remote_datasource.dart';
import 'package:vms_app/data/datasources/remote/weather_remote_datasource.dart';
// Repository Implementations
import 'package:vms_app/data/repositories/terms_repository_impl.dart';
import 'package:vms_app/data/repositories/navigation_repository_impl.dart';
import 'package:vms_app/data/repositories/vessel_repository_impl.dart';
import 'package:vms_app/data/repositories/route_search_repository_impl.dart';
import 'package:vms_app/data/repositories/weather_repository_impl.dart';
// Repository Interfaces
import 'package:vms_app/domain/repositories/terms_repository.dart';
import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/domain/repositories/route_search_repository.dart';
import 'package:vms_app/domain/repositories/weather_repository.dart';
// UseCases
import 'package:vms_app/domain/usecases/auth/get_terms_list.dart';
import 'package:vms_app/domain/usecases/navigation/get_navigation_history.dart';
import 'package:vms_app/domain/usecases/navigation/get_weather_info.dart';
import 'package:vms_app/domain/usecases/vessel/search_vessel.dart';

final getIt = GetIt.instance;

/// Dependency Injection 초기화
Future<void> initInjection() async {
  // 순서: DataSources → Repositories → UseCases
  _injectDataSources();
  _injectRepositories();
  _injectUseCases();
}

/// DataSource 레이어 주입
void _injectDataSources() {
  // Remote DataSources - 싱글톤으로 등록
  getIt.registerLazySingleton<CmdSource>(() => CmdSource());
  getIt.registerLazySingleton<RosSource>(() => RosSource());
  getIt.registerLazySingleton<VesselSearchSource>(() => VesselSearchSource());
  getIt.registerLazySingleton<RouteSearchSource>(() => RouteSearchSource());
  getIt.registerLazySingleton<WidSource>(() => WidSource());
}

/// Repository 레이어 주입
void _injectRepositories() {
  // Terms Repository
  getIt.registerLazySingleton<TermsRepository>(
    () => TermsRepositoryImpl(getIt<CmdSource>()),
  );

  // Navigation Repository
  getIt.registerLazySingleton<NavigationRepository>(
    () => NavigationRepositoryImpl(getIt<RosSource>()),
  );

  // Vessel Repository
  getIt.registerLazySingleton<VesselRepository>(
    () => VesselRepositoryImpl(getIt<VesselSearchSource>()),
  );

  // Route Search Repository
  getIt.registerLazySingleton<RouteSearchRepository>(
    () => RouteSearchRepositoryImpl(getIt<RouteSearchSource>()),
  );

  // Weather Repository
  getIt.registerLazySingleton<WeatherRepository>(
    () => WeatherRepositoryImpl(getIt<WidSource>()),
  );
}

/// UseCase 레이어 주입
void _injectUseCases() {
  // Auth UseCases
  getIt.registerLazySingleton<GetTermsList>(
    () => GetTermsList(getIt<TermsRepository>()),
  );

  // Navigation UseCases
  getIt.registerLazySingleton<GetNavigationHistory>(
    () => GetNavigationHistory(getIt<NavigationRepository>()),
  );

  // Weather UseCases
  getIt.registerLazySingleton<GetWeatherInfo>(
    () => GetWeatherInfo(getIt<WeatherRepository>()),
  );

  // Vessel UseCases
  getIt.registerLazySingleton<SearchVessel>(
    () => SearchVessel(getIt<VesselRepository>()),
  );
}

/// GetIt 초기화 상태 확인
bool isInjectionInitialized() {
  try {
    // 주요 의존성이 등록되었는지 확인
    getIt<TermsRepository>();
    getIt<NavigationRepository>();
    getIt<VesselRepository>();
    return true;
  } catch (e) {
    return false;
  }
}

/// GetIt 리셋 (테스트용)
void resetInjection() {
  getIt.reset();
}
EOF

echo "✅ injection.dart 파일 생성 완료"

# 3. main.dart 수정 - initInjection 호출 추가
echo ""
echo "📝 main.dart에 initInjection 호출 추가 중..."

# main.dart 파일이 있는지 확인
if [ -f "lib/main.dart" ]; then
    # main.dart 백업
    cp lib/main.dart lib/main.dart.backup
    
    # initInjection 호출이 이미 있는지 확인
    if grep -q "initInjection()" lib/main.dart; then
        echo "⚠️  initInjection() 호출이 이미 존재합니다."
    else
        # main 함수에 initInjection 추가
        sed -i '/void main() async {/a\  WidgetsFlutterBinding.ensureInitialized();\n  await initInjection();' lib/main.dart
        
        # import 문 추가 (이미 없는 경우에만)
        if ! grep -q "import 'package:vms_app/core/di/injection.dart';" lib/main.dart; then
            sed -i "1s/^/import 'package:vms_app\/core\/di\/injection.dart';\n/" lib/main.dart
        fi
        
        echo "✅ main.dart 수정 완료"
    fi
else
    echo "⚠️  main.dart 파일을 찾을 수 없습니다."
fi

# 4. UseCase 파일들이 없으면 생성
echo ""
echo "📝 누락된 UseCase 파일 확인 및 생성 중..."

# SearchVessel UseCase 생성
if [ ! -f "lib/domain/usecases/vessel/search_vessel.dart" ]; then
    mkdir -p lib/domain/usecases/vessel
    cat > lib/domain/usecases/vessel/search_vessel.dart << 'EOF'
import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';

class SearchVessel {
  final VesselRepository repository;

  SearchVessel(this.repository);

  Future<List<VesselSearchModel>> execute({String? regDt, int? mmsi}) async {
    return await repository.getVesselList(regDt: regDt, mmsi: mmsi);
  }
}
EOF
    echo "✅ search_vessel.dart 생성 완료"
fi

# GetWeatherInfo UseCase 생성
if [ ! -f "lib/domain/usecases/navigation/get_weather_info.dart" ]; then
    mkdir -p lib/domain/usecases/navigation
    cat > lib/domain/usecases/navigation/get_weather_info.dart << 'EOF'
import 'package:vms_app/domain/repositories/weather_repository.dart';
import 'package:vms_app/data/models/weather/weather_model.dart';

class GetWeatherInfo {
  final WeatherRepository repository;

  GetWeatherInfo(this.repository);

  Future<List<WidModel>> execute() async {
    return await repository.getWidList();
  }
}
EOF
    echo "✅ get_weather_info.dart 생성 완료"
fi

# GetNavigationHistory UseCase 생성
if [ ! -f "lib/domain/usecases/navigation/get_navigation_history.dart" ]; then
    cat > lib/domain/usecases/navigation/get_navigation_history.dart << 'EOF'
import 'package:vms_app/domain/repositories/navigation_repository.dart';

class GetNavigationHistory {
  final NavigationRepository repository;

  GetNavigationHistory(this.repository);

  Future<List<dynamic>> execute({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  }) async {
    return await repository.getNavigationHistory(
      startDate: startDate,
      endDate: endDate,
      mmsi: mmsi,
      shipName: shipName,
    );
  }
}
EOF
    echo "✅ get_navigation_history.dart 생성 완료"
fi

# 5. Repository Interface 누락 확인
echo ""
echo "📝 Repository Interface 확인 중..."

# WeatherRepository Interface 생성
if [ ! -f "lib/domain/repositories/weather_repository.dart" ]; then
    cat > lib/domain/repositories/weather_repository.dart << 'EOF'
import 'package:vms_app/data/models/weather/weather_model.dart';

abstract class WeatherRepository {
  Future<List<WidModel>> getWidList();
}
EOF
    echo "✅ weather_repository.dart 생성 완료"
fi

# VesselRepository Interface 생성
if [ ! -f "lib/domain/repositories/vessel_repository.dart" ]; then
    cat > lib/domain/repositories/vessel_repository.dart << 'EOF'
import 'package:vms_app/data/models/vessel/vessel_search_model.dart';

abstract class VesselRepository {
  Future<List<VesselSearchModel>> getVesselList({String? regDt, int? mmsi});
}
EOF
    echo "✅ vessel_repository.dart 생성 완료"
fi

# RouteSearchRepository Interface 생성
if [ ! -f "lib/domain/repositories/route_search_repository.dart" ]; then
    cat > lib/domain/repositories/route_search_repository.dart << 'EOF'
import 'package:vms_app/data/models/navigation/vessel_route_model.dart';

abstract class RouteSearchRepository {
  Future<VesselRouteResponse> getVesselRoute({String? regDt, int? mmsi});
}
EOF
    echo "✅ route_search_repository.dart 생성 완료"
fi

# NavigationRepository Interface 수정
if [ ! -f "lib/domain/repositories/navigation_repository.dart" ]; then
    cat > lib/domain/repositories/navigation_repository.dart << 'EOF'
import 'package:vms_app/data/models/navigation/navigation_model.dart';

abstract class NavigationRepository {
  Future<List<RosModel>> getRosList({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  });
  
  Future<List<dynamic>> getNavigationHistory({
    String? startDate,
    String? endDate,
    int? mmsi,
    String? shipName,
  });
  
  Future<WeatherInfo?> getWeatherInfo();
  Future<List<String>?> getNavigationWarnings();
}
EOF
    echo "✅ navigation_repository.dart 생성 완료"
fi

echo ""
echo "========================================="
echo "✅ 의존성 주입 수정 완료!"
echo "========================================="
echo ""
echo "📌 수정된 파일:"
echo "  - lib/core/di/injection.dart"
echo "  - lib/main.dart (initInjection 호출 추가)"
echo ""
echo "📌 생성된 파일:"
echo "  - UseCase 파일들 (필요한 경우)"
echo "  - Repository Interface 파일들 (필요한 경우)"
echo ""
echo "📌 백업 파일:"
echo "  - lib/core/di/injection.dart.backup"
echo "  - lib/main.dart.backup"
echo ""
echo "🔧 다음 단계:"
echo "  1. flutter pub get"
echo "  2. flutter clean"
echo "  3. flutter pub get"
echo "  4. flutter run"
echo ""
echo "⚠️  문제 발생 시 백업 파일로 복원 가능합니다."
