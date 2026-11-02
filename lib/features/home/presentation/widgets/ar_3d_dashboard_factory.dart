import 'package:arcore_flutter_plus/arcore_flutter_plus.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

/// Factory dựng BẢNG DASHBOARD 3D THẬT 100% trong không gian ARCore.
///
/// Bảng điều khiển gồm:
/// 1. Tấm Panel nền 3D đen mỏng dựng đứng (Backboard).
/// 2. Nút Bật/Tắt ĐÈN (Khối Trụ 3D phát sáng màu Cyan nổi trên bảng).
/// 3. Nút Bật/Tắt ĐIỀU HÒA (Khối Trụ 3D phát sáng màu Vàng Gold nổi bên cạnh).
/// 4. Đèn báo trạng thái nguồn LED (Quả cầu phát sáng xanh lá).
class Ar3dDashboardFactory {
  Ar3dDashboardFactory._();

  static const String nodeBackboard = 'db_backboard';
  static const String nodeBtnLight = 'db_btn_light';
  static const String nodeBtnAc = 'db_btn_ac';
  static const String nodeLedStatus = 'db_led_status';

  /// Dựng trọn bộ Trạm Dashboard 3D gồm Bảng nền + Các nút bấm 3D
  static List<ArCoreNode> create3dDashboardStation({
    required vector.Vector3 origin,
    required vector.Vector4 rotation,
    required bool isLightOn,
    required bool isAcOn,
  }) {
    // 1. TẤM BẢNG ĐIỀU KHIỂN NỀN 3D (Đứng lơ lửng, Rộng 40cm, Cao 26cm, Dày 1.5cm)
    final backboardMaterial = ArCoreMaterial(
      color: const Color(0xFF101828), // Màu xanh đen kim loại
      metallic: 0.8,
      roughness: 0.2,
    );
    final backboardCube = ArCoreCube(
      materials: [backboardMaterial],
      size: vector.Vector3(0.40, 0.26, 0.015),
    );
    final backboardNode = ArCoreNode(
      name: nodeBackboard,
      shape: backboardCube,
      position: origin + vector.Vector3(0, 0.20, 0), // Lơ lửng cách sàn 20cm
      rotation: rotation,
    );

    // 2. NÚT BẤM 3D SỐ 1: BẬT/TẮT ĐÈN (Hình Trụ 3D nổi ra phía trước bảng)
    final lightBtnMaterial = ArCoreMaterial(
      color: isLightOn ? const Color(0xFF00E5FF) : const Color(0xFF334155),
      metallic: 0.9,
      roughness: 0.1,
    );
    final lightBtnCylinder = ArCoreCylinder(
      materials: [lightBtnMaterial],
      radius: 0.045, // Bán kính nút 4.5cm
      height: 0.03,  // Độ lồi nút 3cm
    );
    final lightBtnNode = ArCoreNode(
      name: nodeBtnLight,
      shape: lightBtnCylinder,
      // Nằm ở bên trái của bảng, nhô về phía trước (+Z)
      position: origin + vector.Vector3(-0.11, 0.20, 0.02),
      rotation: rotation,
    );

    // 3. NÚT BẤM 3D SỐ 2: BẬT/TẮT ĐIỀU HÒA (Hình Trụ 3D)
    final acBtnMaterial = ArCoreMaterial(
      color: isAcOn ? Colors.amberAccent : const Color(0xFF334155),
      metallic: 0.9,
      roughness: 0.1,
    );
    final acBtnCylinder = ArCoreCylinder(
      materials: [acBtnMaterial],
      radius: 0.045,
      height: 0.03,
    );
    final acBtnNode = ArCoreNode(
      name: nodeBtnAc,
      shape: acBtnCylinder,
      // Nằm ở bên phải của bảng
      position: origin + vector.Vector3(0.11, 0.20, 0.02),
      rotation: rotation,
    );

    // 4. ĐÈN BÁO NGUỒN LED (Quả cầu phát sáng đỉnh bảng)
    final ledMaterial = ArCoreMaterial(
      color: Colors.greenAccent,
      metallic: 0.5,
      roughness: 0.1,
    );
    final ledSphere = ArCoreSphere(
      materials: [ledMaterial],
      radius: 0.018, // 1.8cm
    );
    final ledNode = ArCoreNode(
      name: nodeLedStatus,
      shape: ledSphere,
      position: origin + vector.Vector3(0, 0.31, 0.02),
      rotation: rotation,
    );

    return [backboardNode, lightBtnNode, acBtnNode, ledNode];
  }
}

