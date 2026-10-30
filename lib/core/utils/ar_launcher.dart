import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Class tiện ích chịu trách nhiệm khởi chạy Google Scene Viewer
/// (Dịch vụ hiển thị AR 3D 6DoF chuẩn chính chủ của Google trên Android).
class ArLauncher {
  ArLauncher._(); // Private constructor để ngăn chặn việc khởi tạo đối tượng instance

  /// Mở Google Scene Viewer trực tiếp từ URL của file 3D (.glb).
  ///
  /// * [context]: Dùng để lấy ScaffoldMessenger hiển thị SnackBar khi có lỗi.
  /// * [modelUrl]: Đường dẫn trực tiếp tới file mô hình 3D (.glb).
  /// * [title]: Tiêu đề hiển thị trên thanh công cụ AR.
  static Future<void> launchAr({
    required BuildContext context,
    required String modelUrl,
    required String title,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    // 1. Xây dựng URL theo đặc tả kỹ thuật chuẩn của Google Scene Viewer
    // Tham khảo: https://developers.google.com/ar/develop/scene-viewer
    final uri = Uri.https('arvr.google.com', '/scene-viewer/1.0', {
      'file': modelUrl,          // Link tải mô hình 3D (.glb)
      'mode': 'ar_preferred',    // Ưu tiên mở thẳng vào camera AR thay vì chỉ xem 3D trên màn hình phẳng
      'title': title,            // Tên vật thể
      'resizable': 'true',       // Cho phép người dùng dùng 2 ngón tay phóng to/thu nhỏ mô hình ngoài đời
    });
    final sceneViewerUrl = uri.toString();

    if (Platform.isAndroid) {
      // Chiến lược 1: Thử gọi qua ứng dụng Google chính (Google Quick Search Box) - Nơi Scene Viewer thường tích hợp sẵn
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: sceneViewerUrl,
          package: 'com.google.android.googlequicksearchbox',
        );
        await intent.launch();
        return;
      } catch (e) {
        debugPrint('Google QuickSearchBox intent failed: $e');
      }

      // Chiến lược 2 (Fallback 1): Gọi trực tiếp qua dịch vụ Google Play Services for AR (ARCore APK)
      try {
        final arCoreIntent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: sceneViewerUrl,
          package: 'com.google.ar.core',
        );
        await arCoreIntent.launch();
        return;
      } catch (e) {
        debugPrint('ARCore intent failed: $e');
      }

      // Chiến lược 3 (Fallback 2): Phát Intent tổng quát không chỉ định package (Để Android tự chọn App hỗ trợ)
      try {
        final generalIntent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: sceneViewerUrl,
        );
        await generalIntent.launch();
        return;
      } catch (e) {
        debugPrint('General intent failed: $e');
      }
    }

    // Chiến lược 4 (Fallback cuối cho Browser / iOS QuickLook): Mở bằng trình duyệt ngoài
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    // Thông báo nếu thiết bị chưa cài đặt dịch vụ Google AR hoặc không hỗ trợ
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Không thể khởi động Scene Viewer. Hãy kiểm tra ứng dụng Google trên máy.',
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
