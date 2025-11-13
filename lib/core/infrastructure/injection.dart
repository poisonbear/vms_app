// lib/core/infrastructure/injection.dart

import 'package:get_it/get_it.dart';
import 'package:vms_app/core/infrastructure/network_client.dart';
import 'package:vms_app/core/services/services.dart';
import 'package:vms_app/core/utils/logging/app_logger.dart';

// DataSources
import 'package:vms_app/data/datasources/terms_datasource.dart';
import 'package:vms_app/data/datasources/navigation_datasource.dart';
import 'package:vms_app/data/datasources/vessel_datasource.dart';
import 'package:vms_app/data/datasources/weather_datasource.dart';
import 'package:vms_app/data/datasources/emergency_datasource.dart';

// Repositories
import 'package:vms_app/data/repositories/terms_repository.dart';
import 'package:vms_app/data/repositories/navigation_repository.dart';
import 'package:vms_app/data/repositories/vessel_repository.dart';
import 'package:vms_app/data/repositories/weather_repository.dart';
import 'package:vms_app/data/repositories/emergency_repository.dart';

// Domain Repositories
import 'package:vms_app/domain/repositories/terms_repository.dart' as domain;
import 'package:vms_app/domain/repositories/navigation_repository.dart'
    as domain;
import 'package:vms_app/domain/repositories/vessel_repository.dart' as domain;
import 'package:vms_app/domain/repositories/weather_repository.dart' as domain;
import 'package:vms_app/domain/repositories/emergency_repository.dart'
    as domain;

// UseCases
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
  getIt.registerLazySingleton<NetworkClient>(() => NetworkClient());
  getIt.registerLazySingleton<DioRequest>(() => DioRequest());

  // Cache
  getIt.registerLazySingleton<PersistentCacheService>(
      () => PersistentCacheService());

  AppLogger.d('Infrastructure registered');
}

/// Services 등록
void _registerServices() {
  // State Manager
  getIt.registerLazySingleton<StateManager>(() => StateManager());

  // Location Service
  getIt.registerLazySingleton<LocationService>(() => LocationService());

  AppLogger.d('Services registered');
}

/// DataSources 등록
void _registerDataSources() {
  // Remote DataSources
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

  AppLogger.d('DataSources registered');
}

/// Repositories 등록
void _registerRepositories() {
  // Data Layer Repositories
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

  // Domain Repositories
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

  AppLogger.d('Repositories registered');
}

/// UseCases 등록
void _registerUseCases() {
  // Terms UseCases
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

  getIt.registerFactory<GetNavigationWarningDetails>(
    () => GetNavigationWarningDetails(getIt<domain.NavigationRepository>()),
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

  AppLogger.d('UseCases registered');
}

/// DI 초기화 확인
void verifyDependencies() {
  AppLogger.d('=== DI Configuration ===');
  AppLogger.d(
      'NetworkClient: ${getIt.isRegistered<NetworkClient>() ? "✓" : "✗"}');
  AppLogger.d('DioRequest: ${getIt.isRegistered<DioRequest>() ? "✓" : "✗"}');
  AppLogger.d(
      'DataSources: ${getIt.isRegistered<VesselDataSource>() ? "✓" : "✗"}');
  AppLogger.d(
      'Repositories: ${getIt.isRegistered<VesselRepository>() ? "✓" : "✗"}');
  AppLogger.d(
      'Domain Repositories: ${getIt.isRegistered<domain.VesselRepository>() ? "✓" : "✗"}');
  AppLogger.d('UseCases: ${getIt.isRegistered<SearchVessel>() ? "✓" : "✗"}');
  AppLogger.d(
      'Emergency: ${getIt.isRegistered<EmergencyDataSource>() ? "✓" : "✗"}');
  AppLogger.d('========================');
}

/// main.dart 호환성을 위한 초기화 함수
Future<void> initInjection() async {
  setupDependencies();
}
