import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arcore_flutter_plus/arcore_flutter_plus.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import '../widgets/ar_dashboard_texture_generator.dart';
import '../widgets/ar_instruction_banner.dart';
import '../widgets/ar_selection_toolbar.dart';
import '../../../../core/utils/ar_launcher.dart';
import '../../data/models/ar_location_model.dart';
import '../../data/services/ar_location_storage_service.dart';
import 'package:proj_1/features/character_3d/data/selected_fighter_service.dart';

/// Quản lý từng vật thể AR đang ghim trong không gian thực
class PlacedArNode {
  final String id;
  final String name;
  final int shapeIndex;
  final vector.Vector3 position;
  double rotationAngleY;
  vector.Vector4 rotation;
  double scale;
  Uint8List? textureBytes; // Dành cho Khung tranh 3D hoặc Dashboard
  String? customUrl;

  PlacedArNode({
    required this.id,
    required this.name,
    required this.shapeIndex,
    required this.position,
    required this.rotationAngleY,
    required this.rotation,
    this.scale = 1.0,
    this.textureBytes,
    this.customUrl,
  });
}

/// Màn hình AR Native 6DoF (ARCore Space Studio - Tab 1).
/// Đầy đủ tính năng:
/// 1. Ghim Bảng Data 3D thời gian thực.
/// 2. Ghim Nhân vật 3D ngoài đời thực.
/// 3. Ghim Khung Tranh / Ảnh 3D từ bất kỳ URL ảnh nào trên mạng.
/// 4. Chạm vào vật thể để Xoay (Trái/Phải 30°), Xóa, hoặc Lưu Tọa độ vào CSDL.
/// 5. Danh sách Tọa độ đã lưu (Persistent Storage): Khôi phục ra sàn hoặc Xóa.
class ArViewScreen extends StatefulWidget {
  const ArViewScreen({super.key});

  @override
  State<ArViewScreen> createState() => ArViewScreenState();
}

class ArViewScreenState extends State<ArViewScreen> {
  ArCoreController? _arCoreController;

  int _selectedShapeIndex = 0;

  void selectShape(int index) {
    if (index >= 0 && index < _shapeNames.length) {
      setState(() {
        _selectedShapeIndex = index;
      });
      _showSnack('Đã kích hoạt chế độ: [${_shapeNames[index]}]. Hãy lia camera vào sách/bàn và chạm để chiếu 3D ghi đè!');
    }
  }

  List<String> get _shapeNames => [
    'Bảng Data Hologram',
    '${SelectedFighterService.instance.currentFighter.name} 3D',
    'Khung Tranh Kỹ Thuật Số',
    'Bản Đồ Barcelona 3D Pop-Up',
    'IKEA Showroom 3D Ghi Đè',
    'Cuốn Sách AR 3D Mở',
    'Quả Cầu Plasma Cyan',
    'Khối Lập Phương Gold',
    'Trụ Năng Lượng Ruby',
    'Drone Bay Trinh Sát 3D',
  ];

  static const String nodeDashboardName = 'spatial_data_dashboard_screen';

  // URL ảnh 3D mặc định (Nghệ thuật số chất lượng cao)
  String _customImageUrl = 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=600';
  Uint8List? _cachedImageBytes;

  bool _isPlaneDetected = false;
  int _placedObjectsCount = 0;

  final List<PlacedArNode> _placedNodes = [];
  PlacedArNode? _selectedNode;

  // Dữ liệu Bảng Data
  bool _isLightOn = true;
  bool _isAcOn = true;
  final double _temperature = 24.5;
  vector.Vector3? _dashboardPosition;
  vector.Vector4? _dashboardRotation;

  late Timer _clockTimer;
  String _timeString = '12:00:00';

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    _preloadDefaultImageBytes();
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

  /// Tải trước ảnh từ URL để ghim ra AR tức thì
  Future<void> _preloadDefaultImageBytes() async {
    _cachedImageBytes = await _fetchImageBytes(_customImageUrl);
  }

