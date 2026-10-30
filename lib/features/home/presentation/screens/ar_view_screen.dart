import 'package:flutter/material.dart';
import 'package:arcore_flutter_plus/arcore_flutter_plus.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

/// Màn hình AR không gian thực tế (True 6DoF AR Spatial Studio).
///
/// Sử dụng công nghệ ARCore Native (SLAM + Plane Detection) kết hợp Sceneform.
/// Cho phép phát hiện mặt sàn/mặt bàn ngoài đời thực và ghim các vật thể 3D vào
/// mỏ neo vật lý (Anchor), giúp người dùng có thể bước đi xung quanh 360 độ hoặc ra
/// đằng sau để quan sát vật thể cố định trong không gian thực.
class ArViewScreen extends StatefulWidget {
  const ArViewScreen({super.key});

  @override
  State<ArViewScreen> createState() => _ArViewScreenState();
}

class _ArViewScreenState extends State<ArViewScreen> {
  // Bộ điều khiển phiên làm việc ARCore (quản lý thêm/xóa node và bắt sự kiện chạm)
  ArCoreController? _arCoreController;

  // Chỉ số loại vật thể 3D đang được người dùng lựa chọn trong thanh công cụ
  int _selectedShapeIndex = 0;

  // Danh sách tên các mô hình/hình khối có sẵn để tương tác
  static const List<String> _shapeNames = [
    'Quả cầu Kim loại',
    'Khối lập phương Vàng',
    'Trụ Ruby Đỏ',
    'Mô hình Phi hành gia',
  ];

  // Đếm tổng số vật thể đã ghim thành công lên mặt sàn
  int _placedObjectsCount = 0;

  @override
  void dispose() {
    // Giải phóng tài nguyên camera và phiên ARCore khi thoát khỏi màn hình
    _arCoreController?.dispose();
    super.dispose();
  }

  /// Hàm callback được kích hoạt khi ARCore PlatformView khởi tạo thành công
  void _onArCoreViewCreated(ArCoreController controller) {
    _arCoreController = controller;

    // Lắng nghe sự kiện người dùng chạm (tap) vào mặt phẳng sàn/bàn đã được ARCore phát hiện
    _arCoreController?.onPlaneTap = _handleOnPlaneTap;
  }

  /// Xử lý sự kiện khi có cú chạm vào mặt phẳng
  void _handleOnPlaneTap(List<ArCoreHitTestResult> hits) {
    // Nếu điểm chạm không nằm trên mặt phẳng hợp lệ thì bỏ qua
    if (hits.isEmpty) return;

    // Lấy điểm giao cắt đầu tiên (điểm tiếp xúc gần nhất với mặt sàn/bàn trong đời thực)
    final hit = hits.first;
    _addNodeAtHitPosition(hit);
  }

