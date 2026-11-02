import 'package:flutter/material.dart';
import 'package:proj_1/features/ar_studio/presentation/screens/ar_view_screen.dart';
import 'package:proj_1/features/character_3d/presentation/screens/character_3d_screen.dart';
import 'package:proj_1/features/game_3d/presentation/screens/threejs_game_screen.dart';

/// Màn hình điều hướng chính (Master Navigation Hub).
/// Gồm 3 Tab độc lập theo kiến trúc Feature-First:
/// 1. AR Studio: ARCore Native 6DoF Camera (Bảng Data 3D, Quả cầu Bubble 3D).
/// 2. Character 3D: Khám phá mô hình 3D 360 độ (Phi hành gia, AR Scene Viewer).
/// 3. Game 3D: Đấu trường Robot Three.js PvP (Vật lý chống va chạm, Đấm nhau, Zoom cam).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return const ArViewScreen();
      case 1:
        return const Character3DScreen();
      case 2:
        return const ThreeJsGameScreen();
      default:
        return const ArViewScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF0D1117),
        indicatorColor: const Color(0xFF00E5FF).withValues(alpha: 0.25),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.camera_alt, color: Color(0xFF00E5FF)),
            label: 'AR Studio',
          ),
          NavigationDestination(
            icon: Icon(Icons.accessibility_new_outlined, color: Colors.white70),
            selectedIcon: Icon(
              Icons.accessibility_new,
              color: Color(0xFF00E5FF),
            ),
            label: 'Chọn Tướng 3D',
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
