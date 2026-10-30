import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:proj_1/features/home/presentation/screens/ar_view_screen.dart';
import 'package:proj_1/features/home/presentation/screens/model_viewer_screen.dart';
import '../../../../app/config/theme/theme_cubit.dart';

/// Màn hình chính (Dashboard Hub).
///
/// Cung cấp 2 lựa chọn trải nghiệm AR:
/// 1. AR Native 6DoF (ARCore Space Studio) - Quét sàn, đặt vật thể và đi vòng quanh.
/// 2. 3D Model Studio & Scene Viewer - Xoay/zoom mô hình và mở Google Scene Viewer.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AR 3D Production Studio'),
        actions: [
          // Nút chuyển đổi nhanh chế độ Giao diện Sáng (Light) / Tối (Dark)
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Đổi giao diện Sáng / Tối',
            onPressed: () {
              context.read<ThemeCubit>().toggleTheme();
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Thẻ giới thiệu tổng quan
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.view_in_ar,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AR Space Studio',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Trải nghiệm thực tế tăng cường 6DoF với công nghệ Google ARCore & Scene Viewer.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ==========================================
              // NÚT 1: CHẾ ĐỘ AR NATIVE (CỐT LÕI 6DoF)
              // ==========================================
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Colors.amber[800],
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.spatial_audio_off_rounded, size: 28),
                label: const Text(
                  'AR Native (ARCore 6DoF)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  // Mở màn hình quét mặt sàn & ghim mỏ neo thực tế
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ArViewScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // ==========================================
              // NÚT 2: CHẾ ĐỘ XEM 3D & GOOGLE SCENE VIEWER
              // ==========================================
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.rocket_launch_outlined, size: 28),
                label: const Text(
                  '3D Model & Scene Viewer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  // Mở mô hình Phi hành gia mẫu
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ModelViewerScreen(
                        modelUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
                        modelTitle: 'Mô hình Phi Hành Gia',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