  /// Tải dữ liệu byte của ảnh từ bất kỳ đường link URL nào
  Future<Uint8List?> _fetchImageBytes(String url) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
        return Uint8List.fromList(bytes);
      }
    } catch (_) {}
    return null;
  }

  /// Tạo texture dự phòng cho Khung ảnh 3D nếu offline hoặc lỗi mạng
  Future<Uint8List> _generateFallbackImageBytes() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 600, 400));
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF00E5FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(0, 0, 600, 400));

    canvas.drawRect(const Rect.fromLTWH(0, 0, 600, 400), paint);

    final borderPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawRect(const Rect.fromLTWH(10, 10, 580, 380), borderPaint);

    final tp = TextPainter(
      text: const TextSpan(
        text: '3D AR PHOTO FRAME\n(Cyber Hologram Art)',
        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: 560);
    tp.paint(canvas, const Offset(60, 160));

    final picture = recorder.endRecording();
    final img = await picture.toImage(600, 400);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _arCoreController = null;
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

  void _handleOnNodeTap(String nodeName) async {
    HapticFeedback.heavyImpact();

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
      _showSnack('[CHỌN] Đã chọn đối tượng [${found.name}]. Bạn có thể Phóng to, Xoay hoặc Xóa.');
    }

    if (nodeName == nodeDashboardName) {
      setState(() {
        _isLightOn = !_isLightOn;
      });
      await _refreshDashboardTexture();
    }
  }

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

    final currentScale = _selectedNode?.id == nodeDashboardName ? _selectedNode!.scale : 1.0;

    final screenCube = ArCoreCube(
      materials: [material],
      size: vector.Vector3(0.42 * currentScale, 0.26 * currentScale, 0.01 * currentScale),
    );

    final node = ArCoreNode(
      name: nodeDashboardName,
      shape: screenCube,
      position: _dashboardPosition! + vector.Vector3(0, 0.22 * currentScale, 0),
      rotation: _dashboardRotation,
    );

    _arCoreController?.addArCoreNode(node);
  }

  void _handleOnPlaneTap(List<ArCoreHitTestResult> hits) async {
    if (hits.isEmpty) {
      _showSnack('Chưa khóa được mặt phẳng. Hãy lia camera chậm để khóa không gian AR.');
      return;
    }

    final hit = hits.first;
    await _addNodeAtHitPosition(hit.pose.translation, hit.pose.rotation, _selectedShapeIndex);
  }

  Future<void> _addNodeAtHitPosition(
    vector.Vector3 position,
    vector.Vector4 rotation,
    int shapeIndex, {
    String? customUrl,
    Uint8List? preloadedBytes,
    double initialScale = 1.0,
  }) async {
    if (_arCoreController == null) return;

    final String nodeId = 'ar_node_${DateTime.now().millisecondsSinceEpoch}_$shapeIndex';
    final String shapeName = _shapeNames[shapeIndex];

    // 1. GHIM BẢNG DATA
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
        size: vector.Vector3(0.42 * initialScale, 0.26 * initialScale, 0.01 * initialScale),
      );

      final dashboardNode = ArCoreNode(
        name: nodeDashboardName,
        shape: screenCube,
        position: position + vector.Vector3(0, 0.22 * initialScale, 0),
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
        scale: initialScale,
        textureBytes: textureBytes,
      );
      _placedNodes.add(placed);

      setState(() {
        _placedObjectsCount = _placedNodes.length;
        _selectedNode = placed;
      });

      _showSnack('Đã ghim Bảng Data Hologram. Chạm vào bảng để Bật/Tắt đèn.');
      return;
    }

    // 2. GHIM KHUNG TRANH / ẢNH 3D TỪ BẤT KỲ URL NÀO
    if (shapeIndex == 2) {
      Uint8List? imageBytes = preloadedBytes ?? _cachedImageBytes;
      final targetUrl = customUrl ?? _customImageUrl;

      if (imageBytes == null) {
        _showSnack('Đang tải ảnh từ URL...');
        imageBytes = await _fetchImageBytes(targetUrl);
        imageBytes ??= await _generateFallbackImageBytes();
        _cachedImageBytes = imageBytes;
      }

      final material = ArCoreMaterial(
        color: Colors.white,
        textureBytes: imageBytes,
        metallic: 0.1,
        roughness: 0.35,
      );

      // Khung tranh 3D: Rộng 44cm x Cao 30cm x Dày 1.8cm
      final pictureFrame = ArCoreCube(
        materials: [material],
        size: vector.Vector3(0.44 * initialScale, 0.30 * initialScale, 0.018 * initialScale),
      );

      final pictureNode = ArCoreNode(
        name: nodeId,
        shape: pictureFrame,
        position: position + vector.Vector3(0, 0.18 * initialScale, 0),
        rotation: rotation,
      );

      _arCoreController?.addArCoreNodeWithAnchor(pictureNode);

      final placed = PlacedArNode(
        id: nodeId,
        name: 'Tranh Kỹ Thuật Số',
        shapeIndex: 2,
        position: position,
        rotationAngleY: 0,
        rotation: rotation,
        scale: initialScale,
        textureBytes: imageBytes,
        customUrl: targetUrl,
      );
      _placedNodes.add(placed);

      setState(() {
        _placedObjectsCount = _placedNodes.length;
        _selectedNode = placed;
      });

      _showSnack('Đã ghim Khung Tranh Kỹ Thuật Số vào không gian.');
      return;
    }

    // 3. CÁC HÌNH KHÁC (NHÂN VẬT 3D, QUẢ CẦU, KHỐI VÀNG, TRỤ RUBY, LĂNG KÍNH, SÁCH 3D, EMERALD, DRONE)
    final node = _createNodeInstance(nodeId, shapeIndex, position, rotation, scale: initialScale);
    _arCoreController?.addArCoreNodeWithAnchor(node);

    final placed = PlacedArNode(
      id: nodeId,
      name: shapeName,
      shapeIndex: shapeIndex,
      position: position,
      rotationAngleY: 0,
      rotation: rotation,
      scale: initialScale,
    );
    _placedNodes.add(placed);

    setState(() {
      _placedObjectsCount = _placedNodes.length;
      _selectedNode = placed;
    });

    _showSnack('Đã ghim [$shapeName] vào không gian AR.');
  }

  ArCoreNode _createNodeInstance(
    String id,
    int shapeIndex,
    vector.Vector3 position,
    vector.Vector4 rotation, {
    double scale = 1.0,
    Uint8List? textureBytes,
  }) {
    switch (shapeIndex) {
      case 1:
        final fighter = SelectedFighterService.instance.currentFighter;
        return ArCoreReferenceNode(
          name: id,
          objectUrl: fighter.modelUrl,
          position: position,
          rotation: rotation,
          scale: vector.Vector3(0.28 * scale, 0.28 * scale, 0.28 * scale),
        );
      case 2:
        return ArCoreNode(
          name: id,
          shape: ArCoreCube(
            materials: [
              ArCoreMaterial(color: Colors.white, textureBytes: textureBytes, metallic: 0.1, roughness: 0.35),
            ],
            size: vector.Vector3(0.44 * scale, 0.30 * scale, 0.018 * scale),
          ),
          position: position + vector.Vector3(0, 0.18 * scale, 0),
          rotation: rotation,
        );
      case 3:
        // Bản Đồ Barcelona 3D Pop-Up (Chiếu mọc thẳng đứng trên trang sách/bản đồ)
        return ArCoreReferenceNode(
          name: id,
          objectUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
          position: position + vector.Vector3(0, 0.18 * scale, 0),
          rotation: rotation,
          scale: vector.Vector3(0.28 * scale, 0.28 * scale, 0.28 * scale),
        );
      case 4:
        // IKEA Showroom 3D Ghi Đè (Ghế thư giãn Sheen Chair 1:1)
        return ArCoreReferenceNode(
          name: id,
          objectUrl: 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/SheenChair/glTF-Binary/SheenChair.glb',
          position: position,
          rotation: rotation,
          scale: vector.Vector3(0.35 * scale, 0.35 * scale, 0.35 * scale),
        );
      case 5:
        // Cuốn Sách AR 3D Mở
        return ArCoreNode(
          name: id,
          shape: ArCoreCube(
            materials: [
              ArCoreMaterial(color: const Color(0xFFF8FAFC), metallic: 0.1, roughness: 0.7),
            ],
            size: vector.Vector3(0.32 * scale, 0.04 * scale, 0.24 * scale),
          ),
          position: position + vector.Vector3(0, 0.02 * scale, 0),
          rotation: rotation,
        );
      case 6:
        // Quả Cầu Plasma Cyan
        return ArCoreNode(
          name: id,
          shape: ArCoreSphere(
            materials: [
              ArCoreMaterial(color: const Color(0xFF00E5FF), metallic: 0.85, roughness: 0.1),
            ],
            radius: 0.14 * scale,
          ),
          position: position + vector.Vector3(0, 0.14 * scale, 0),
          rotation: rotation,
        );
      case 7:
        // Khối Lập Phương Gold
        return ArCoreNode(
          name: id,
          shape: ArCoreCube(
            materials: [
              ArCoreMaterial(color: Colors.amber, metallic: 0.9, roughness: 0.2),
            ],
            size: vector.Vector3(0.2 * scale, 0.2 * scale, 0.2 * scale),
          ),
          position: position + vector.Vector3(0, 0.1 * scale, 0),
          rotation: rotation,
        );
      case 8:
        // Trụ Năng Lượng Ruby
        return ArCoreNode(
          name: id,
          shape: ArCoreCylinder(
            materials: [
              ArCoreMaterial(color: Colors.redAccent, metallic: 0.8, roughness: 0.3),
            ],
            radius: 0.1 * scale,
            height: 0.25 * scale,
          ),
          position: position + vector.Vector3(0, 0.125 * scale, 0),
          rotation: rotation,
        );
      case 9:
      default:
        // Drone Bay Trinh Sát 3D
        return ArCoreReferenceNode(
          name: id,
          objectUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
          position: position + vector.Vector3(0, 0.25 * scale, 0),
          rotation: rotation,
          scale: vector.Vector3(0.32 * scale, 0.32 * scale, 0.32 * scale),
        );
    }
  }

  void _rotateSelectedNode(double deltaAngleRadians) {
    if (_selectedNode == null || _arCoreController == null) return;
    HapticFeedback.lightImpact();

    final node = _selectedNode!;
    node.rotationAngleY += deltaAngleRadians;

    final q = vector.Quaternion.axisAngle(vector.Vector3(0, 1, 0), node.rotationAngleY);
    node.rotation = vector.Vector4(q.x, q.y, q.z, q.w);

    _arCoreController?.removeNode(nodeName: node.id);

    if (node.shapeIndex == 0) {
      _dashboardRotation = node.rotation;
      _refreshDashboardTexture();
    } else {
      final updatedNode = _createNodeInstance(
        node.id,
        node.shapeIndex,
        node.position,
        node.rotation,
        scale: node.scale,
        textureBytes: node.textureBytes,
      );
      _arCoreController?.addArCoreNodeWithAnchor(updatedNode);
    }

    final deg = (node.rotationAngleY * 180 / math.pi).round() % 360;
    _showSnack('Đã xoay [${node.name}] sang góc $deg°');
  }

  /// PHÓNG TO / THU NHỎ VẬT THỂ 3D ĐƯỢC CHỌN (TĂNG/GIẢM THEO TỈ LỆ)
  void _scaleSelectedNode(double factor) {
    if (_selectedNode == null || _arCoreController == null) return;
    HapticFeedback.selectionClick();

    final node = _selectedNode!;
    final newScale = (node.scale * factor).clamp(0.25, 4.0);
    node.scale = newScale;

    _arCoreController?.removeNode(nodeName: node.id);

    if (node.shapeIndex == 0) {
      _refreshDashboardTexture();
    } else {
      final updatedNode = _createNodeInstance(
        node.id,
        node.shapeIndex,
        node.position,
        node.rotation,
        scale: node.scale,
        textureBytes: node.textureBytes,
      );
      _arCoreController?.addArCoreNodeWithAnchor(updatedNode);
    }

    final percent = (node.scale * 100).round();
    _showSnack('Kích thước [${node.name}]: $percent%');
    setState(() {});
  }

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

    _showSnack('Đã xóa [${node.name}] khỏi không gian.');
  }

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
      scale: node.scale,
      customUrl: node.customUrl,
      createdAt: DateTime.now(),
    );

    await ArLocationStorageService.instance.saveLocation(location);

    _showSnack(
      'Đã lưu tọa độ và tỉ lệ ${(node.scale * 100).round()}% vào CSDL.',
    );
  }

  /// HỘP THOẠI ĐỔI ĐƯỜNG LINK ẢNH 3D TÙY Ý TỪ INTERNET
  void _openChangeImageUrlDialog() {
    final controller = TextEditingController(text: _customImageUrl);

    final sampleUrls = [
      {'name': 'Hội Họa', 'url': 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=600'},
      {'name': 'Không Gian Vũ Trụ', 'url': 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600'},
      {'name': 'Thành Phố Cyberpunk', 'url': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600'},
      {'name': 'Phong Cảnh Thiên Nhiên', 'url': 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600'},
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_photo_alternate, color: Color(0xFF00E5FF)),
              SizedBox(width: 8),
              Text('Đổi Link Ảnh 3D URL', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dán bất kỳ link ảnh (.jpg, .png, .webp) trên mạng để chiếu thành Khung tranh 3D lơ lửng trong phòng:',
                style: TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'https://...',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.black45,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.link, color: Color(0xFF00E5FF), size: 18),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Hoặc chọn ảnh mẫu nhanh:', style: TextStyle(color: Colors.white60, fontSize: 11)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: sampleUrls.map((s) {
                  return ActionChip(
                    backgroundColor: Colors.white12,
                    label: Text(s['name']!, style: const TextStyle(color: Colors.white, fontSize: 10.5)),
                    onPressed: () {
                      controller.text = s['url']!;
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final newUrl = controller.text.trim();
                if (newUrl.isNotEmpty) {
                  setState(() {
                    _customImageUrl = newUrl;
                    _selectedShapeIndex = 2; // Chuyển luôn sang tab Khung tranh 3D
                  });
                  Navigator.pop(ctx);
                  _showSnack('Đang tải ảnh mới từ URL...');
                  final bytes = await _fetchImageBytes(newUrl);
                  if (bytes != null) {
                    _cachedImageBytes = bytes;
                    _showSnack('Đã tải xong. Hãy chạm vào sàn nhà để ghim Khung Tranh 3D.');
                  } else {
                    _showSnack('Không thể tải ảnh trực tiếp, sử dụng ảnh mặc định.');
                  }
                }
              },
              child: const Text('Lưu & Chọn Ghim', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

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
                            _showSnack('Đã xóa toàn bộ dữ liệu vị trí AR đã lưu.');
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
                          'Chưa có tọa độ nào được lưu.\nHãy ghim vật thể ra sàn, chạm vào vật thể rồi bấm [Lưu Vị Trí].',
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
                                      customUrl: item.customUrl,
                                      initialScale: item.scale,
                                    );
                                    _showSnack('Đã khôi phục [${item.name}] từ CSDL ra không gian AR.');
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
    _showSnack('Đã xóa toàn bộ đối tượng AR trong không gian.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR 6DoF Space Studio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          // NÚT ĐỔI LINK ẢNH URL TÙY CHỌN
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF00E5FF)),
            tooltip: 'Đổi Link Ảnh 3D URL bất kỳ',
            onPressed: _openChangeImageUrlDialog,
          ),
          // NÚT XEM VỊ TRÍ ĐÃ LƯU
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
              final fighter = SelectedFighterService.instance.currentFighter;
              ArLauncher.launchAr(
                context: context,
                modelUrl: fighter.modelUrl,
                title: '${fighter.name} (AR 3D)',
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

          // BANNER HƯỚNG DẪN TRÊN CÙNG (TỰ ĐỘNG THEO NOTCH/TAI THỎ)
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: SafeArea(
              child: ArInstructionBanner(
                placedCount: _placedObjectsCount,
                isPlaneDetected: _isPlaneDetected,
              ),
            ),
          ),

          // KHUNG NGẮM QUÉT BÌA SÁCH / VẬT THỂ KHI CHỌN SÁCH HOẶC BẢN ĐỒ
          if ((_selectedShapeIndex == 3 || _selectedShapeIndex == 4 || _selectedShapeIndex == 5) && _placedObjectsCount == 0)
            Center(
              child: IgnorePointer(
                child: Container(
                  width: 240,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _isPlaneDetected ? const Color(0xFF00E5FF) : Colors.white30,
                      width: 2,
                    ),
                    boxShadow: _isPlaneDetected
                        ? [const BoxShadow(color: Color(0x4D00E5FF), blurRadius: 16)]
                        : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.center_focus_strong,
                          color: _isPlaneDetected ? const Color(0xFF00E5FF) : Colors.white38,
                          size: 44,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _isPlaneDetected ? 'CHẠM VÀO SÁCH ĐỂ CHIẾU 3D GHI ĐÈ' : 'HƯỚNG CAMERA VÀO BÌA SÁCH / VẬT THỂ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isPlaneDetected ? const Color(0xFF00E5FF) : Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // THANH CÔNG CỤ DƯỚI ĐÁY TÍCH HỢP (RESPONSIVE CHO MỌI DÒNG MÁY & MÀN GẬP)
          Positioned(
            bottom: 10,
            left: 12,
            right: 12,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // THANH ĐIỀU KHIỂN VẬT THỂ KHI ĐƯỢC CHỌN (PHÓNG TO / THU NHỎ / XOAY / LƯU / XÓA)
                  if (_selectedNode != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xF20A0F1D),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
                        boxShadow: const [
                          BoxShadow(color: Color(0x6600E5FF), blurRadius: 14),
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
                                  const Icon(Icons.touch_app, color: Color(0xFF00E5FF), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ĐANG CHỌN: ${_selectedNode!.name.toUpperCase()} • TỈ LỆ: ${(_selectedNode!.scale * 100).round()}%',
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
                          const SizedBox(height: 6),
                          // HÀNG NÚT CUỘN NGANG AN TOÀN TRÁNH TRÀN TRÊN MÁY BẢNG / GẬP FOLD 4
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                // NÚT PHÓNG TO
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.22),
                                    foregroundColor: const Color(0xFF00E5FF),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: const BorderSide(color: Color(0xFF00E5FF)),
                                    ),
                                  ),
                                  icon: const Icon(Icons.zoom_in, size: 16),
                                  label: const Text('Phóng to (+)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  onPressed: () => _scaleSelectedNode(1.2),
                                ),
                                const SizedBox(width: 6),
                                // NÚT THU NHỎ
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white12,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.zoom_out, size: 16, color: Colors.amberAccent),
                                  label: const Text('Thu nhỏ (-)', style: TextStyle(fontSize: 11)),
                                  onPressed: () => _scaleSelectedNode(0.83),
                                ),
                                const SizedBox(width: 6),
                                // XOAY TRÁI -30 ĐỘ
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white12,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.rotate_left, size: 16, color: Color(0xFF00E5FF)),
                                  label: const Text('-30°', style: TextStyle(fontSize: 11)),
                                  onPressed: () => _rotateSelectedNode(-math.pi / 6),
                                ),
                                const SizedBox(width: 6),
                                // XOAY PHẢI +30 ĐỘ
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white12,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.rotate_right, size: 16, color: Color(0xFF00E5FF)),
                                  label: const Text('+30°', style: TextStyle(fontSize: 11)),
                                  onPressed: () => _rotateSelectedNode(math.pi / 6),
                                ),
                                const SizedBox(width: 6),
                                // LƯU VỊ TRÍ VÀO CSDL
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.28),
                                    foregroundColor: const Color(0xFF00E5FF),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: const BorderSide(color: Color(0xFF00E5FF)),
                                    ),
                                  ),
                                  icon: const Icon(Icons.save, size: 16),
                                  label: const Text('Lưu Vị Trí', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  onPressed: _saveSelectedNodeLocation,
                                ),
                                const SizedBox(width: 6),
                                // XÓA VẬT THỂ NÀY
                                IconButton(
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.redAccent.withValues(alpha: 0.25),
                                    foregroundColor: Colors.redAccent,
                                    padding: const EdgeInsets.all(7),
                                  ),
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  tooltip: 'Xóa vật thể này',
                                  onPressed: _deleteSelectedNode,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // THANH CÔNG CỤ CHỌN VẬT THỂ ĐỂ GHIM (DOCK CHÍNH)
                  ArSelectionToolbar(
                    shapeNames: _shapeNames,
                    selectedIndex: _selectedShapeIndex,
                    onSelect: (index) {
                      setState(() {
                        _selectedShapeIndex = index;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
