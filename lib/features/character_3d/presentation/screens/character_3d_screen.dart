import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../../core/utils/ar_launcher.dart';

/// Dữ liệu một Nhân vật 3D trong Studio
class CharacterData {
  final String id;
  final String name;
  final String role;
  final String description;
  final String modelUrl;
  final int speed;
  final int power;
  final int hp;
  final Color themeColor;
  final IconData icon;

  const CharacterData({
    required this.id,
    required this.name,
    required this.role,
    required this.description,
    required this.modelUrl,
    required this.speed,
    required this.power,
    required this.hp,
    required this.themeColor,
    required this.icon,
  });
}

/// Tab 2: Phòng Chọn Nhân Vật 3D (Character Selection Studio).
/// Cho phép:
/// - Duyệt qua danh sách các nhân vật 3D chất lượng cao (Robot Expressive, Phi Hành Gia Apollo, Crimson Mecha, Cáo Thần Fox).
/// - Xoay 360 độ, phóng to thu nhỏ tương tác trực tiếp.
/// - Xem chỉ số sức mạnh: Tốc độ, Lực đánh, Máu.
/// - Chọn làm tướng chiến đấu chính.
/// - Đưa trực tiếp nhân vật ra sàn nhà thực tế bằng AR Scene Viewer.
class Character3DScreen extends StatefulWidget {
  const Character3DScreen({super.key});

  @override
  State<Character3DScreen> createState() => _Character3DScreenState();
}

class _Character3DScreenState extends State<Character3DScreen> {
  int _selectedCharacterIndex = 0;
  int _selectedActiveFighterIndex = 0; // Tướng đang được kích hoạt chiến đấu
  bool _autoRotate = true;
  int _selectedBgIndex = 0;

  static const List<CharacterData> characters = [
    CharacterData(
      id: 'robot_expressive',
      name: 'Robot Cyber Titan',
      role: 'Đấu Sĩ Toàn Diện',
      description: 'Robot chiến đấu đa năng với bộ khung hợp kim Titan, cú đấm tên lửa và hoạt ảnh biểu cảm phong phú.',
      modelUrl: 'https://raw.githubusercontent.com/mrdoob/three.js/master/examples/models/gltf/RobotExpressive/RobotExpressive.glb',
      speed: 85,
      power: 90,
      hp: 100,
      themeColor: Color(0xFF00E5FF),
      icon: Icons.smart_toy,
    ),
    CharacterData(
      id: 'astronaut_apollo',
      name: 'Phi Hành Gia Apollo',
      role: 'Tiên Phong Vũ Trụ',
      description: 'Nhà thám hiểm không gian trang bị bộ đồ du hành phản trọng lực và kính mũ tráng gương phản chiếu thực tế.',
      modelUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
      speed: 75,
      power: 82,
      hp: 120,
      themeColor: Color(0xFFF59E0B),
      icon: Icons.rocket_launch,
    ),
    CharacterData(
      id: 'crimson_mecha',
      name: 'Crimson Fury Mecha',
      role: 'Sát Thương Bạo Kích',
      description: 'Chiến giáp cận chiến màu đỏ thẫm với tốc độ vung đòn vũ bão và lực đẩy xung kích cực lớn.',
      modelUrl: 'https://raw.githubusercontent.com/mrdoob/three.js/master/examples/models/gltf/RobotExpressive/RobotExpressive.glb',
      speed: 95,
      power: 98,
      hp: 85,
      themeColor: Color(0xFFEF4444),
      icon: Icons.local_fire_department,
    ),
    CharacterData(
      id: 'cyber_fox',
      name: 'Cáo Thần Không Gian',
      role: 'Thích Khách Siêu Tốc',
      description: 'Linh thú thần thoại di chuyển với tốc độ âm thanh, khả năng né đòn và rình rập đối phương siêu việt.',
      modelUrl: 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Fox/glTF-Binary/Fox.glb',
      speed: 100,
      power: 70,
      hp: 75,
      themeColor: Color(0xFFA855F7),
      icon: Icons.pets,
    ),
  ];

  static const List<Color> _bgColors = [
    Color(0xFF070B14), // Cyber Deep Black
    Color(0xFF0F172A), // Slate Dark
    Color(0xFF1E1B4B), // Violet Cyber
    Color(0xFFF1F5F9), // Studio Light
  ];

