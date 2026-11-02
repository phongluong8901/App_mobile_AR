import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
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

/// Quản lý từng vật thể AR đang ghim trong không gian thực
class PlacedArNode {
  final String id;
  final String name;
  final int shapeIndex;
  final vector.Vector3 position;
  double rotationAngleY;
  vector.Vector4 rotation;
  Uint8List? textureBytes; // Dành cho Khung tranh 3D hoặc Dashboard
  String? customUrl;

  PlacedArNode({
    required this.id,
    required this.name,
    required this.shapeIndex,
    required this.position,
    required this.rotationAngleY,
    required this.rotation,
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
  State<ArViewScreen> createState() => _ArViewScreenState();
}

class _ArViewScreenState extends State<ArViewScreen> {
  ArCoreController? _arCoreController;

  int _selectedShapeIndex = 0;

  static const List<String> _shapeNames = [
    '📊 Bảng Data 3D',
    '🤖 Nhân Vật 3D AR',
    '🖼️ Tranh 3D từ URL',
    '🔮 Quả cầu Bubble 3D',
    '🧊 Khối Gold 3D',
    '🔴 Trụ Ruby 3D',
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
        text: '🖼️ 3D AR PHOTO FRAME\n(Cyber Hologram Art)',
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
      _showSnack('🎯 Đã chọn [${found.name}]! Bạn có thể Xoay hoặc Xóa ở thanh công cụ dưới.');
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

  Future<void> _addNodeAtHitPosition(
    vector.Vector3 position,
    vector.Vector4 rotation,
    int shapeIndex, {
    String? customUrl,
    Uint8List? preloadedBytes,
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
        textureBytes: textureBytes,
      );
      _placedNodes.add(placed);

      setState(() {
        _placedObjectsCount = _placedNodes.length;
        _selectedNode = placed;
      });

      _showSnack('🎯 Đã ghim Bảng Data Dashboard lên mặt bàn! Chạm vào để Bật/Tắt đèn.');
      return;
    }

    // 2. GHIM KHUNG TRANH / ẢNH 3D TỪ BẤT KỲ URL NÀO
    if (shapeIndex == 2) {
      Uint8List? imageBytes = preloadedBytes ?? _cachedImageBytes;
      final targetUrl = customUrl ?? _customImageUrl;

      if (imageBytes == null) {
        _showSnack('⏳ Đang tải ảnh từ URL...');
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
        size: vector.Vector3(0.44, 0.30, 0.018),
      );

      final pictureNode = ArCoreNode(
        name: nodeId,
        shape: pictureFrame,
        position: position + vector.Vector3(0, 0.18, 0),
        rotation: rotation,
      );

      _arCoreController?.addArCoreNodeWithAnchor(pictureNode);

      final placed = PlacedArNode(
        id: nodeId,
        name: 'Tranh 3D URL',
        shapeIndex: 2,
        position: position,
        rotationAngleY: 0,
        rotation: rotation,
        textureBytes: imageBytes,
        customUrl: targetUrl,
      );
      _placedNodes.add(placed);

      setState(() {
        _placedObjectsCount = _placedNodes.length;
        _selectedNode = placed;
      });

      _showSnack('🖼️ Đã ghim Khung Tranh 3D từ URL lên sàn! Chạm vào tranh để Xoay hoặc Xóa.');
      return;
    }

    // 3. CÁC HÌNH KHÁC (NHÂN VẬT 3D, QUẢ CẦU, KHỐI VÀNG, TRỤ RUBY)
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
      _showSnack('🤖 Đã ghim Nhân vật 3D lên sàn! Chạm vào để Xoay hoặc Xóa.');
    } else {
      _showSnack('🎯 Đã ghim $shapeName vào sàn! Chạm vào để Xoay hoặc Xóa.');
    }
  }

  ArCoreNode _createNodeInstance(
    String id,
    int shapeIndex,
    vector.Vector3 position,
    vector.Vector4 rotation, {
    Uint8List? textureBytes,
  }) {
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
          shape: ArCoreCube(
            materials: [
              ArCoreMaterial(color: Colors.white, textureBytes: textureBytes, metallic: 0.1, roughness: 0.35),
            ],
            size: vector.Vector3(0.44, 0.30, 0.018),
          ),
          position: position + vector.Vector3(0, 0.18, 0),
          rotation: rotation,
        );
      case 3:
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
      case 4:
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
      case 5:
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
        textureBytes: node.textureBytes,
      );
      _arCoreController?.addArCoreNodeWithAnchor(updatedNode);
    }

    final deg = (node.rotationAngleY * 180 / math.pi).round() % 360;
    _showSnack('🔄 Đã xoay [${node.name}] sang góc $deg°');
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

    _showSnack('🗑️ Đã xóa [${node.name}] khỏi không gian!');
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
      customUrl: node.customUrl,
      createdAt: DateTime.now(),
    );

    await ArLocationStorageService.instance.saveLocation(location);

    _showSnack(
      '💾 Đã lưu tọa độ [X: ${node.position.x.toStringAsFixed(2)}, Y: ${node.position.y.toStringAsFixed(2)}, Z: ${node.position.z.toStringAsFixed(2)}] vào CSDL!',
    );
  }

  /// HỘP THOẠI ĐỔI ĐƯỜNG LINK ẢNH 3D TÙY Ý TỪ INTERNET
  void _openChangeImageUrlDialog() {
    final controller = TextEditingController(text: _customImageUrl);

    final sampleUrls = [
      {'name': '🎨 Hội Họa', 'url': 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=600'},
      {'name': '🌌 NASA Vũ Trụ', 'url': 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600'},
      {'name': '🏙️ Cyberpunk', 'url': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600'},
      {'name': '🌸 Anime Phong Cảnh', 'url': 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600'},
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
                  _showSnack('⏳ Đang tải ảnh mới từ URL...');
                  final bytes = await _fetchImageBytes(newUrl);
                  if (bytes != null) {
                    _cachedImageBytes = bytes;
                    _showSnack('✅ Đã tải xong! Hãy chạm vào sàn nhà để ghim Khung Tranh 3D.');
                  } else {
                    _showSnack('⚠️ Không thể tải ảnh trực tiếp, sẽ dùng ảnh khung 3D nghệ thuật dự phòng.');
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
                          'Chưa có tọa độ nào được lưu.\nHãy ghim vật thể/khung tranh ra sàn, chạm vào vật thể rồi bấm [💾 Lưu Vị Trí]!',
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
