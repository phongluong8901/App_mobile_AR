import 'dart:convert';

/// Model dữ liệu Lưu trữ Tọa độ và Góc xoay của Vật thể AR (Spatial Anchor).
/// Tương thích chuẩn cho cả SQLite nội bộ và PostgreSQL / Supabase / MongoDB Atlas.
class ArLocationModel {
  final String id;
  final String name;
  final int shapeIndex;
  final double posX;
  final double posY;
  final double posZ;
  final double rotX;
  final double rotY;
  final double rotZ;
  final double rotW;
  final double rotationAngleY;
  final String? customUrl; // URL ảnh 3D hoặc model 3D tùy chọn
  final DateTime createdAt;

  const ArLocationModel({
    required this.id,
    required this.name,
    required this.shapeIndex,
    required this.posX,
    required this.posY,
    required this.posZ,
    required this.rotX,
    required this.rotY,
    required this.rotZ,
    required this.rotW,
    required this.rotationAngleY,
    this.customUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'shape_index': shapeIndex,
      'pos_x': posX,
      'pos_y': posY,
      'pos_z': posZ,
      'rot_x': rotX,
      'rot_y': rotY,
      'rot_z': rotZ,
      'rot_w': rotW,
      'rotation_angle_y': rotationAngleY,
      'custom_url': customUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ArLocationModel.fromMap(Map<String, dynamic> map) {
    return ArLocationModel(
      id: map['id'] as String,
      name: map['name'] as String,
      shapeIndex: (map['shape_index'] as num).toInt(),
      posX: (map['pos_x'] as num).toDouble(),
      posY: (map['pos_y'] as num).toDouble(),
      posZ: (map['pos_z'] as num).toDouble(),
      rotX: (map['rot_x'] as num).toDouble(),
      rotY: (map['rot_y'] as num).toDouble(),
      rotZ: (map['rot_z'] as num).toDouble(),
      rotW: (map['rot_w'] as num).toDouble(),
      rotationAngleY: (map['rotation_angle_y'] as num).toDouble(),
      customUrl: map['custom_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory ArLocationModel.fromJson(String source) =>
      ArLocationModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
