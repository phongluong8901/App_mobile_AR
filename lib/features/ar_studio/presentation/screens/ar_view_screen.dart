import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arcore_flutter_plus/arcore_flutter_plus.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import '../widgets/ar_dashboard_texture_generator.dart';
import '../widgets/ar_instruction_banner.dart';
import '../widgets/ar_node_factory.dart';
import '../widgets/ar_selection_toolbar.dart';
import '../../../../core/utils/ar_launcher.dart';
import '../../data/models/ar_location_model.dart';
import '../../data/services/ar_location_storage_service.dart';

/// Class quản lý trạng thái của từng Vật thể AR đang hiển thị trên sàn
class PlacedArNode {
  final String id;
  final String name;
  final int shapeIndex;
  final vector.Vector3 position;
  double rotationAngleY; // Góc xoay quanh trục Y (radian)
  vector.Vector4 rotation;

  PlacedArNode({
    required this.id,
    required this.name,
    required this.shapeIndex,
    required this.position,
    required this.rotationAngleY,
    required this.rotation,
  });
}

/// Màn hình AR Native 6DoF (ARCore Space Studio - Tab 1).
/// Đã được nâng cấp:
/// 1. Tương tác trực tiếp: Chạm vào vật thể để Xoay (Trái/Phải 30°), Xóa hoặc Lưu Tọa độ.
/// 2. Lưu trữ Vị trí (Location Persistent Storage): Lưu vào CSDL nội bộ vĩnh viễn (sẵn sàng cho Supabase/PostgreSQL).
/// 3. Quản lý Vị trí đã lưu: Xem danh sách, Khôi phục lại ra sàn nhà hoặc Xóa.
class ArViewScreen extends StatefulWidget {
  const ArViewScreen({super.key});

  @override
  State<ArViewScreen> createState() => _ArViewScreenState();
}

class _ArViewScreenState extends State<ArViewScreen> {
  ArCoreController? _arCoreController;

  int _selectedShapeIndex = 0;

  static const List<String> _shapeNames = [
    '📊 Bảng Data 3D',
    '🤖 Nhân Vật 3D AR',
    '🔮 Quả cầu Bubble 3D',
    '🧊 Khối Gold 3D',
    '🔴 Trụ Ruby 3D',
  ];

  static const String nodeDashboardName = 'spatial_data_dashboard_screen';

  bool _isPlaneDetected = false;
  int _placedObjectsCount = 0;

  // Danh sách các vật thể đang hiển thị trong không gian AR thực
  final List<PlacedArNode> _placedNodes = [];
  PlacedArNode? _selectedNode; // Vật thể người dùng đang chạm chọn để xoay / xóa

  // Dữ liệu hiển thị trên Bảng Data
  bool _isLightOn = true;
  bool _isAcOn = true;
  final double _temperature = 24.5;
  vector.Vector3? _dashboardPosition;
  vector.Vector4? _dashboardRotation;

