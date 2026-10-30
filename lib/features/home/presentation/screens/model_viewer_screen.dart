import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../../core/utils/ar_launcher.dart';

class ModelViewerScreen extends StatefulWidget {
  final String modelUrl;
  final String modelTitle;
  final String? iosModelUrl;

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
  bool _autoRotate = true;
  int _bgColorIndex = 0;
  late String _currentModelUrl;
  late String _currentTitle;
  String? _currentIosUrl;

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
        ],
      ),
      body: Stack(
        children: [
          // 1. Core 3D & AR Viewer Widget
          ModelViewer(
            key: ValueKey('$_currentModelUrl-$_autoRotate-$_bgColorIndex'),
            src: _currentModelUrl,
            iosSrc: _currentIosUrl,
            alt: "A 3D model of $_currentTitle",
            ar: true,
            arModes: const ['scene-viewer', 'webxr', 'quick-look'],
            arScale: ArScale.auto,
            arPlacement: ArPlacement.floor,
            autoRotate: _autoRotate,
            cameraControls: true,
            backgroundColor: bgColor,
          ),

          // Banner hướng dẫn
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Vuốt để xoay 3D • Thu phóng bằng 2 ngón • Bấm nút "Xem AR Camera" bên dưới để đặt vào phòng thực tế',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // 2. Control Panel Overlay ở dưới màn hình
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionItem(
                    context,
                    icon: _autoRotate ? Icons.pause_circle_outline : Icons.rotate_right,
                    label: _autoRotate ? "Dừng xoay" : "Xoay 360",
                    onTap: () {
                      setState(() {
                        _autoRotate = !_autoRotate;
                      });
                    },
                  ),
                  _buildActionItem(
                    context,
                    icon: Icons.palette_outlined,
                    label: "Đổi nền",
                    onTap: () {
                      setState(() {
                        _bgColorIndex = (_bgColorIndex + 1) % _bgColors.length;
                      });
                    },
                  ),
                  _buildActionItem(
                    context,
                    icon: Icons.swap_horiz,
                    label: "Đổi mẫu",
                    onTap: () {
                      setState(() {
                        if (_currentModelUrl.contains('Astronaut')) {
                          _currentModelUrl =
                              'https://modelviewer.dev/shared-assets/models/RobotExpressive.glb';
                          _currentIosUrl =
                              'https://modelviewer.dev/shared-assets/models/RobotExpressive.usdz';
                          _currentTitle = 'Robot 3D Model';
                        } else {
                          _currentModelUrl =
                              'https://modelviewer.dev/shared-assets/models/Astronaut.glb';
                          _currentIosUrl =
                              'https://modelviewer.dev/shared-assets/models/Astronaut.usdz';
                          _currentTitle = 'Astronaut 3D Model';
                        }
                      });
                    },
                  ),
                  // Nút Xem trong AR Native Intent
                  _buildActionItem(
                    context,
                    icon: Icons.view_in_ar,
                    label: "Xem AR Camera",
                    highlight: true,
                    onTap: () {
                      ArLauncher.launchAr(
                        context: context,
                        modelUrl: _currentModelUrl,
                        title: _currentTitle,
                      );
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

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final color = highlight ? Colors.amber[800] ?? Colors.amber : theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: highlight ? 26 : 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                color: highlight ? color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
