import 'package:get_it/get_it.dart';
import 'package:vms_app/core/infrastructure/network_client.dart';
import 'package:vms_app/core/services/cache_service.dart';
import 'package:vms_app/core/services/state_manager.dart' as sm;
import 'package:vms_app/core/services/location_service.dart';
import 'package:vms_app/data/datasources/remote/terms_remote_datasource.dart';
import 'package:vms_app/data/datasources/remote/navigation_remote_datasource.dart';
import 'package:vms_app/data/datasources/remote/vessel_remote_datasource.dart';
import 'package:vms_app/data/datasources/remote/route_search_remote_datasource.dart';
import 'package:vms_app/data/datasources/remote/weather_remote_datasource.dart';
import 'package:vms_app/data/repositories/terms_repository_impl.dart';
import 'package:vms_app/data/repositories/navigation_repository_impl.dart';
import 'package:vms_app/data/repositories/vessel_repository_impl.dart';
import 'package:vms_app/data/repositories/route_search_repository_impl.dart';
import 'package:vms_app/data/repositories/weather_repository_impl.dart';
import 'package:vms_app/domain/repositories/terms_repository.dart';
import 'package:vms_app/domain/repositories/navigation_repository.dart';
import 'package:vms_app/domain/repositories/vessel_repository.dart';
import 'package:vms_app/domain/repositories/route_search_repository.dart';
import 'package:vms_app/domain/repositories/weather_repository.dart';
import 'package:vms_app/domain/usecases/auth/get_terms_list.dart';
import 'package:vms_app/domain/usecases/navigation/get_navigation_history.dart';
import 'package:vms_app/domain/usecases/navigation/get_weather_info.dart';
import 'package:vms_app/domain/usecases/vessel/search_vessel.dart';

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

/// Infrastructure 레이어 등록
void _registerInfrastructure() {
  if (!getIt.isRegistered<NetworkClient>()) {
    getIt.registerLazySingleton<NetworkClient>(() => NetworkClient());
  }

  // DioRequest 호환성 등록
  if (!getIt.isRegistered<DioRequest>()) {
    getIt.registerLazySingleton<DioRequest>(() => DioRequest());
  }
}

/// Services 레이어 등록
void _registerServices() {
  // Cache Service
  if (!getIt.isRegistered<CacheService>()) {
    getIt.registerLazySingleton<CacheService>(() => CacheService());
  }

  // State Manager - state_manager.dart 사용
  if (!getIt.isRegistered<sm.StateManager>()) {
    getIt.registerLazySingleton<sm.StateManager>(() => sm.StateManager());
  }

  // Location Service
  if (!getIt.isRegistered<LocationService>()) {
    getIt.registerLazySingleton<LocationService>(() => LocationService());
  }

  // Timer Service
  if (!getIt.isRegistered<TimerService>()) {
    getIt.registerLazySingleton<TimerService>(() => TimerService());
  }

  // Location Focus Service
  if (!getIt.isRegistered<LocationFocusService>()) {
    getIt.registerLazySingleton<LocationFocusService>(() => LocationFocusService());
  }

  // Memory Manager
  if (!getIt.isRegistered<MemoryManager>()) {
    getIt.registerLazySingleton<MemoryManager>(() => MemoryManager());
  }
}

/// DataSource 레이어 등록
void _registerDataSources() {
  if (!getIt.isRegistered<CmdSource>()) {
    getIt.registerLazySingleton<CmdSource>(() => CmdSource());
  }

  if (!getIt.isRegistered<RosSource>()) {
    getIt.registerLazySingleton<RosSource>(() => RosSource());
  }

  if (!getIt.isRegistered<VesselSearchSource>()) {
    getIt.registerLazySingleton<VesselSearchSource>(() => VesselSearchSource());
  }

  if (!getIt.isRegistered<RouteSearchSource>()) {
    getIt.registerLazySingleton<RouteSearchSource>(() => RouteSearchSource());
  }

  if (!getIt.isRegistered<WidSource>()) {
    getIt.registerLazySingleton<WidSource>(() => WidSource());
  }
}

/// Repository 레이어 등록
void _registerRepositories() {
  // Terms Repository
  if (!getIt.isRegistered<TermsRepository>()) {
    getIt.registerLazySingleton<TermsRepository>(
          () => TermsRepositoryImpl(getIt<CmdSource>()),
    );
  }

  // Navigation Repository
  if (!getIt.isRegistered<NavigationRepository>()) {
    getIt.registerLazySingleton<NavigationRepository>(
          () => NavigationRepositoryImpl(getIt<RosSource>()),
    );
  }

  // Vessel Repository
  if (!getIt.isRegistered<VesselRepository>()) {
    getIt.registerLazySingleton<VesselRepository>(
          () => VesselRepositoryImpl(getIt<VesselSearchSource>()),
    );
  }

  // Route Search Repository
  if (!getIt.isRegistered<RouteSearchRepository>()) {
    getIt.registerLazySingleton<RouteSearchRepository>(
          () => RouteSearchRepositoryImpl(getIt<RouteSearchSource>()),
    );
  }

  // Weather Repository
  if (!getIt.isRegistered<WeatherRepository>()) {
    getIt.registerLazySingleton<WeatherRepository>(
          () => WeatherRepositoryImpl(getIt<WidSource>()),
    );
  }
}

/// Use Case 레이어 등록
void _registerUseCases() {
  // Auth Use Cases
  if (!getIt.isRegistered<GetTermsList>()) {
    getIt.registerLazySingleton<GetTermsList>(
          () => GetTermsList(getIt<TermsRepository>()),
    );
  }

  // Navigation Use Cases
  if (!getIt.isRegistered<GetNavigationHistory>()) {
    getIt.registerLazySingleton<GetNavigationHistory>(
          () => GetNavigationHistory(getIt<NavigationRepository>()),
    );
  }

  if (!getIt.isRegistered<GetWeatherInfo>()) {
    getIt.registerLazySingleton<GetWeatherInfo>(
          () => GetWeatherInfo(getIt<NavigationRepository>()),
    );
  }

  // Vessel Use Cases
  if (!getIt.isRegistered<SearchVessel>()) {
    getIt.registerLazySingleton<SearchVessel>(
          () => SearchVessel(getIt<VesselRepository>()),
    );
  }
}

/// 초기화 함수 (main.dart 호환성)
Future<void> initInjection() async {
  setupDependencies();
}

/// Dependency Injection 초기화
Future<void> initializeDependencies() async {
  setupDependencies();
}