  // Đồng hồ thời gian thực
  late Timer _clockTimer;
  String _timeString = '12:00:00';

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
  }

  void _updateClock() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    if (mounted) {
      setState(() {
        _timeString = '$h:$m:$s';
      });
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _arCoreController?.dispose();
    super.dispose();
  }

  void _onArCoreViewCreated(ArCoreController controller) {
    _arCoreController = controller;

    _arCoreController?.onPlaneDetected = (ArCorePlane plane) {
      if (!_isPlaneDetected && mounted) {
        setState(() {
          _isPlaneDetected = true;
        });
      }
    };

    _arCoreController?.onPlaneTap = _handleOnPlaneTap;
    _arCoreController?.onNodeTap = _handleOnNodeTap;
  }

  /// Khi chạm vào vật thể AR trên sàn thực tế
  void _handleOnNodeTap(String nodeName) async {
    HapticFeedback.heavyImpact();

    // Tìm vật thể được chạm
    PlacedArNode? found;
    for (final node in _placedNodes) {
      if (node.id == nodeName) {
        found = node;
        break;
      }
    }

    if (found != null) {
      setState(() {
        _selectedNode = found;
      });
      _showSnack('🎯 Đã chọn [${found.name}]! Sử dụng thanh công cụ bên dưới để Xoay hoặc Xóa.');
    }

    // Nếu chạm vào Bảng Data thì đổi trạng thái Đèn
    if (nodeName == nodeDashboardName) {
      setState(() {
        _isLightOn = !_isLightOn;
      });
      await _refreshDashboardTexture();
    }
  }

  /// Cập nhật lại Bảng Data
  Future<void> _refreshDashboardTexture() async {
    if (_arCoreController == null || _dashboardPosition == null || _dashboardRotation == null) return;

    _arCoreController?.removeNode(nodeName: nodeDashboardName);

    final Uint8List textureBytes = await ArDashboardTextureGenerator.generateDashboardImageBytes(
      isLightOn: _isLightOn,
      isAcOn: _isAcOn,
      temperature: _temperature,
      timeString: _timeString,
    );

    final material = ArCoreMaterial(
      color: Colors.white,
      textureBytes: textureBytes,
      metallic: 0.1,
      roughness: 0.2,
    );

    final screenCube = ArCoreCube(
      materials: [material],
      size: vector.Vector3(0.42, 0.26, 0.01),
    );

    final node = ArCoreNode(
      name: nodeDashboardName,
      shape: screenCube,
      position: _dashboardPosition! + vector.Vector3(0, 0.22, 0),
      rotation: _dashboardRotation,
    );

    _arCoreController?.addArCoreNode(node);
  }

  void _handleOnPlaneTap(List<ArCoreHitTestResult> hits) async {
    if (hits.isEmpty) {
      _showSnack('⚠️ Chưa khóa được mặt phẳng! Hãy lia camera chậm đến khi banner chuyển màu xanh lá.');
      return;
    }

    final hit = hits.first;
    await _addNodeAtHitPosition(hit.pose.translation, hit.pose.rotation, _selectedShapeIndex);
  }

  /// Thêm vật thể vào không gian AR tại vị trí xác định
  Future<void> _addNodeAtHitPosition(
    vector.Vector3 position,
    vector.Vector4 rotation,
    int shapeIndex,
  ) async {
    if (_arCoreController == null) return;

    final String nodeId = 'ar_node_${DateTime.now().millisecondsSinceEpoch}_$shapeIndex';
    final String shapeName = _shapeNames[shapeIndex];

    if (shapeIndex == 0) {
      _dashboardPosition = position;
      _dashboardRotation = rotation;

      final Uint8List textureBytes = await ArDashboardTextureGenerator.generateDashboardImageBytes(
        isLightOn: _isLightOn,
        isAcOn: _isAcOn,
        temperature: _temperature,
        timeString: _timeString,
      );

      final material = ArCoreMaterial(
        color: Colors.white,
        textureBytes: textureBytes,
        metallic: 0.1,
        roughness: 0.2,
      );

      final screenCube = ArCoreCube(
        materials: [material],
        size: vector.Vector3(0.42, 0.26, 0.01),
      );

      final dashboardNode = ArCoreNode(
        name: nodeDashboardName,
        shape: screenCube,
        position: position + vector.Vector3(0, 0.22, 0),
        rotation: rotation,
      );

      _arCoreController?.addArCoreNodeWithAnchor(dashboardNode);

      final placed = PlacedArNode(
        id: nodeDashboardName,
        name: shapeName,
        shapeIndex: 0,
        position: position,
        rotationAngleY: 0,
        rotation: rotation,
      );
      _placedNodes.add(placed);

      setState(() {
        _placedObjectsCount = _placedNodes.length;
        _selectedNode = placed;
      });

      _showSnack('🎯 Đã ghim Bảng Data Dashboard lên mặt bàn! Chạm vào để Bật/Tắt đèn.');
      return;
    }

    final node = _createNodeInstance(nodeId, shapeIndex, position, rotation);
    _arCoreController?.addArCoreNodeWithAnchor(node);

    final placed = PlacedArNode(
      id: nodeId,
      name: shapeName,
      shapeIndex: shapeIndex,
      position: position,
      rotationAngleY: 0,
      rotation: rotation,
    );
    _placedNodes.add(placed);

    setState(() {
      _placedObjectsCount = _placedNodes.length;
      _selectedNode = placed;
    });

    if (shapeIndex == 1) {
      _showSnack('🤖 Đã ghim Nhân vật 3D lên sàn! Chạm vào nhân vật để Xoay hoặc Xóa.');
    } else {
      _showSnack('🎯 Đã ghim $shapeName vào sàn! Chạm vào để Xoay hoặc Xóa.');
    }
  }

  /// Khởi tạo instance Node AR dựa trên loại hình dạng
  ArCoreNode _createNodeInstance(
    String id,
    int shapeIndex,
    vector.Vector3 position,
    vector.Vector4 rotation,
  ) {
    switch (shapeIndex) {
      case 1:
        return ArCoreReferenceNode(
          name: id,
          objectUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
          position: position,
          rotation: rotation,
          scale: vector.Vector3(0.28, 0.28, 0.28),
        );
      case 2:
        return ArCoreNode(
          name: id,
          shape: ArCoreSphere(
            materials: [
              ArCoreMaterial(color: const Color(0xFF00E5FF), metallic: 0.8, roughness: 0.1),
            ],
            radius: 0.14,
          ),
          position: position + vector.Vector3(0, 0.14, 0),
          rotation: rotation,
        );
      case 3:
        return ArCoreNode(
          name: id,
          shape: ArCoreCube(
            materials: [
              ArCoreMaterial(color: Colors.amber, metallic: 0.9, roughness: 0.2),
            ],
            size: vector.Vector3(0.2, 0.2, 0.2),
          ),
          position: position + vector.Vector3(0, 0.1, 0),
          rotation: rotation,
        );
      case 4:
      default:
        return ArCoreNode(
          name: id,
          shape: ArCoreCylinder(
            materials: [
              ArCoreMaterial(color: Colors.redAccent, metallic: 0.8, roughness: 0.3),
            ],
            radius: 0.1,
            height: 0.25,
          ),
          position: position + vector.Vector3(0, 0.125, 0),
          rotation: rotation,
        );
    }
  }

  /// XOAY VẬT THỂ ĐÃ CHỌN QUANH TRỤC THẲNG ĐỨNG Y
  void _rotateSelectedNode(double deltaAngleRadians) {
    if (_selectedNode == null || _arCoreController == null) return;
    HapticFeedback.lightImpact();

    final node = _selectedNode!;
    node.rotationAngleY += deltaAngleRadians;

    // Tính toán lại Quaternion xoay quanh trục Y
    final q = vector.Quaternion.axisAngle(vector.Vector3(0, 1, 0), node.rotationAngleY);
    node.rotation = vector.Vector4(q.x, q.y, q.z, q.w);

    // Gỡ node cũ và đặt lại với góc xoay mới
    _arCoreController?.removeNode(nodeName: node.id);

    if (node.shapeIndex == 0) {
      _dashboardRotation = node.rotation;
      _refreshDashboardTexture();
    } else {
      final updatedNode = _createNodeInstance(node.id, node.shapeIndex, node.position, node.rotation);
      _arCoreController?.addArCoreNodeWithAnchor(updatedNode);
    }

    final deg = (node.rotationAngleY * 180 / math.pi).round() % 360;
    _showSnack('🔄 Đã xoay [${node.name}] sang góc $deg°');
  }

  /// XÓA MỘT VẬT THỂ ĐƯỢC CHỌN
  void _deleteSelectedNode() {
    if (_selectedNode == null || _arCoreController == null) return;
    HapticFeedback.heavyImpact();

    final node = _selectedNode!;
    _arCoreController?.removeNode(nodeName: node.id);
    _placedNodes.removeWhere((item) => item.id == node.id);

    setState(() {
      _selectedNode = null;
      _placedObjectsCount = _placedNodes.length;
    });

    _showSnack('🗑️ Đã xóa [${node.name}] khỏi không gian!');
  }

  /// LƯU TỌA ĐỘ VÀ GÓC XOAY CỦA VẬT THỂ VÀO CƠ SỞ DỮ LIỆU
  Future<void> _saveSelectedNodeLocation() async {
    if (_selectedNode == null) return;
    HapticFeedback.mediumImpact();

    final node = _selectedNode!;
    final location = ArLocationModel(
      id: node.id,
      name: node.name,
      shapeIndex: node.shapeIndex,
      posX: node.position.x,
      posY: node.position.y,
      posZ: node.position.z,
      rotX: node.rotation.x,
      rotY: node.rotation.y,
      rotZ: node.rotation.z,
      rotW: node.rotation.w,
      rotationAngleY: node.rotationAngleY,
      createdAt: DateTime.now(),
    );

    await ArLocationStorageService.instance.saveLocation(location);

    _showSnack(
      '💾 Đã lưu tọa độ [X: ${node.position.x.toStringAsFixed(2)}, Y: ${node.position.y.toStringAsFixed(2)}, Z: ${node.position.z.toStringAsFixed(2)}] vào CSDL!',
    );
  }

  /// MỞ BOTTOM SHEET XEM VÀ QUẢN LÝ CÁC VỊ TRÍ AR ĐÃ LƯU
  void _openSavedLocationsBottomSheet() async {
    final locations = await ArLocationStorageService.instance.getAllLocations();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bookmarks, color: Color(0xFF00E5FF), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'TỌA ĐỘ VỊ TRÍ AR ĐÃ LƯU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      if (locations.isNotEmpty)
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                          icon: const Icon(Icons.delete_sweep, size: 18),
                          label: const Text('Xóa hết', style: TextStyle(fontSize: 11)),
                          onPressed: () async {
                            await ArLocationStorageService.instance.clearAllLocations();
                            setModalState(() {
                              locations.clear();
                            });
                            _showSnack('🧹 Đã xóa toàn bộ dữ liệu vị trí AR đã lưu!');
                          },
                        ),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  if (locations.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: Text(
                          'Chưa có tọa độ nào được lưu.\nHãy ghim vật thể ra sàn, chạm vào vật thể rồi bấm [💾 Lưu Vị Trí]!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: locations.length,
                        itemBuilder: (ctx, i) {
                          final item = locations[i];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: Color(0xFF00E5FF), size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'X: ${item.posX.toStringAsFixed(2)}m  •  Y: ${item.posY.toStringAsFixed(2)}m  •  Z: ${item.posZ.toStringAsFixed(2)}m',
                                        style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11),
                                      ),
                                      Text(
                                        'Ngày ghim: ${item.createdAt.hour}:${item.createdAt.minute} - ${item.createdAt.day}/${item.createdAt.month}',
                                        style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.replay_circle_filled, color: Colors.greenAccent),
                                  tooltip: 'Khôi phục ra sàn AR',
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await _addNodeAtHitPosition(
                                      vector.Vector3(item.posX, item.posY, item.posZ),
                                      vector.Vector4(item.rotX, item.rotY, item.rotZ, item.rotW),
                                      item.shapeIndex,
                                    );
                                    _showSnack('✨ Đã khôi phục [${item.name}] từ CSDL ra sàn AR!');
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  tooltip: 'Xóa khỏi CSDL',
                                  onPressed: () async {
                                    await ArLocationStorageService.instance.deleteLocation(item.id);
                                    setModalState(() {
                                      locations.removeAt(i);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.black87,
        duration: const Duration(milliseconds: 2500),
      ),
    );
  }

  Key _arKey = UniqueKey();

  void _clearAllNodes() {
    _arCoreController?.removeNode(nodeName: nodeDashboardName);
    for (final node in _placedNodes) {
      _arCoreController?.removeNode(nodeName: node.id);
    }
    setState(() {
      _placedNodes.clear();
      _selectedNode = null;
      _placedObjectsCount = 0;
      _isPlaneDetected = false;
      _dashboardPosition = null;
      _arKey = UniqueKey();
    });
    _showSnack('🧹 Đã xóa toàn bộ đối tượng AR trong không gian!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR 6DoF Space Studio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          // NÚT XEM DANH SÁCH TỌA ĐỘ ĐÃ LƯU
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined, color: Color(0xFF00E5FF)),
            tooltip: 'Danh sách vị trí AR đã lưu (CSDL)',
            onPressed: _openSavedLocationsBottomSheet,
          ),
          // NÚT MỞ GOOGLE AR SCENE VIEWER
          IconButton(
            icon: const Icon(Icons.view_in_ar, color: Color(0xFF00E5FF)),
            tooltip: 'Chiếu Nhân vật 3D ra sàn ngoài đời thực (Google AR 6DoF)',
            onPressed: () {
              ArLauncher.launchAr(
                context: context,
                modelUrl: 'https://raw.githubusercontent.com/mrdoob/three.js/master/examples/models/gltf/RobotExpressive/RobotExpressive.glb',
                title: 'Robot Expressive (AR 3D)',
              );
            },
          ),
          if (_placedObjectsCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Xóa toàn bộ đối tượng AR',
              onPressed: _clearAllNodes,
            ),
        ],
      ),
      body: Stack(
        children: [
          ArCoreView(
            key: _arKey,
            onArCoreViewCreated: _onArCoreViewCreated,
            enablePlaneRenderer: true,
            enableTapRecognizer: true,
            enableUpdateListener: true,
          ),

          // BANNER HƯỚNG DẪN TRÊN CÙNG
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: ArInstructionBanner(
              placedCount: _placedObjectsCount,
              isPlaneDetected: _isPlaneDetected,
            ),
          ),

          // THANH ĐIỀU KHIỂN VẬT THỂ KHI ĐƯỢC CHỌN (XOAY / XÓA / LƯU VỊ TRÍ)
          if (_selectedNode != null)
            Positioned(
              bottom: 96,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xF20A0F1D),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x6600E5FF), blurRadius: 16),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.touch_app, color: Color(0xFF00E5FF), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'ĐANG CHỌN: ${_selectedNode!.name.toUpperCase()}',
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _selectedNode = null),
                          child: const Icon(Icons.close, color: Colors.white60, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // XOAY TRÁI -30 ĐỘ
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white12,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.rotate_left, size: 18, color: Color(0xFF00E5FF)),
                          label: const Text('Xoay -30°', style: TextStyle(fontSize: 11)),
                          onPressed: () => _rotateSelectedNode(-math.pi / 6),
                        ),
                        // XOAY PHẢI +30 ĐỘ
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white12,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.rotate_right, size: 18, color: Color(0xFF00E5FF)),
                          label: const Text('Xoay +30°', style: TextStyle(fontSize: 11)),
                          onPressed: () => _rotateSelectedNode(math.pi / 6),
                        ),
                        // LƯU VỊ TRÍ VÀO CSDL
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
                            foregroundColor: const Color(0xFF00E5FF),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFF00E5FF)),
                            ),
                          ),
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Lưu Vị Trí', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: _saveSelectedNodeLocation,
                        ),
                        // XÓA VẬT THỂ NÀY
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.redAccent.withValues(alpha: 0.25),
                            foregroundColor: Colors.redAccent,
                          ),
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip: 'Xóa vật thể này',
                          onPressed: _deleteSelectedNode,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // THANH CÔNG CỤ CHỌN VẬT THỂ ĐỂ GHIM
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ArSelectionToolbar(
              shapeNames: _shapeNames,
              selectedIndex: _selectedShapeIndex,
              onSelect: (index) {
                setState(() {
                  _selectedShapeIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
