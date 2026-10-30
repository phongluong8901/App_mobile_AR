import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/config/theme/app_theme.dart';
import 'app/config/theme/theme_cubit.dart';
import 'core/di/injection.dart' as di;
import 'features/home/presentation/screens/home_screen.dart';

/// Điểm bắt đầu (Entry Point) của toàn bộ ứng dụng Flutter.
void main() async {
  // Đảm bảo các binding cấp hệ thống (Native Engine) được khởi tạo xong trước khi chạy app
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo hệ thống tiêm phụ thuộc (Dependency Injection - GetIt)
  await di.initDependencies();

  runApp(const ProductionArApp());
}

/// Widget gốc của ứng dụng (Root Application Widget)
class ProductionArApp extends StatelessWidget {
  const ProductionArApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cung cấp ThemeCubit cho toàn bộ cây widget để lắng nghe và chuyển đổi Theme sáng/tối
    return MultiBlocProvider(
      providers: [BlocProvider<ThemeCubit>(create: (_) => di.sl<ThemeCubit>())],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'AR 3D Production App',
            debugShowCheckedModeBanner: false, // Tắt nhãn DEBUG góc phải

            // Cấu hình giao diện Light & Dark mode theo chuẩn Material 3
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode, // Điều khiển chế độ hiển thị hiện tại

            // Màn hình chính đầu tiên khi mở app
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
