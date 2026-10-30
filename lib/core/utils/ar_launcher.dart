import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ArLauncher {
  ArLauncher._();

  /// Mở Google Scene Viewer trực tiếp qua Android Native Intent
  /// Sử dụng mode=ar_preferred thay vì mode=ar_only để tránh lỗi sập màn hình đen khi camera chưa sẵn sàng
  static Future<void> launchAr({
    required BuildContext context,
    required String modelUrl,
    required String title,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    if (Platform.isAndroid) {
      final sceneViewerUrl =
          'https://arvr.google.com/scene-viewer/1.0?file=${Uri.encodeComponent(modelUrl)}&mode=ar_preferred&title=${Uri.encodeComponent(title)}&resizable=true';

      // 1. Thử gọi qua Google App (Google Quick Search Box) - ứng dụng chứa Scene Viewer chuẩn nhất của Android
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

      // 2. Thử gọi qua Google Play Services for AR (ARCore)
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

      // 3. Fallback mở qua browser / Chrome Custom Tabs
      final uri = Uri.parse(sceneViewerUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Nếu không mở được (ví dụ máy thiếu dịch vụ Google)
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Không thể khởi động Scene Viewer. Hãy kiểm tra ứng dụng Google hoặc Google Play Services for AR trên máy.',
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

