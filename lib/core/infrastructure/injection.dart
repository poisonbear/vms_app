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

// Domain Repositories - 수정된 import
import 'package:vms_app/domain/repositories/terms_repository.dart' as domain;
import 'package:vms_app/domain/repositories/navigation_repository.dart' as domain;
import 'package:vms_app/domain/repositories/vessel_repository.dart' as domain;
import 'package:vms_app/domain/repositories/weather_repository.dart' as domain;
import 'package:vms_app/domain/repositories/emergency_repository.dart' as domain;

// UseCases - 새로운 평면 구조
import 'package:vms_app/domain/usecases/terms_usecases.dart';
import 'package:vms_app/domain/usecases/navigation_usecases.dart';
import 'package:vms_app/domain/usecases/vessel_usecases.dart';
import 'package:vms_app/domain/usecases/weather_usecases.dart';
import 'package:vms_app/domain/usecases/emergency_usecases.dart';

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

  getIt.registerLazySingleton<domain.WeatherRepository>(
        () => getIt<WeatherRepository>(),
  );

  getIt.registerLazySingleton<domain.EmergencyRepository>(
        () => getIt<EmergencyRepository>(),
  );

  // 기존 이름들은 typedef로 자동 처리됨
  // TermsRepositoryImpl = TermsRepository
  // NavigationRepositoryImpl = NavigationRepository
  // VesselRepositoryImpl = VesselRepository
  // RouteSearchRepositoryImpl = VesselRepository (vessel에 통합)
  // WeatherRepositoryImpl = WeatherRepository
}

/// UseCases 등록
void _registerUseCases() {
  // ===== 통합 UseCase 클래스들 등록 =====

  // Terms
  getIt.registerFactory<TermsUseCases>(
        () => TermsUseCases(getIt<domain.TermsRepository>()),
  );

  // Navigation
  getIt.registerFactory<NavigationUseCases>(
        () => NavigationUseCases(getIt<domain.NavigationRepository>()),
  );

  // Vessel
  getIt.registerFactory<VesselUseCases>(
        () => VesselUseCases(getIt<domain.VesselRepository>()),
  );

  // Weather
  getIt.registerFactory<WeatherUseCases>(
        () => WeatherUseCases(getIt<domain.WeatherRepository>()),
  );

  // Emergency
  getIt.registerFactory<EmergencyUseCases>(
        () => EmergencyUseCases(getIt<domain.EmergencyRepository>()),
  );

  // ===== 개별 UseCase 클래스들 등록 (기존 호환성 유지) =====

  // Terms/Auth UseCases
  getIt.registerFactory<GetTermsList>(
        () => GetTermsList(getIt<domain.TermsRepository>()),
  );

  // Navigation UseCases
  getIt.registerFactory<GetNavigationHistory>(
        () => GetNavigationHistory(getIt<domain.NavigationRepository>()),
  );

  getIt.registerFactory<GetWeatherInfo>(
        () => GetWeatherInfo(getIt<domain.NavigationRepository>()),
  );

  getIt.registerFactory<GetNavigationWarnings>(
        () => GetNavigationWarnings(getIt<domain.NavigationRepository>()),
  );

  // Vessel UseCases
  getIt.registerFactory<SearchVessel>(
        () => SearchVessel(getIt<domain.VesselRepository>()),
  );

  getIt.registerFactory<GetVesselRoute>(
        () => GetVesselRoute(getIt<domain.VesselRepository>()),
  );

  // Weather UseCases
  getIt.registerFactory<GetWeatherList>(
        () => GetWeatherList(getIt<domain.WeatherRepository>()),
  );

  getIt.registerFactory<GetCurrentWeather>(
        () => GetCurrentWeather(getIt<domain.WeatherRepository>()),
  );

  // Emergency UseCases
  getIt.registerFactory<SaveEmergencyData>(
        () => SaveEmergencyData(getIt<domain.EmergencyRepository>()),
  );

  getIt.registerFactory<LoadEmergencyHistory>(
        () => LoadEmergencyHistory(getIt<domain.EmergencyRepository>()),
  );

  getIt.registerFactory<LoadLastEmergency>(
        () => LoadLastEmergency(getIt<domain.EmergencyRepository>()),
  );

  getIt.registerFactory<ClearEmergencyHistory>(
        () => ClearEmergencyHistory(getIt<domain.EmergencyRepository>()),
  );

  getIt.registerFactory<SaveLocationTracking>(
        () => SaveLocationTracking(getIt<domain.EmergencyRepository>()),
  );

  getIt.registerFactory<LoadLocationTracking>(
        () => LoadLocationTracking(getIt<domain.EmergencyRepository>()),
  );

  getIt.registerFactory<CheckActiveEmergency>(
        () => CheckActiveEmergency(getIt<domain.EmergencyRepository>()),
  );
}

/// DI 초기화 확인
void verifyDependencies() {
  AppLogger.d('=== DI Configuration ===');
  AppLogger.d('Infrastructure: ${getIt.isRegistered<DioRequest>() ? "✓" : "✗"}');
  AppLogger.d('DataSources: ${getIt.isRegistered<VesselDataSource>() ? "✓" : "✗"}');
  AppLogger.d('Repositories: ${getIt.isRegistered<VesselRepository>() ? "✓" : "✗"}');
  AppLogger.d('Domain Repositories: ${getIt.isRegistered<domain.VesselRepository>() ? "✓" : "✗"}');
  AppLogger.d('UseCases (Individual): ${getIt.isRegistered<SearchVessel>() ? "✓" : "✗"}');
  AppLogger.d('UseCases (Integrated): ${getIt.isRegistered<VesselUseCases>() ? "✓" : "✗"}');
  AppLogger.d('Emergency: ${getIt.isRegistered<EmergencyUseCases>() ? "✓" : "✗"}');
  AppLogger.d('========================');
}

/// main.dart 호환성을 위한 초기화 함수
Future<void> initInjection() async {
  setupDependencies();
}