  /// Tạo node 3D và ghim cố định vào tọa độ không gian thực của điểm chạm
  void _addNodeAtHitPosition(ArCoreHitTestResult hit) {
    if (_arCoreController == null) return;

    ArCoreNode node;

    switch (_selectedShapeIndex) {
      case 0:
        // 1. Quả cầu kim loại Chrome phản chiếu ánh sáng môi trường phòng
        final material = ArCoreMaterial(
          color: Colors.cyanAccent,
          metallic: 1.0,  // Tính chất kim loại tối đa
          roughness: 0.1, // Độ nhám thấp -> phản quang sắc nét
        );
        final sphere = ArCoreSphere(
          materials: [material],
          radius: 0.12, // Bán kính 12 cm ngoài đời thực
        );
        node = ArCoreNode(
          shape: sphere,
          // Nâng nhẹ trục Y thêm 0.12m để tâm quả cầu nằm tiếp xúc ngay trên mặt phẳng sàn
          position: hit.pose.translation + vector.Vector3(0, 0.12, 0),
          rotation: hit.pose.rotation,
        );
        break;

      case 1:
        // 2. Khối lập phương vàng Gold sang trọng
        final material = ArCoreMaterial(
          color: Colors.amber,
          metallic: 0.9,
          roughness: 0.2,
        );
        final cube = ArCoreCube(
          materials: [material],
          size: vector.Vector3(0.2, 0.2, 0.2), // Kích thước mỗi cạnh 20 cm
        );
        node = ArCoreNode(
          shape: cube,
          // Nâng trục Y 0.1m để đáy khối lập phương đặt phẳng lên sàn
          position: hit.pose.translation + vector.Vector3(0, 0.1, 0),
          rotation: hit.pose.rotation,
        );
        break;

      case 2:
        // 3. Khối trụ Ruby đỏ
        final material = ArCoreMaterial(
          color: Colors.redAccent,
          metallic: 0.8,
          roughness: 0.3,
        );
        final cylinder = ArCoreCylinder(
          materials: [material],
          radius: 0.1,
          height: 0.25, // Cao 25 cm
        );
        node = ArCoreNode(
          shape: cylinder,
          position: hit.pose.translation + vector.Vector3(0, 0.125, 0),
          rotation: hit.pose.rotation,
        );
        break;

      case 3:
      default:
        // 4. Mô hình 3D thực tế (Phi hành gia - Astronaut.glb)
        node = ArCoreReferenceNode(
          name: "Astronaut_${DateTime.now().millisecondsSinceEpoch}",
          objectUrl: "https://modelviewer.dev/shared-assets/models/Astronaut.glb",
          position: hit.pose.translation,
          rotation: hit.pose.rotation,
          scale: vector.Vector3(0.25, 0.25, 0.25), // Thu nhỏ tỷ lệ để vừa vặn mặt bàn
        );
        break;
    }

    // [CỐT LÕI 6DoF]: Ghim cứng vật thể vào tọa độ thế giới thông qua Anchor của ARCore.
    // Anchor đảm bảo khi camera di chuyển ra xa hay đi vòng lại phía sau,
    // vật thể vẫn đứng im tuyệt đối tại điểm tiếp xúc thực tế.
    _arCoreController?.addArCoreNodeWithAnchor(node);

    setState(() {
      _placedObjectsCount++;
    });

    // Thông báo gợi ý người dùng trải nghiệm di chuyển vòng quanh
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎯 Đã ghim ${_shapeNames[_selectedShapeIndex]} vào mặt sàn! Bạn hãy bước đi vòng quanh để ngắm nhìn.',
        ),
        backgroundColor: Colors.green[800],
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  /// Xóa toàn bộ các vật thể đã ghim bằng cách tái khởi động phiên AR
  void _clearAllNodes() {
    setState(() {
      _placedObjectsCount = 0;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ArViewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARCore Native Space Studio'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          // Nút dọn dẹp các vật thể đã đặt trên sàn
          if (_placedObjectsCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xóa các vật thể đã đặt',
              onPressed: _clearAllNodes,
            ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Màn hình camera ARCore Native thực thụ
          // Hiển thị lưới chấm li ti (Feature points) khi nhận diện được mặt phẳng sàn/bàn
          ArCoreView(
            onArCoreViewCreated: _onArCoreViewCreated,
            enablePlaneRenderer: true, // Bật chế độ quét và hiển thị lưới mặt phẳng sàn/bàn
            enableTapRecognizer: true, // Bật tính năng nhận diện cử chỉ chạm vào mặt sàn
          ),

          // 2. Banner hiển thị hướng dẫn tương tác cho người dùng
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.screen_search_desktop, color: Colors.amber, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _placedObjectsCount == 0
                            ? 'Lia camera từ từ xuống mặt sàn/mặt bàn cho đến khi hiện lưới chấm li ti → Chạm vào sàn để ghim vật thể.'
                            : 'Đã ghim $_placedObjectsCount vật thể! Cầm máy bước lại gần hoặc đi vòng xung quanh để ngắm từ mọi góc.',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Thanh Dock phía dưới để chọn loại mô hình/hình khối trước khi chạm đặt
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Chọn vật thể để chạm đặt lên sàn:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _shapeNames.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final isSelected = index == _selectedShapeIndex;
                        return ChoiceChip(
                          label: Text(
                            _shapeNames[index],
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.amber,
                          backgroundColor: Colors.white10,
                          onSelected: (_) {
                            setState(() {
                              _selectedShapeIndex = index;
                            });
                          },
                        );
                      },
                    ),
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
