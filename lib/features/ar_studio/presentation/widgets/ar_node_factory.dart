import 'dart:typed_data';
import 'package:arcore_flutter_plus/arcore_flutter_plus.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

/// Factory class chịu trách nhiệm khởi tạo các loại Node 3D cho ARCore.
/// Nhận trực tiếp [position] (Vector3) và [rotation] (Vector4) để đảm bảo tương thích tuyệt đối.
class ArNodeFactory {
  ArNodeFactory._();

  /// 1. Tạo node màn hình AR Hologram Dashboard lơ lửng từ Texture ảnh PNG
  static ArCoreNode createDashboardNode({
    required vector.Vector3 position,
    required vector.Vector4 rotation,
    required Uint8List textureBytes,
  }) {
    final material = ArCoreMaterial(
      textureBytes: textureBytes,
      roughness: 0.2,
      metallic: 0.1,
    );

    // Kích thước màn hình mỏng: Rộng 36cm x Cao 22cm x Dày 0.5cm
    final dashboardScreen = ArCoreCube(
      materials: [material],
      size: vector.Vector3(0.36, 0.22, 0.005),
    );

    return ArCoreNode(
      shape: dashboardScreen,
      position: position + vector.Vector3(0, 0.18, 0),
      rotation: rotation,
    );
  }

  /// 2. Tạo Quả cầu Bubble 3D Neon Cyan (Hologram Bubble)
  static ArCoreNode createBubbleNode({
    required vector.Vector3 position,
    required vector.Vector4 rotation,
  }) {
    final material = ArCoreMaterial(
      color: const Color(0xFF00E5FF),
      metallic: 0.8,
      roughness: 0.1,
    );
    final sphere = ArCoreSphere(
      materials: [material],
      radius: 0.14, // Bán kính 14cm
    );
    return ArCoreNode(
      shape: sphere,
      position: position + vector.Vector3(0, 0.14, 0),
      rotation: rotation,
    );
  }

  /// Alias tương thích cũ
  static ArCoreNode createChromeSphereNode({
    required vector.Vector3 position,
    required vector.Vector4 rotation,
  }) => createBubbleNode(position: position, rotation: rotation);

  /// 3. Tạo khối lập phương vàng Gold
  static ArCoreNode createGoldCubeNode({
    required vector.Vector3 position,
    required vector.Vector4 rotation,
  }) {
    final material = ArCoreMaterial(
      color: Colors.amber,
      metallic: 0.9,
      roughness: 0.2,
    );
    final cube = ArCoreCube(
      materials: [material],
      size: vector.Vector3(0.2, 0.2, 0.2), // 20cm mỗi cạnh
    );
    return ArCoreNode(
      shape: cube,
      position: position + vector.Vector3(0, 0.1, 0),
      rotation: rotation,
    );
  }

  /// 4. Tạo khối trụ Ruby đỏ
  static ArCoreNode createRubyCylinderNode({
    required vector.Vector3 position,
    required vector.Vector4 rotation,
  }) {
    final material = ArCoreMaterial(
      color: Colors.redAccent,
      metallic: 0.8,
      roughness: 0.3,
    );
    final cylinder = ArCoreCylinder(
      materials: [material],
      radius: 0.1,
      height: 0.25, // Cao 25cm
    );
    return ArCoreNode(
      shape: cylinder,
      position: position + vector.Vector3(0, 0.125, 0),
      rotation: rotation,
    );
  }

  /// 5. Tạo mô hình 3D Reference GLB (Phi hành gia)
  static ArCoreNode createAstronautReferenceNode({
    required vector.Vector3 position,
    required vector.Vector4 rotation,
  }) {
    return ArCoreReferenceNode(
      name: 'Astronaut_${DateTime.now().millisecondsSinceEpoch}',
      objectUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
      position: position,
      rotation: rotation,
      scale: vector.Vector3(0.25, 0.25, 0.25),
    );
  }
}

