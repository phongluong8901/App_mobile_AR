import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../data/models/book_3d_model.dart';

/// Bộ sinh ảnh Texture Hologram 3D sắc nét cho Cuốn Sách trong không gian AR thực tế.
/// Vẽ trực tiếp vào Bitmap bằng Canvas để dán lên ArCoreCube lơ lửng ngay trên cuốn sách thật.
class ArBookTextureGenerator {
  ArBookTextureGenerator._();

  static Future<Uint8List> generateBookInfoTexture(Book3dModel book) async {
    const double width = 800;
    const double height = 520;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

    // 1. NỀN THẺ HOLOGRAPHIC (Xanh đen sâu + Viền Cyberpunk)
    final bgPaint = Paint()..color = const Color(0xFF090E1D);
    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 8, width - 16, height - 16),
      const Radius.circular(32),
    );
    canvas.drawRRect(rrect, bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);

    // 2. HEADER: TIÊU ĐỀ SÁCH VÀ NHÃN AR
    _drawText(
      canvas: canvas,
      text: 'AR SURFACE TARGET • 6DoF ANCHOR',
      x: 36,
      y: 36,
      fontSize: 16,
      color: const Color(0xFF00E5FF),
      isBold: true,
      letterSpacing: 1.5,
    );

    _drawText(
      canvas: canvas,
      text: book.title.toUpperCase(),
      x: 36,
      y: 68,
      fontSize: 26,
      color: Colors.white,
      isBold: true,
      maxWidth: 720,
    );

    // Đường gạch ngang phân cách
    final linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(36, 120), const Offset(width - 36, 120), linePaint);

    // 3. THẺ THÔNG TIN TÁC GIẢ & THỂ LOẠI
    _drawText(
      canvas: canvas,
      text: 'TÁC GIẢ: ${book.author.toUpperCase()}',
      x: 36,
      y: 135,
      fontSize: 18,
      color: const Color(0xFF38BDF8),
      isBold: true,
    );

    _drawText(
      canvas: canvas,
      text: 'THỂ LOẠI: ${book.category}  |  NĂM: ${book.publishYear}  |  ĐÁNH GIÁ: ${book.rating}/5.0',
      x: 36,
      y: 170,
      fontSize: 15,
      color: Colors.white70,
    );

    // 4. KHUNG MÔ TẢ TÓM TẮT
    final descBgPaint = Paint()..color = const Color(0xFF131D33);
    final descRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(36, 210, width - 72, 180),
      const Radius.circular(18),
    );
    canvas.drawRRect(descRRect, descBgPaint);

    _drawText(
      canvas: canvas,
      text: 'TÓM TẮT NỘI DUNG VẬT THỂ 3D:',
      x: 54,
      y: 226,
      fontSize: 14,
      color: const Color(0xFF00E5FF),
      isBold: true,
    );

    _drawText(
      canvas: canvas,
      text: book.description,
      x: 54,
      y: 256,
      fontSize: 17,
      color: Colors.white,
      maxWidth: 690,
      maxLines: 4,
    );

    // 5. FOOTER TRẠNG THÁI GHI ĐÈ LÊN SÁCH THẬT
    _drawText(
      canvas: canvas,
      text: 'TRẠNG THÁI: GHI ĐÈ TRỰC TIẾP LÊN CUỐN SÁCH NGOÀI ĐỜI THỰC',
      x: 36,
      y: 420,
      fontSize: 14,
      color: Colors.greenAccent,
      isBold: true,
    );

    _drawText(
      canvas: canvas,
      text: 'KÍCH THƯỚC: ${book.dimensions}  •  SLAM TRACKING: KHÓA CHẶT 6DoF',
      x: 36,
      y: 450,
      fontSize: 13,
      color: Colors.white54,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
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
    double maxWidth = 740,
    int maxLines = 1,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          letterSpacing: letterSpacing,
          height: 1.35,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '...',
    );
    tp.layout(maxWidth: maxWidth);
    tp.paint(canvas, Offset(x, y));
  }
}

