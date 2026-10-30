import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Lớp đại diện cho dữ liệu mỏ neo AR (Spatial Anchor).
/// Chứa thông tin về vị trí và tỷ lệ thu phóng của vật thể 3D trong không gian.
class AnchorData {
  final double x;          // Tọa độ trục hoành
  final double y;          // Tọa độ trục tung
  final double scale;      // Tỷ lệ kích thước của vật thể
  final int modelIndex;    // Chỉ số mô hình 3D tương ứng trong danh sách lựa chọn

  const AnchorData({
    required this.x,
    required this.y,
    required this.scale,
    required this.modelIndex,
  });

  /// Chuyển đối tượng thành cấu trúc Map để serialize thành chuỗi JSON
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'scale': scale,
        'modelIndex': modelIndex,
      };

  /// Khởi tạo đối tượng từ dữ liệu JSON đã giải mã
  factory AnchorData.fromJson(Map<String, dynamic> json) => AnchorData(
        x: (json['x'] as num?)?.toDouble() ?? 0.0,
        y: (json['y'] as num?)?.toDouble() ?? 0.0,
        scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
        modelIndex: (json['modelIndex'] as int?) ?? 0,
      );
}

/// Lớp tiện ích lưu trữ vị trí mỏ neo AR xuống bộ nhớ cục bộ (Local Storage).
/// Được thiết kế thuần Dart (không phụ thuộc shared_preferences) nhằm đảm bảo
/// tương thích hoàn toàn với Flutter 3.47+ và loại bỏ lỗi liên kết Android v1 embedding.
class AnchorStorage {
  AnchorStorage._(); // Khóa constructor để không tạo instance

  // Bộ nhớ đệm tạm thời (In-memory Cache) giúp truy xuất nhanh mà không cần đọc lại ổ đĩa
  static AnchorData? _memoryCache;

  /// Xác định đường dẫn file lưu trữ riêng tư của ứng dụng trên Android
  static File? _resolveStorageFile() {
    try {
      if (Platform.isAndroid) {
        const paths = [
          '/data/user/0/com.example.proj_1/files',
          '/data/data/com.example.proj_1/files',
        ];
        for (final p in paths) {
          final dir = Directory(p);
          if (dir.existsSync()) {
            return File('${dir.path}/ar_anchor.json');
          }
        }
        // Nếu thư mục chưa tồn tại thì tạo mới
        final fallbackDir = Directory(paths.first);
        fallbackDir.createSync(recursive: true);
        return File('${fallbackDir.path}/ar_anchor.json');
      }
    } catch (e) {
      debugPrint('AnchorStorage resolve error: $e');
    }
    return null;
  }

  /// Đọc dữ liệu tọa độ đã lưu từ file JSON hoặc memory cache
  static Future<AnchorData?> load() async {
    // Ưu tiên trả về ngay từ RAM nếu đã có
    if (_memoryCache != null) return _memoryCache;

    try {
      final file = _resolveStorageFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _memoryCache = AnchorData.fromJson(json);
        return _memoryCache;
      }
    } catch (e) {
      debugPrint('AnchorStorage load error: $e');
    }
    return null;
  }

  /// Ghi đè tọa độ mới xuống file JSON và đồng bộ bộ nhớ RAM
  static Future<void> save({
    required double x,
    required double y,
    required double scale,
    required int modelIndex,
  }) async {
    final data = AnchorData(
      x: x,
      y: y,
      scale: scale,
      modelIndex: modelIndex,
    );
    _memoryCache = data;

    try {
      final file = _resolveStorageFile();
      if (file != null) {
        await file.writeAsString(jsonEncode(data.toJson()));
      }
    } catch (e) {
      debugPrint('AnchorStorage save error: $e');
    }
  }

  /// Xóa dữ liệu mỏ neo đã lưu
  static Future<void> clear() async {
    _memoryCache = null;
    try {
      final file = _resolveStorageFile();
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('AnchorStorage clear error: $e');
    }
  }
}
