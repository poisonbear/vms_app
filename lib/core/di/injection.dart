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
  // Remote DataSources
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
  // ⚠️ 확인 필요: NavigationRepository가 맞나요?
  // 만약 WeatherRepository를 사용해야 한다면 수정 필요
  getIt.registerLazySingleton<GetWeatherInfo>(
        () => GetWeatherInfo(getIt<NavigationRepository>()),
  );

  // Vessel UseCases
  getIt.registerLazySingleton<SearchVessel>(
        () => SearchVessel(getIt<VesselRepository>()),
  );
}

/// DI 컨테이너 리셋 (테스트용)
void resetInjection() {
  getIt.reset();
}

/// 특정 타입이 등록되어 있는지 확인
bool isRegistered<T extends Object>() {
  return getIt.isRegistered<T>();
}