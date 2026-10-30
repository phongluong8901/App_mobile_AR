import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArViewScreen extends StatefulWidget {
  const ArViewScreen({super.key});

  @override
  State<ArViewScreen> createState() => _ArViewScreenState();
}

class _ArViewScreenState extends State<ArViewScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;

  // Danh sách các mô hình 3D AR
  int _selectedModelIndex = 0;
  static const List<Map<String, String>> _models = [
    {
      'title': 'Phi hành gia (Astronaut)',
      'url': 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
    },
    {
      'title': 'Robot cử động (Robot)',
      'url': 'https://modelviewer.dev/shared-assets/models/RobotExpressive.glb',
    },
    {
      'title': 'Bộ đồ du hành (Neil Armstrong)',
      'url': 'https://modelviewer.dev/shared-assets/models/NeilArmstrong.glb',
    },
    {
      'title': 'Ghế bành 3D (Sheen Chair)',
      'url': 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/SheenChair/glTF-Binary/SheenChair.glb',
    },
  ];

  // Tọa độ gốc do người dùng đặt (User Anchor Offset)
  Offset _baseAnchorOffset = Offset.zero;
  double _modelScale = 1.0;
  bool _autoRotate = true;

  // Tính năng Gyroscope World-Tracking (Ghim vào không gian phòng)
  bool _isGyroTrackingEnabled = true;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  double _currentPanX = 0.0; // Góc xoay ngang (rad)
  double _currentPanY = 0.0; // Góc xoay dọc (rad)
  DateTime? _lastGyroTimestamp;

  // Hệ số khuếch đại góc nhìn camera (FOV factor ~ 60 độ camera điện thoại)
  static const double _fovFactor = 650.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedAnchor();
    _initCamera();
    _startGyroTracking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gyroSubscription?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      _gyroSubscription?.pause();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
      _gyroSubscription?.resume();
    }
  }

  // Nạp lại tọa độ đã ghim trước đó từ SharedPreferences (nếu có)
  Future<void> _loadSavedAnchor() async {
    final prefs = await SharedPreferences.getInstance();
    final savedX = prefs.getDouble('ar_anchor_x');
    final savedY = prefs.getDouble('ar_anchor_y');
    final savedScale = prefs.getDouble('ar_scale');
    final savedModel = prefs.getInt('ar_model_index');

    if (savedX != null && savedY != null && mounted) {
      setState(() {
        _baseAnchorOffset = Offset(savedX, savedY);
        if (savedScale != null) _modelScale = savedScale;
        if (savedModel != null && savedModel < _models.length) {
          _selectedModelIndex = savedModel;
        }
      });
    }
  }

  // Lưu vị trí ghim hiện tại vào SharedPreferences
  Future<void> _saveCurrentAnchor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ar_anchor_x', _baseAnchorOffset.dx);
    await prefs.setDouble('ar_anchor_y', _baseAnchorOffset.dy);
    await prefs.setDouble('ar_scale', _modelScale);
    await prefs.setInt('ar_model_index', _selectedModelIndex);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Đã lưu vị trí ghim vào bộ nhớ máy! Lần sau mở app sẽ tự phục hồi.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Khởi động con quay hồi chuyển để bù trừ góc lia máy (World Anchoring)
  void _startGyroTracking() {
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (!_isGyroTrackingEnabled) return;

      final now = DateTime.now();
      if (_lastGyroTimestamp == null) {
        _lastGyroTimestamp = now;
        return;
      }

      final dt = now.difference(_lastGyroTimestamp!).inMicroseconds / 1000000.0;
      _lastGyroTimestamp = now;

      // Giới hạn dt hợp lệ (tránh nhảy đột ngột)
      if (dt > 0.1) return;

      setState(() {
        // Gyroscope:
        // event.y: Xoay quanh trục Y (quay điện thoại sang trái/phải)
        // event.x: Xoay quanh trục X (ngửa/chúc điện thoại)
        _currentPanX += event.y * dt;
        _currentPanY += event.x * dt;

        // Giới hạn góc nhìn trong phạm vi hợp lý quanh điểm ghim
        _currentPanX = _currentPanX.clamp(-math.pi, math.pi);
        _currentPanY = _currentPanY.clamp(-math.pi / 2, math.pi / 2);
      });
    });
  }

  // Đặt lại điểm gốc con quay về hướng điện thoại đang chỉ
  void _recenterGyroAnchor() {
    setState(() {
      _currentPanX = 0.0;
      _currentPanY = 0.0;
      _baseAnchorOffset = Offset.zero;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎯 Đã ghim vật thể tại hướng nhìn camera hiện tại!'),
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _isPermissionDenied = true;
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isPermissionDenied = true;
        });
        return;
      }
      await _setupCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint("Lỗi khởi tạo Camera: $e");
      setState(() {
        _isPermissionDenied = true;
      });
    }
  }

  Future<void> _setupCameraController(CameraDescription camera) async {
    _cameraController?.dispose();
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
        _isPermissionDenied = false;
      });
    } catch (e) {
      debugPrint("Lỗi setup controller: $e");
    }
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final currentModel = _models[_selectedModelIndex];

    // Tính toán tọa độ thực tế của vật thể:
    // Tọa độ người dùng đặt + độ lệch bù trừ khi lia điện thoại qua cảm biến Gyroscope
    final double gyroShiftX = _isGyroTrackingEnabled ? -(_currentPanX * _fovFactor) : 0.0;
    final double gyroShiftY = _isGyroTrackingEnabled ? (_currentPanY * _fovFactor) : 0.0;
    final Offset totalOffset = Offset(
      _baseAnchorOffset.dx + gyroShiftX,
      _baseAnchorOffset.dy + gyroShiftY,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.6),
        foregroundColor: Colors.white,
        title: const Text('AR World Anchor Studio'),
        actions: [
          // Nút bật/tắt ghim cảm biến
          IconButton(
            icon: Icon(
              _isGyroTrackingEnabled ? Icons.explore : Icons.explore_off,
              color: _isGyroTrackingEnabled ? Colors.amber : Colors.white60,
            ),
            tooltip: _isGyroTrackingEnabled
                ? 'Đang bật Ghim không gian thực'
                : 'Đang tắt Ghim không gian',
            onPressed: () {
              setState(() {
                _isGyroTrackingEnabled = !_isGyroTrackingEnabled;
              });
            },
          ),
          // Nút lưu vị trí vào máy
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Lưu vị trí ghim',
            onPressed: _saveCurrentAnchor,
          ),
          if (_cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              tooltip: 'Đổi Camera trước/sau',
              onPressed: _switchCamera,
            ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Tầng Camera Stream thời gian thực
          Positioned.fill(
            child: _buildCameraLayer(),
          ),

          // 2. Chạm vào màn hình để đặt vị trí (Touch to Place Anchor)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) {
                final size = MediaQuery.of(context).size;
                setState(() {
                  // Chạm vào đâu ghim vật thể tại hướng đó
                  _baseAnchorOffset = Offset(
                    details.localPosition.dx - (size.width / 2) - gyroShiftX,
                    details.localPosition.dy - (size.height / 2) - gyroShiftY,
                  );
                });
              },
            ),
          ),

          // 3. Tầng Vật thể 3D AR nổi trên nền Camera
          Center(
            child: Transform.translate(
              offset: totalOffset,
              child: Transform.scale(
                scale: _modelScale,
                child: SizedBox(
                  width: 320,
                  height: 380,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Mô hình 3D trong suốt
                      ModelViewer(
                        key: ValueKey('${currentModel['url']}-$_autoRotate'),
                        src: currentModel['url']!,
                        alt: currentModel['title']!,
                        ar: false,
                        autoRotate: _autoRotate,
                        cameraControls: true,
                        backgroundColor: Colors.transparent,
                      ),

                      // Bệ định vị Anchor màu vàng
                      Positioned(
                        bottom: 12,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _baseAnchorOffset += details.delta;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isGyroTrackingEnabled ? Icons.push_pin : Icons.open_with,
                                  size: 15,
                                  color: Colors.black87,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isGyroTrackingEnabled ? 'Đã ghim không gian thực' : 'Kéo để di chuyển',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Banner hướng dẫn trạng thái ghim
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isGyroTrackingEnabled ? Colors.amber.withValues(alpha: 0.5) : Colors.white24,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isGyroTrackingEnabled ? Icons.explore : Icons.touch_app,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isGyroTrackingEnabled
                            ? 'Con quay hồi chuyển BẬT: Lia camera qua lại vật thể vẫn đứng yên chỗ cũ trong phòng.'
                            : 'Ghim TẮT: Chạm hoặc kéo để chỉnh vị trí tự do.',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Thanh chọn mô hình ở trên cùng
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _models.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedModelIndex;
                  return ChoiceChip(
                    label: Text(
                      _models[index]['title']!.split('(').first.trim(),
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.amber,
                    backgroundColor: Colors.black54,
                    onSelected: (_) {
                      setState(() {
                        _selectedModelIndex = index;
                      });
                    },
                  );
                },
              ),
            ),
          ),

          // 6. Thanh điều khiển kích thước & ghim lại ở dưới cùng
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Thu nhỏ
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                    tooltip: 'Thu nhỏ',
                    onPressed: () {
                      setState(() {
                        if (_modelScale > 0.4) _modelScale -= 0.15;
                      });
                    },
                  ),
                  // Phóng to
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                    tooltip: 'Phóng to',
                    onPressed: () {
                      setState(() {
                        if (_modelScale < 2.5) _modelScale += 0.15;
                      });
                    },
                  ),
                  // Bật/tắt xoay
                  IconButton(
                    icon: Icon(
                      _autoRotate ? Icons.pause_circle : Icons.play_circle,
                      color: Colors.amber,
                    ),
                    tooltip: _autoRotate ? 'Dừng xoay' : 'Tự xoay',
                    onPressed: () {
                      setState(() {
                        _autoRotate = !_autoRotate;
                      });
                    },
                  ),
                  // Nút Ghim lại tại tâm camera hiện tại
                  IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.amber),
                    tooltip: 'Ghim tại hướng hiện tại',
                    onPressed: _recenterGyroAnchor,
                  ),
                  // Nút Lưu vị trí
                  IconButton(
                    icon: const Icon(Icons.save_outlined, color: Colors.white),
                    tooltip: 'Lưu vị trí này',
                    onPressed: _saveCurrentAnchor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraLayer() {
    if (_isPermissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Ứng dụng cần quyền Camera để hiển thị không gian AR.',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                icon: const Icon(Icons.settings, color: Colors.black),
                label: const Text('Mở cài đặt cấp quyền', style: TextStyle(color: Colors.black)),
                onPressed: () => openAppSettings(),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(height: 16),
            Text(
              'Đang khởi động Camera AR & Cảm biến...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize?.height ?? 1080,
          height: _cameraController!.value.previewSize?.width ?? 1920,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }
}
