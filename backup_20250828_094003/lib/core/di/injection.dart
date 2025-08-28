import 'package:get_it/get_it.dart';
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

Future<void> initInjection() async {
  // ===== DataSources =====
  getIt.registerLazySingleton(() => CmdSource());
  getIt.registerLazySingleton(() => RosSource());
  getIt.registerLazySingleton(() => VesselSearchSource());
  getIt.registerLazySingleton(() => RouteSearchSource());
  getIt.registerLazySingleton(() => WidSource());

  // ===== Repositories =====
  getIt.registerLazySingleton<TermsRepository>(
        () => TermsRepositoryImpl(getIt<CmdSource>()),
  );

  getIt.registerLazySingleton<VesselRepository>(
        () => VesselRepositoryImpl(getIt<VesselSearchSource>()),
  );

  // RouteSearchRepository 인터페이스로 등록
  getIt.registerLazySingleton<RouteSearchRepository>(
        () => RouteSearchRepositoryImpl(getIt<RouteSearchSource>()),
  );

  getIt.registerLazySingleton<NavigationRepository>(
        () => NavigationRepositoryImpl(getIt<RosSource>()),
  );

  // WeatherRepositoryImpl로 수정
  getIt.registerLazySingleton<WeatherRepository>(
        () => WeatherRepositoryImpl(getIt<WidSource>()),
  );

  // ===== UseCases =====
  getIt.registerLazySingleton(() => GetTermsList(getIt<TermsRepository>()));
  getIt.registerLazySingleton(() => GetNavigationHistory(getIt<NavigationRepository>()));
  getIt.registerLazySingleton(() => GetWeatherInfo(getIt<NavigationRepository>()));
  getIt.registerLazySingleton(() => SearchVessel(getIt<VesselRepository>()));
}