import 'package:flutter/material.dart';

/// Component Banner hướng dẫn và hiển thị trạng thái phát hiện mặt phẳng ARCore.
class ArInstructionBanner extends StatelessWidget {
  final int placedCount;
  final bool isPlaneDetected;

  const ArInstructionBanner({
    super.key,
    required this.placedCount,
    required this.isPlaneDetected,
  });

  @override
  Widget build(BuildContext context) {
    // Đổi màu viền và icon tùy theo đã tìm thấy mặt phẳng hay chưa
    final Color statusColor = isPlaneDetected
        ? const Color(0xFF00E676) // Xanh lá sáng: Đã khóa được mặt phẳng
        : const Color(0xFFFF9100); // Cam/Amber: Đang quét tìm mặt phẳng

    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isPlaneDetected
                  ? Icons.check_circle_outline_rounded
                  : Icons.radar_rounded,
              color: statusColor,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                !isPlaneDetected
                    ? '🔍 Đang quét... Hãy lia camera CHẬM xuống sàn/bàn có vân gỗ/họa tiết để khóa mặt phẳng.'
                    : (placedCount == 0
                        ? '✅ ĐÃ TÌM THẤY MẶT PHẲNG! Hãy chạm ngón tay vào vùng có lưới chấm để ghim.'
                        : '🎯 Đã ghim $placedCount đối tượng! Bạn có thể bước đi vòng quanh để ngắm nhìn.'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
