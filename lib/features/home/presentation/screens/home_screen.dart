import 'package:flutter/material.dart';
import 'package:proj_1/features/ar_studio/presentation/screens/ar_view_screen.dart';
import 'package:proj_1/features/book_ar_scanner/presentation/screens/book_ar_scanner_screen.dart';
import 'package:proj_1/features/character_3d/presentation/screens/character_3d_screen.dart';
import 'package:proj_1/features/game_3d/presentation/screens/threejs_game_screen.dart';

/// Màn hình điều hướng chính (Master Navigation Hub).
/// Sử dụng IndexedStack để duy trì phiên AR Camera và WebGL ổn định 100%,
/// ngăn chặn việc khởi tạo và hủy SurfaceView liên tục gây xung đột camera trên Android.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ArViewScreenState> _arScreenKey = GlobalKey<ArViewScreenState>();

  void _openInArCamera(int shapeIndex) {
    _arScreenKey.currentState?.selectShape(shapeIndex);
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isShortHeight = MediaQuery.of(context).size.height < 520;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ArViewScreen(key: _arScreenKey),
          BookArScannerScreen(
            onSwitchToArCamera: _openInArCamera,
          ),
          const Character3DScreen(),
          const ThreeJsGameScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: isShortHeight ? 54 : 66,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF0D1117),
        indicatorColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
        labelBehavior: isShortHeight
            ? NavigationDestinationLabelBehavior.alwaysHide
            : NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.camera_alt, color: Color(0xFF00E5FF)),
            label: 'AR Studio',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.auto_stories, color: Color(0xFF00E5FF)),
            label: 'AR Sách & 3D',
          ),
          NavigationDestination(
            icon: Icon(Icons.accessibility_new_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.accessibility_new, color: Color(0xFF00E5FF)),
            label: 'Chọn Tướng',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.sports_esports, color: Color(0xFF00E5FF)),
            label: 'Game 3D',
          ),
        ],
      ),
    );
  }
}