  void _selectCharacter(int index) {
    if (index != _selectedCharacterIndex) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedCharacterIndex = index;
      });
    }
  }

  void _confirmChooseFighter() {
    HapticFeedback.heavyImpact();
    setState(() {
      _selectedActiveFighterIndex = _selectedCharacterIndex;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🔥 Đã chọn "${characters[_selectedCharacterIndex].name}" làm Tướng Chiến Đấu!',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: characters[_selectedCharacterIndex].themeColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentBgColor = _bgColors[_selectedBgIndex];
    final isDarkBg = currentBgColor != const Color(0xFFF1F5F9);
    final character = characters[_selectedCharacterIndex];
    final isCurrentFighter = _selectedActiveFighterIndex == _selectedCharacterIndex;

    return Scaffold(
      backgroundColor: currentBgColor,
      appBar: AppBar(
        title: const Text('Phòng Chọn Nhân Vật 3D', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: isDarkBg ? Colors.black87 : Colors.white,
        foregroundColor: isDarkBg ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _autoRotate ? 'Dừng xoay' : 'Bật tự xoay 360°',
            icon: Icon(_autoRotate ? Icons.pause_circle_outline : Icons.play_circle_outline),
            onPressed: () {
              setState(() {
                _autoRotate = !_autoRotate;
              });
            },
          ),
          IconButton(
            tooltip: 'Đưa nhân vật ra sàn nhà (AR)',
            icon: const Icon(Icons.view_in_ar, color: Color(0xFF00E5FF), size: 26),
            onPressed: () {
              ArLauncher.launchAr(
                context: context,
                modelUrl: character.modelUrl,
                title: character.name,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // TRÌNH XEM MÔ HÌNH 3D XOAY 360 ĐỘ
          Positioned.fill(
            child: ModelViewer(
              key: ValueKey(character.id + currentBgColor.toString()),
              backgroundColor: currentBgColor,
              src: character.modelUrl,
              alt: character.name,
              ar: true,
              arModes: const ['scene-viewer', 'webxr', 'quick-look'],
              autoRotate: _autoRotate,
              cameraControls: true,
              disableZoom: false,
            ),
          ),

          // THANH CHỌN TƯỚNG TRÊN ĐẦU
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(characters.length, (index) {
                  final char = characters[index];
                  final isSelected = index == _selectedCharacterIndex;
                  final isFighter = index == _selectedActiveFighterIndex;

                  return GestureDetector(
                    onTap: () => _selectCharacter(index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? char.themeColor.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? char.themeColor : Colors.white24,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: char.themeColor.withValues(alpha: 0.4), blurRadius: 10)]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(char.icon, color: char.themeColor, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            char.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (isFighter) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('ĐANG DÙNG', style: TextStyle(color: Colors.greenAccent, fontSize: 8.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // BẢNG THÔNG TIN CHỈ SỐ & NÚT HÀNH ĐỘNG DƯỚI ĐÁY
          Positioned(
            bottom: 16,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xE60A0F1D),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: character.themeColor.withValues(alpha: 0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 20),
                  BoxShadow(color: character.themeColor.withValues(alpha: 0.25), blurRadius: 12),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÊN VÀ CLASS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            character.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            character.role,
                            style: TextStyle(
                              color: character.themeColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      // CHỌN MÀU NỀN STUDIO
                      Row(
                        children: List.generate(_bgColors.length, (idx) {
                          final isBgSel = idx == _selectedBgIndex;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedBgIndex = idx),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _bgColors[idx],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isBgSel ? const Color(0xFF00E5FF) : Colors.white24,
                                  width: isBgSel ? 2 : 1,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // MÔ TẢ NGẮN
                  Text(
                    character.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // THANH CHỈ SỐ: TỐC ĐỘ, LỰC ĐÁNH, MÁU
                  _buildStatBar('Tốc độ', character.speed, const Color(0xFF38BDF8)),
                  const SizedBox(height: 4),
                  _buildStatBar('Lực đánh', character.power, const Color(0xFFEF4444)),
                  const SizedBox(height: 4),
                  _buildStatBar('Máu (HP)', character.hp, const Color(0xFF10B981)),
                  const SizedBox(height: 14),

                  // HÀNG NÚT BẤM: CHỌN TƯỚNG & XEM AR
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCurrentFighter ? Colors.white24 : character.themeColor,
                            foregroundColor: isCurrentFighter ? Colors.white : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: Icon(isCurrentFighter ? Icons.check_circle : Icons.flash_on, size: 18),
                          label: Text(
                            isCurrentFighter ? 'ĐANG CHỌN TƯỚNG NÀY' : 'CHỌN CHIẾN BINH NÀY',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          onPressed: isCurrentFighter ? null : _confirmChooseFighter,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF00E5FF),
                            side: const BorderSide(color: Color(0xFF00E5FF)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.view_in_ar, size: 18),
                          label: const Text('ĐẶT RA SÀN (AR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          onPressed: () {
                            ArLauncher.launchAr(
                              context: context,
                              modelUrl: character.modelUrl,
                              title: character.name,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 65,
          child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 120,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$value', style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
