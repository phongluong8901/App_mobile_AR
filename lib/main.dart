import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/config/theme/app_theme.dart';
import 'app/config/theme/theme_cubit.dart';
import 'core/di/injection.dart' as di;
import 'features/home/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Dependency Injection
  await di.initDependencies();

  runApp(const ProductionArApp());
}

class ProductionArApp extends StatelessWidget {
  const ProductionArApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider<ThemeCubit>(create: (_) => di.sl<ThemeCubit>())],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'AR 3D Production App',
            debugShowCheckedModeBanner: false,

            // Cấu hình Theme động theo Cubit
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,

            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
