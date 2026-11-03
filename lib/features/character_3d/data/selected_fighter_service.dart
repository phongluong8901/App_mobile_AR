import 'package:flutter/material.dart';

/// Dữ liệu Nhân vật 3D chia sẻ giữa Tab 2 (Studio) và Tab 3 (Đấu trường Game).
class FighterConfig {
  final String id;
  final String name;
  final String role;
  final String modelUrl;
  final int speed;
  final int power;
  final int maxHp;
  final Color themeColor;
  final String hexColor;

  const FighterConfig({
    required this.id,
    required this.name,
    required this.role,
    required this.modelUrl,
    required this.speed,
    required this.power,
    required this.maxHp,
    required this.themeColor,
    required this.hexColor,
  });
}

/// Dịch vụ đồng bộ Tướng chiến đấu toàn cục (Singleton).
/// Cho phép bất kỳ thay đổi nào ở Tab 2 (Chọn tướng) lập tức có hiệu lực ở Tab 3 (Game 3D).
class SelectedFighterService {
  SelectedFighterService._();
  static final SelectedFighterService instance = SelectedFighterService._();

  static const defaultFighter = FighterConfig(
    id: 'robot_titan',
    name: 'Robot Cyber Titan',
    role: 'Đấu Sĩ Toàn Diện',
    modelUrl: 'https://raw.githubusercontent.com/mrdoob/three.js/master/examples/models/gltf/RobotExpressive/RobotExpressive.glb',
    speed: 85,
    power: 90,
    maxHp: 120,
    themeColor: Color(0xFF00E5FF),
    hexColor: '#00E5FF',
  );

  final ValueNotifier<FighterConfig> selectedFighterNotifier =
      ValueNotifier<FighterConfig>(defaultFighter);

  FighterConfig get currentFighter => selectedFighterNotifier.value;

  void selectFighter(FighterConfig fighter) {
    selectedFighterNotifier.value = fighter;
  }
}

