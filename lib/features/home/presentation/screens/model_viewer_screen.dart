import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../../core/utils/ar_launcher.dart';

/// Màn hình tương tác và xem trước mô hình 3D (3D Model Studio).
///
/// Sử dụng `model_viewer_plus` (dựa trên WebGL / Three.js ngầm).
/// Cho phép người dùng:
/// - Xoay 360 độ, zoom phóng to/thu nhỏ mô hình ảo trên màn hình.
/// - Đổi màu nền phòng trưng bày (Studio Background).
/// - Bấm nút camera AR ở góc phải để kích hoạt Google Scene Viewer đưa vật thể ra thế giới thực.
class ModelViewerScreen extends StatefulWidget {
  final String modelUrl;        // Link file mô hình định dạng .glb
  final String modelTitle;      // Tiêu đề của mô hình
  final String? iosModelUrl;    // Link file .usdz dành riêng cho iOS QuickLook

  const ModelViewerScreen({
    super.key,
    required this.modelUrl,
    required this.modelTitle,
    this.iosModelUrl,
  });

  @override
  State<ModelViewerScreen> createState() => _ModelViewerScreenState();
}

class _ModelViewerScreenState extends State<ModelViewerScreen> {
  // Trạng thái tự động quay tròn mô hình
  bool _autoRotate = true;

  // Chỉ số màu nền đang chọn
  int _bgColorIndex = 0;

  // Dữ liệu mô hình hiện tại
  late String _currentModelUrl;
  late String _currentTitle;
  String? _currentIosUrl;

  // Bảng màu nền phòng trưng bày 3D
  static const List<Color> _bgColors = [
    Color(0xFF121826),
    Color(0xFF1E293B),
    Color(0xFFF8FAFC),
    Color(0xFF0F172A),
  ];

  @override
  void initState() {
    super.initState();
    _currentModelUrl = widget.modelUrl;
    _currentTitle = widget.modelTitle;
    _currentIosUrl = widget.iosModelUrl ??
        'https://modelviewer.dev/shared-assets/models/Astronaut.usdz';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = _bgColors[_bgColorIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle),
        actions: [
          // Nút bấm kích hoạt mở Google Scene Viewer ngoài đời thực
          IconButton(
            tooltip: 'Mở AR Camera trực tiếp',
            icon: const Icon(Icons.view_in_ar, size: 28),
            onPressed: () {
              ArLauncher.launchAr(
                context: context,
                modelUrl: _currentModelUrl,
                title: _currentTitle,
              );
            },
          ),
          // Nút bật/tắt tự động xoay mô hình
          IconButton(
            tooltip: _autoRotate ? 'Dừng tự xoay' : 'Bật tự xoay',
            icon: Icon(_autoRotate ? Icons.pause_circle_outline : Icons.play_circle_outline),
            onPressed: () {
              setState(() {
                _autoRotate = !_autoRotate;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Khung hiển thị mô hình 3D tương tác
          Container(
            color: bgColor,
            child: ModelViewer(
              backgroundColor: bgColor,
              src: _currentModelUrl,
              alt: _currentTitle,
              ar: true,                         // Kích hoạt chế độ AR nếu thiết bị hỗ trợ
              arModes: const ['scene-viewer', 'webxr', 'quick-look'],
              autoRotate: _autoRotate,          // Tự xoay 360 độ
              cameraControls: true,             // Cho phép vuốt tay để xoay, chụm 2 ngón tay để phóng to/thu nhỏ
              iosSrc: _currentIosUrl,
              disableZoom: false,
            ),
          ),

          // 2. Bảng điều khiển màu nền Studio ở phía dưới
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Màu nền Studio:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: List.generate(_bgColors.length, (index) {
                      final color = _bgColors[index];
                      final isSelected = index == _bgColorIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _bgColorIndex = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }),
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
