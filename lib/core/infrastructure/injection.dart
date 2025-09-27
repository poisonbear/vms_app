import 'package:get_it/get_it.dart';
import 'package:vms_app/core/infrastructure/network_client.dart';
import 'package:vms_app/core/services/cache_service.dart';
import 'package:vms_app/core/services/state_manager.dart' as sm;
import 'package:vms_app/core/services/location_service.dart';
import 'package:vms_app/core/utils/app_logger.dart';

// DataSources - 새로운 이름과 기존 typedef 모두 포함
import 'package:vms_app/data/datasources/terms_datasource.dart';
import 'package:vms_app/data/datasources/navigation_datasource.dart';
import 'package:vms_app/data/datasources/vessel_datasource.dart';
import 'package:vms_app/data/datasources/weather_datasource.dart';
import 'package:vms_app/data/datasources/emergency_datasource.dart';

// Repositories - 새로운 이름과 기존 typedef 모두 포함
import 'package:vms_app/data/repositories/terms_repository.dart';
import 'package:vms_app/data/repositories/navigation_repository.dart';
import 'package:vms_app/data/repositories/vessel_repository.dart';
import 'package:vms_app/data/repositories/weather_repository.dart';
import 'package:vms_app/data/repositories/emergency_repository.dart';

// Domain Repositories
import 'package:vms_app/domain/repositories/terms_repository.dart' as domain;
import 'package:vms_app/domain/repositories/navigation_repository.dart' as domain;
import 'package:vms_app/domain/repositories/vessel_repository.dart' as domain;
import 'package:vms_app/domain/repositories/route_search_repository.dart' as domain;
import 'package:vms_app/domain/repositories/weather_repository.dart' as domain;

// UseCases
import 'package:vms_app/domain/usecases/auth/get_terms_list.dart';
import 'package:vms_app/domain/usecases/navigation/get_navigation_history.dart';
import 'package:vms_app/domain/usecases/navigation/get_weather_info.dart';
import 'package:vms_app/domain/usecases/vessel/search_vessel.dart';

// Domain Repositories

// UseCases

final getIt = GetIt.instance;

/// Dependency Injection 설정
void setupDependencies() {
  // 1. Infrastructure & Services 등록
  _registerInfrastructure();
  _registerServices();

  // 2. Data Layer 등록
  _registerDataSources();
  _registerRepositories();

  // 3. Domain Layer 등록
  _registerUseCases();
}

/// Infrastructure 등록
void _registerInfrastructure() {
  // Network
  getIt.registerLazySingleton<DioRequest>(() => DioRequest());

  // Cache
  getIt.registerLazySingleton<CacheService>(() => CacheService());
}

/// Services 등록
void _registerServices() {
  // State Manager
  getIt.registerLazySingleton<sm.StateManager>(() => sm.StateManager());

  // Location Service
  getIt.registerLazySingleton<LocationService>(() => LocationService());
}

/// DataSources 등록
void _registerDataSources() {
  // Remote DataSources (새로운 클래스명만 등록)
  getIt.registerLazySingleton<TermsDataSource>(
        () => TermsDataSource(),
  );

  getIt.registerLazySingleton<NavigationDataSource>(
        () => NavigationDataSource(),
  );

  getIt.registerLazySingleton<VesselDataSource>(
        () => VesselDataSource(),
  );

  getIt.registerLazySingleton<WeatherDataSource>(
        () => WeatherDataSource(),
  );

  // Local DataSource
  getIt.registerLazySingleton<EmergencyDataSource>(
        () => EmergencyDataSource(),
  );

  // 기존 이름들은 typedef로 자동 처리됨
  // CmdSource = TermsDataSource
  // RosSource = NavigationDataSource
  // VesselSearchSource = VesselDataSource
  // RouteSearchSource = VesselDataSource
  // WidSource = WeatherDataSource
}

/// Repositories 등록
void _registerRepositories() {
  // Data Layer Repositories (새로운 클래스명만 등록)
  getIt.registerLazySingleton<TermsRepository>(
        () => TermsRepository(getIt<TermsDataSource>()),
  );

  getIt.registerLazySingleton<NavigationRepository>(
        () => NavigationRepository(getIt<NavigationDataSource>()),
  );

  getIt.registerLazySingleton<VesselRepository>(
        () => VesselRepository(getIt<VesselDataSource>()),
  );

  getIt.registerLazySingleton<WeatherRepository>(
        () => WeatherRepository(getIt<WeatherDataSource>()),
  );

  getIt.registerLazySingleton<EmergencyRepository>(
        () => EmergencyRepository(getIt<EmergencyDataSource>()),
  );

  // Domain Layer Repository Interfaces
  getIt.registerLazySingleton<domain.TermsRepository>(
        () => getIt<TermsRepository>(),
  );

  getIt.registerLazySingleton<domain.NavigationRepository>(
        () => getIt<NavigationRepository>(),
  );

  getIt.registerLazySingleton<domain.VesselRepository>(
        () => getIt<VesselRepository>(),
  );

  getIt.registerLazySingleton<domain.RouteSearchRepository>(
        () => getIt<VesselRepository>(), // VesselRepository가 RouteSearchRepository도 구현
  );

  getIt.registerLazySingleton<domain.WeatherRepository>(
        () => getIt<WeatherRepository>(),
  );

  // 기존 이름들은 typedef로 자동 처리됨
  // TermsRepositoryImpl = TermsRepository
  // NavigationRepositoryImpl = NavigationRepository
  // VesselRepositoryImpl = VesselRepository
  // RouteSearchRepositoryImpl = VesselRepository
  // WeatherRepositoryImpl = WeatherRepository
}

/// UseCases 등록
void _registerUseCases() {
  // Auth/Terms
  getIt.registerFactory<GetTermsList>(
        () => GetTermsList(getIt<domain.TermsRepository>()),
  );

  // Navigation
  getIt.registerFactory<GetNavigationHistory>(
        () => GetNavigationHistory(getIt<domain.NavigationRepository>()),
  );

  getIt.registerFactory<GetWeatherInfo>(
        () => GetWeatherInfo(getIt<domain.NavigationRepository>()),
  );

  // Vessel
  getIt.registerFactory<SearchVessel>(
        () => SearchVessel(getIt<domain.VesselRepository>()),
  );
}

/// DI 초기화 확인
void verifyDependencies() {
  AppLogger.d('=== DI Configuration ===');
  AppLogger.d('Infrastructure: ${getIt.isRegistered<DioRequest>() ? "✓" : "✗"}');
  AppLogger.d('DataSources: ${getIt.isRegistered<VesselDataSource>() ? "✓" : "✗"}');
  AppLogger.d('Repositories: ${getIt.isRegistered<VesselRepository>() ? "✓" : "✗"}');
  AppLogger.d('UseCases: ${getIt.isRegistered<SearchVessel>() ? "✓" : "✗"}');
  AppLogger.d('========================');
}

/// main.dart 호환성을 위한 초기화 함수
Future<void> initInjection() async {
  setupDependencies();
}