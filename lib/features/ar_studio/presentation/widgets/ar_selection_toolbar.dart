import 'package:flutter/material.dart';

/// Component Thanh Dock chọn loại vật thể / Dashboard AR muốn đặt lên sàn.
/// Thiết kế giao diện công nghệ cao (Sci-Fi Cyber), sử dụng Icon chuyên nghiệp, không emoji.
class ArSelectionToolbar extends StatelessWidget {
  final List<String> shapeNames;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const ArSelectionToolbar({
    super.key,
    required this.shapeNames,
    required this.selectedIndex,
    required this.onSelect,
  });

  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard_customize_outlined;
      case 1:
        return Icons.smart_toy_outlined;
      case 2:
        return Icons.image_outlined;
      case 3:
        return Icons.map_outlined;
      case 4:
        return Icons.chair_outlined;
      case 5:
        return Icons.menu_book;
      case 6:
        return Icons.blur_on;
      case 7:
        return Icons.view_in_ar;
      case 8:
        return Icons.lens;
      case 9:
        return Icons.flight_takeoff;
      default:
        return Icons.layers_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xF2080E1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 16),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              children: [
                Icon(Icons.tune, color: Color(0xFF00E5FF), size: 14),
                SizedBox(width: 6),
                Text(
                  'DANH MỤC VẬT THỂ AR 3D KHÔNG GIAN',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shapeNames.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == selectedIndex;
                final icon = _getIconForIndex(index);

                return ChoiceChip(
                  avatar: Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.black : const Color(0xFF00E5FF),
                  ),
                  label: Text(
                    shapeNames[index],
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF00E5FF),
                  backgroundColor: const Color(0xFF131D31),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF00E5FF) : Colors.white12,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (_) => onSelect(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
