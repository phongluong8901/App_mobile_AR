import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit quản lý trạng thái Theme của toàn bộ ứng dụng (Sáng / Tối / Tự động theo hệ thống).
class ThemeCubit extends Cubit<ThemeMode> {
  // Mặc định khởi đầu theo cấu hình của hệ điều hành thiết bị
  ThemeCubit() : super(ThemeMode.system);

  /// Cập nhật chủ động Theme cụ thể (ThemeMode.light, dark, hoặc system)
  void updateThemeMode(ThemeMode mode) {
    emit(mode);
  }

  /// Đảo ngược chế độ Theme giữa Sáng (Light) và Tối (Dark)
  void toggleTheme() {
    if (state == ThemeMode.light) {
      emit(ThemeMode.dark);
    } else {
      emit(ThemeMode.light);
    }
  }
}
