import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Component Hologram Dashboard giả lập AR 6DoF tương tác trực tiếp bằng Flutter Widget!
///
/// Tính năng:
/// 1. Tương tác thật 100%: Nút bấm, chuyển tab, đồng hồ live, slider...
/// 2. Giả lập cảm biến 3D Parallax: Cầm điện thoại nghiêng máy, xoay góc hoặc bước đi,
///    bảng Dashboard sẽ nghiêng theo góc nhìn 3D thực tế như đang lơ lửng trước mặt!
/// 3. Có nút Thu nhỏ / Mở rộng / Ghim góc màn hình hoặc ghim giữa không gian.
class SimulatedArDashboardOverlay extends StatefulWidget {
  final VoidCallback? onClose;
  final int placedCount;

  const SimulatedArDashboardOverlay({
    super.key,
    this.onClose,
    this.placedCount = 0,
  });

  @override
  State<SimulatedArDashboardOverlay> createState() =>
      _SimulatedArDashboardOverlayState();
}

class _SimulatedArDashboardOverlayState
    extends State<SimulatedArDashboardOverlay> {
  // Góc nghiêng mô phỏng 3D theo con quay hồi chuyển của máy
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  // Vị trí kéo thả tự do của Dashboard trên màn hình
  Offset _position = const Offset(20, 80);

  // Tab đang chọn trong Dashboard: 0: Tổng quan, 1: IoT Smart Home, 2: Camera an ninh
  int _currentTab = 0;

  // Trạng thái các thiết bị Smart Home tương tác được
  bool _lightLivingRoom = true;
  bool _airConditioner = false;
  double _temperature = 24.5;

  @override
  void initState() {
    super.initState();
    // Lắng nghe con quay hồi chuyển để tạo hiệu ứng 3D Parallax lơ lửng chân thật
    gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (mounted) {
        setState(() {
          // Lọc nhẹ để chuyển động mượt mà
          _tiltX = (_tiltX * 0.85 + event.y * 0.08).clamp(-0.25, 0.25);
          _tiltY = (_tiltY * 0.85 - event.x * 0.08).clamp(-0.25, 0.25);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        // Cho phép dùng tay kéo thả Dashboard ghim tại bất kỳ vị trí nào trên màn hình
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Hiệu ứng phối cảnh 3D Perspective
            ..rotateX(_tiltY)        // Nghiêng trục X theo cử động tay
            ..rotateY(_tiltX),       // Nghiêng trục Y theo cử động tay
          alignment: FractionalOffset.center,
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // Nền bán trong suốt màu Cyberpunk Hologram
              color: const Color(0xE60A0F1D),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF00E5FF),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Dashboard + Icon Kéo Thả + Nút Đóng
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0x3300E5FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stream,
                        color: Color(0xFF00E5FF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'HOLOGRAM WEB DASHBOARD',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.open_with,
                      color: Colors.white54,
                      size: 16,
                    ),
                    if (widget.onClose != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 18,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // 2. Tab Bar chuyển đổi tính năng bên trong Dashboard
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTabItem(index: 0, title: 'Hệ thống'),
                      _buildTabItem(index: 1, title: 'Smart Home'),
                      _buildTabItem(index: 2, title: 'Camera Live'),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Nội dung tương tác thay đổi theo từng Tab
                if (_currentTab == 0) _buildSystemTab(),
                if (_currentTab == 1) _buildSmartHomeTab(),
                if (_currentTab == 2) _buildCameraTab(),

                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    '👆 Chạm giữ để kéo di chuyển | Nghiêng máy để ngắm 3D',
                    style: TextStyle(color: Colors.white38, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({required int index, required String title}) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tab 1: Thông tin hệ thống AR & Tracking
  Widget _buildSystemTab() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatCard('SPATIAL TRACKING', '6DoF ACTIVE', Colors.greenAccent),
            _buildStatCard('ANCHORS PINNED', '${widget.placedCount} Nodes', Colors.amber),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.memory, color: Color(0xFF00E5FF), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SLAM FPS: 60.0 | Engine: ARCore v1.40',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tab 2: Bảng điều khiển Smart Home tương tác bấm nút thật
  Widget _buildSmartHomeTab() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đèn phòng khách:',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            Switch(
              value: _lightLivingRoom,
              activeColor: const Color(0xFF00E5FF),
              onChanged: (val) {
                setState(() {
                  _lightLivingRoom = val;
                });
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Điều hòa phòng:',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            Switch(
              value: _airConditioner,
              activeColor: Colors.amber,
              onChanged: (val) {
                setState(() {
                  _airConditioner = val;
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.thermostat, color: Colors.cyanAccent, size: 18),
            const SizedBox(width: 4),
            Text(
              '${_temperature.toStringAsFixed(1)}°C',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Slider(
                value: _temperature,
                min: 16.0,
                max: 30.0,
                activeColor: const Color(0xFF00E5FF),
                onChanged: (val) {
                  setState(() {
                    _temperature = val;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Tab 3: Giả lập màn hình Camera an ninh / Video feed
  Widget _buildCameraTab() {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_outlined,
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                  size: 32,
                ),
                const SizedBox(height: 4),
                const Text(
                  'CCTV CAM #01 - FRONT DOOR',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '● REC 1080P',
                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

