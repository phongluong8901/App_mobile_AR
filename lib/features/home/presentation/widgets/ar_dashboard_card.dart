import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Tiện ích chuyển đổi Widget Flutter thành dữ liệu ảnh PNG (Uint8List).
/// Được sử dụng để tạo Texture 3D sắc nét cho màn hình AR Dashboard lơ lửng.
class WidgetToImageConverter {
  WidgetToImageConverter._();

  /// Chuyển đổi một GlobalKey gắn với `RepaintBoundary` thành `Uint8List` (ảnh PNG)
  static Future<Uint8List?> capturePng(GlobalKey globalKey) async {
    try {
      final boundary =
          globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Render với pixelRatio = 3.0 để chữ và biểu đồ cực kỳ sắc nét trên AR
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Lỗi chuyển Widget sang ảnh Texture: $e');
      return null;
    }
  }
}

/// Widget giao diện Thẻ Hologram Dashboard công nghệ cao.
/// Hiển thị các chỉ số: Thời gian thực tế, Trạng thái hệ thống, Tín hiệu AR, Pin và Biểu đồ hoạt động.
class ArDashboardCard extends StatelessWidget {
  final String currentTime;
  final String title;
  final int activeNodes;

  const ArDashboardCard({
    super.key,
    required this.currentTime,
    this.title = 'JARVIS AR SPACE DASHBOARD',
    this.activeNodes = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 440,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1D), // Nền xanh đen sâu công nghệ cao
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00E5FF), // Viền Cyan phát quang nổi bật
          width: 3.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x6600E5FF),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Icon trạng thái + Tiêu đề + Đèn Live
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: Color(0xFF00E5FF),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Text(
                      'SLAM 6DoF SPATIAL TRACKING: ONLINE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent, width: 1.2),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),

          // 2. Nội dung chính: Đồng hồ thời gian + Card thống kê
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Đồng hồ kỹ thuật số lớn
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LOCAL TIME (REAL-TIME)',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),

              // Chỉ số vật thể đã ghim trong không gian
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber, width: 1.5),
                ),
                child: Column(
                  children: [
                    const Text(
                      'ANCHORS',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$activeNodes Pinned',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Thanh đo tín hiệu ảo (Signal & Space Grid)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SPATIAL ACCURACY: 99.8%',
                      style: TextStyle(color: Colors.white70, fontSize: 9),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.92,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LIGHT ESTIMATION: OPTIMAL',
                      style: TextStyle(color: Colors.white70, fontSize: 9),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.85,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

