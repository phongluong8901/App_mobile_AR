import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Bộ sinh ảnh Texture Bảng Dữ Liệu Data Dashboard sắc nét 100%.
/// Vẽ trực tiếp vào Bitmap bằng Canvas, không phụ thuộc Widget tree.
class ArDashboardTextureGenerator {
  ArDashboardTextureGenerator._();

  static Future<Uint8List> generateDashboardImageBytes({
    required bool isLightOn,
    required bool isAcOn,
    required double temperature,
    required String timeString,
  }) async {
    const double width = 800;
    const double height = 500;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

    // 1. NỀN BẢNG DASHBOARD (Màu xanh đen sâu + Bo góc + Viền sáng Neon)
    final bgPaint = Paint()..color = const Color(0xFF0A0F1D);
    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 8, width - 16, height - 16),
      const Radius.circular(36),
    );
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);

    // 2. HEADER
    _drawText(
      canvas: canvas,
      text: 'JARVIS SPATIAL IOT DASHBOARD',
      x: 40,
      y: 40,
      fontSize: 28,
      color: const Color(0xFF00E5FF),
      isBold: true,
      letterSpacing: 1.5,
    );

    _drawText(
      canvas: canvas,
      text: 'TIME: $timeString  |  SLAM TRACKING: 6DoF ONLINE (PINNED)',
      x: 40,
      y: 80,
      fontSize: 16,
      color: Colors.white70,
    );

    // Đường gạch ngang phân cách
    final linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(40, 115), const Offset(width - 40, 115), linePaint);

    // 3. CÁC Ô BẢNG DỮ LIỆU (DATA TABLE CARDS)
    // Cột 1: ĐÈN PHÒNG KHÁCH
    _drawDataCard(
      canvas: canvas,
      rect: const Rect.fromLTWH(40, 135, 220, 150),
      title: 'ĐÈN PHÒNG KHÁCH',
      value: isLightOn ? 'ĐANG BẬT' : 'ĐÃ TẮT',
      subText: isLightOn ? '● 100% Brightness' : '○ Standby',
      valueColor: isLightOn ? const Color(0xFF00E5FF) : Colors.white38,
      borderColor: isLightOn ? const Color(0xFF00E5FF) : Colors.white24,
    );

    // Cột 2: ĐIỀU HÒA
    _drawDataCard(
      canvas: canvas,
      rect: const Rect.fromLTWH(290, 135, 220, 150),
      title: 'ĐIỀU HÒA',
      value: isAcOn ? '${temperature.toStringAsFixed(1)}°C' : 'OFF',
      subText: isAcOn ? '● Làm mát tự động' : '○ Tiết kiệm điện',
      valueColor: isAcOn ? Colors.amberAccent : Colors.white38,
      borderColor: isAcOn ? Colors.amberAccent : Colors.white24,
    );

    // Cột 3: SPATIAL ENGINE
    _drawDataCard(
      canvas: canvas,
      rect: const Rect.fromLTWH(540, 135, 220, 150),
      title: 'SPATIAL ENGINE',
      value: '60 FPS',
      subText: 'Pin: 92%  |  AI: Sẵn sàng',
      valueColor: Colors.greenAccent,
      borderColor: Colors.greenAccent.withValues(alpha: 0.5),
    );

    // 4. HÀNG DỮ LIỆU DƯỚI (DATA ROWS)
    _drawDataRow(
      canvas: canvas,
      y: 315,
      label: 'ĐỘ ẨM PHÒNG:',
      value: '58% RH (Mát mẻ lý tưởng)',
      valColor: Colors.white,
    );
    _drawDataRow(
      canvas: canvas,
      y: 355,
      label: 'CHẤT LƯỢNG KHÔNG KHÍ:',
      value: 'TỐT (AQI 22 - Không khí sạch)',
      valColor: Colors.greenAccent,
    );
    _drawDataRow(
      canvas: canvas,
      y: 395,
      label: 'TRẠNG THÁI VẬT THỂ:',
      value: 'Ghim cứng cố định trong phòng (Anchor 6DoF)',
      valColor: const Color(0xFF00E5FF),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static void _drawDataCard({
    required Canvas canvas,
    required Rect rect,
    required String title,
    required String value,
    required String subText,
    required Color valueColor,
    required Color borderColor,
  }) {
    final cardRRect = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    final bgCardPaint = Paint()..color = const Color(0xFF161F36);
    canvas.drawRRect(cardRRect, bgCardPaint);

    final borderCardPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(cardRRect, borderCardPaint);

    _drawText(
      canvas: canvas,
      text: title,
      x: rect.left + 16,
      y: rect.top + 18,
      fontSize: 13,
      color: Colors.white60,
      isBold: true,
    );

    _drawText(
      canvas: canvas,
      text: value,
      x: rect.left + 16,
      y: rect.top + 50,
      fontSize: 26,
      color: valueColor,
      isBold: true,
    );

    _drawText(
      canvas: canvas,
      text: subText,
      x: rect.left + 16,
      y: rect.top + 105,
      fontSize: 12,
      color: Colors.white54,
    );
  }

  static void _drawDataRow({
    required Canvas canvas,
    required double y,
    required String label,
    required String value,
    required Color valColor,
  }) {
    _drawText(
      canvas: canvas,
      text: label,
      x: 45,
      y: y,
      fontSize: 15,
      color: Colors.white54,
      isBold: true,
    );
    _drawText(
      canvas: canvas,
      text: value,
      x: 270,
      y: y,
      fontSize: 15,
      color: valColor,
      isBold: true,
    );
  }

  static void _drawText({
    required Canvas canvas,
    required String text,
    required double x,
    required double y,
    required double fontSize,
    required Color color,
    bool isBold = false,
    double letterSpacing = 0.0,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          letterSpacing: letterSpacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }
}
