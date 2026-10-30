import 'package:get_it/get_it.dart';

import '../../app/config/theme/theme_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // 1. Quản lý trạng thái App & Cubit
  sl.registerLazySingleton(() => ThemeCubit());

  // 2. Core Services (AR Engine, Local Storage, Network Client)
  // Ví dụ: sl.registerLazySingleton<ArCoreService>(() => ArCoreServiceImpl());
}
