import 'dart:convert';
import 'dart:io';
import '../models/ar_location_model.dart';

/// Dịch vụ lưu trữ Tọa độ Không gian AR (Persistent AR Anchor Storage).
/// Hoạt động 100% Offline & Free, không cần cấu hình phức tạp.
/// Cấu trúc dữ liệu chuẩn hóa, sẵn sàng mở rộng sang PostgreSQL (Supabase) hoặc MongoDB Atlas.
class ArLocationStorageService {
  ArLocationStorageService._();
  static final ArLocationStorageService instance = ArLocationStorageService._();

  // Bộ nhớ tạm thời trong phiên chạy
  final List<ArLocationModel> _cache = [];
  bool _isInitialized = false;

  File? _storageFile;

  Future<void> _init() async {
    if (_isInitialized) return;

    try {
      // Ưu tiên thư mục dữ liệu nội bộ của ứng dụng
      final appDir = Directory('/data/user/0/com.example.proj_1/files');
      if (await appDir.exists()) {
        _storageFile = File('${appDir.path}/ar_locations.json');
      } else {
        // Dự phòng thư mục hệ thống an toàn
        final fallbackDir = Directory.systemTemp;
        _storageFile = File('${fallbackDir.path}/ar_locations_proj1.json');
      }

      if (await _storageFile!.exists()) {
        final content = await _storageFile!.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> list = json.decode(content) as List<dynamic>;
          _cache.clear();
          for (final item in list) {
            _cache.add(ArLocationModel.fromMap(item as Map<String, dynamic>));
          }
        }
      }
    } catch (_) {
      // Bỏ qua lỗi I/O để app không crash
    } finally {
      _isInitialized = true;
    }
  }

  Future<void> _persist() async {
    try {
      if (_storageFile != null) {
        if (!await _storageFile!.parent.exists()) {
          await _storageFile!.parent.create(recursive: true);
        }
        final list = _cache.map((e) => e.toMap()).toList();
        await _storageFile!.writeAsString(json.encode(list), flush: true);
      }
    } catch (_) {}
  }

  /// Lấy toàn bộ danh sách tọa độ vật thể đã lưu
  Future<List<ArLocationModel>> getAllLocations() async {
    await _init();
    return List.unmodifiable(_cache);
  }

  /// Lưu một tọa độ vật thể AR mới vào bộ nhớ
  Future<void> saveLocation(ArLocationModel location) async {
    await _init();
    _cache.removeWhere((item) => item.id == location.id);
    _cache.insert(0, location);
    await _persist();
  }

  /// Xóa một tọa độ theo ID
  Future<void> deleteLocation(String id) async {
    await _init();
    _cache.removeWhere((item) => item.id == id);
    await _persist();
  }

  /// Xóa toàn bộ danh sách tọa độ
  Future<void> clearAllLocations() async {
    await _init();
    _cache.clear();
    await _persist();
  }
}

