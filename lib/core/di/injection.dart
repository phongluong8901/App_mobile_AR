import 'package:get_it/get_it.dart';
import '../../app/config/theme/theme_cubit.dart';

/// Service Locator instance (GetIt) toàn cục của ứng dụng.
final GetIt sl = GetIt.instance;

/// Khởi tạo và đăng ký các dependencies (Singletons / Factories) khi khởi động app.
Future<void> initDependencies() async {
  // 1. Quản lý trạng thái App: Đăng ký ThemeCubit dưới dạng LazySingleton
  // (Chỉ khởi tạo một instance duy nhất khi được gọi lần đầu)
  sl.registerLazySingleton(() => ThemeCubit());

  // 2. Tầng Core Services / Repositories (nếu sau này mở rộng thêm API backend, Firebase, v.v.)
}
