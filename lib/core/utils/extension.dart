/// Chứa các Extension methods hữu ích giúp mở rộng chức năng cho các kiểu dữ liệu có sẵn.
library;

extension StringExtension on String {
  /// Viết hoa chữ cái đầu tiên của chuỗi
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

