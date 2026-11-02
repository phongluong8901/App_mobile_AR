import 'package:flutter/material.dart';

/// Component Thanh Dock chọn loại vật thể / Dashboard AR muốn đặt lên sàn.
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.88),
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
              'Chọn đối tượng muốn ghim vào không gian:',
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
              itemCount: shapeNames.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == selectedIndex;
                return ChoiceChip(
                  label: Text(
                    shapeNames[index],
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: index == 0
                      ? const Color(0xFF00E5FF)
                      : Colors.amber,
                  backgroundColor: Colors.white10,
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

