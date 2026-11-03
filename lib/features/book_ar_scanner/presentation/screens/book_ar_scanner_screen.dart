import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../../core/utils/ar_launcher.dart';
import '../../data/models/book_3d_model.dart';

/// Tab 2: Thư Viện Sách & IKEA 3D Showroom (Interactive 3D Catalog).
/// Hoạt động an toàn 100%, không xung đột ARCore SurfaceView.
/// Tính năng:
/// 1. Khám phá mô hình 3D 360 độ (Bản đồ du lịch Barcelona, Ghế IKEA, Bàn Smart Desk, Sách Pop-up).
/// 2. Bảng đổi màu sắc & chất liệu thời gian thực (IKEA Customizer).
/// 3. Các điểm mốc POI 3D tương tác của Barcelona.
/// 4. Nút "MỞ CAMERA AR QUÉT & GHI ĐÈ LÊN SÁCH (TAB 1 AR STUDIO)": Chuyển ngay sang Camera AR thật để ghim đè lên sách ngoài đời.
/// 5. Nút "CHIẾU GOOGLE AR SCENE VIEWER NGOÀI ĐỜI": Chiếu thẳng vật thể ra sàn nhà thật tỉ lệ 1:1.
class BookArScannerScreen extends StatefulWidget {
  final ValueChanged<int>? onSwitchToArCamera;

  const BookArScannerScreen({super.key, this.onSwitchToArCamera});

  @override
  State<BookArScannerScreen> createState() => _BookArScannerScreenState();
}

class _BookArScannerScreenState extends State<BookArScannerScreen> {
  int _selectedBookIndex = 0;
  Book3dModel get _currentBook => Book3dModel.sampleBooks[_selectedBookIndex];

  BookPoiModel? _selectedPoi;
  int _selectedColorVariantIndex = 0;
  bool _autoRotate = true;

  @override
  void initState() {
    super.initState();
    if (_currentBook.pois.isNotEmpty) {
      _selectedPoi = _currentBook.pois.first;
    }
  }

  void _selectBook(int index) {
    if (index != _selectedBookIndex) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedBookIndex = index;
        _selectedColorVariantIndex = 0;
        _selectedPoi = _currentBook.pois.isNotEmpty
            ? _currentBook.pois.first
            : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = _currentBook;

    return Scaffold(
      backgroundColor: const Color(0xFF050811),
      appBar: AppBar(
        title: Text(
          book.isShowroom ? 'IKEA 3D Showroom' : 'AR Sách & Bản Đồ 3D',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _autoRotate ? 'Dừng xoay' : 'Tự xoay 360°',
            icon: Icon(
              _autoRotate
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
            ),
            onPressed: () {
              setState(() {
                _autoRotate = !_autoRotate;
              });
            },
          ),
          IconButton(
            tooltip: 'Chiếu Google AR 6DoF',
            icon: const Icon(Icons.view_in_ar, color: Color(0xFF00E5FF)),
            onPressed: () {
              ArLauncher.launchAr(
                context: context,
                modelUrl: book.model3dUrl,
                title: '${book.title} (AR 3D)',
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. TRÌNH XEM MÔ HÌNH 3D TƯƠNG TÁC 360 ĐỘ (MODEL VIEWER)
          Positioned.fill(
            child: ModelViewer(
              key: ValueKey('book_mv_${book.id}_$_selectedColorVariantIndex'),
              backgroundColor: const Color(0xFF070B14),
              src: book.model3dUrl,
              alt: book.title,
              ar: true,
              arModes: const ['scene-viewer', 'webxr', 'quick-look'],
              autoRotate: _autoRotate,
              cameraControls: true,
              disableZoom: false,
            ),
          ),

          // 2. THANH CHỌN MẪU SÁCH / BẢN ĐỒ / SHOWROOM TRÊN ĐẦU
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: SafeArea(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(Book3dModel.sampleBooks.length, (
                    index,
                  ) {
                    final item = Book3dModel.sampleBooks[index];
                    final isSel = index == _selectedBookIndex;

                    return GestureDetector(
                      onTap: () => _selectBook(index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSel
                              ? (item.isShowroom
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF00E5FF))
                                    .withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel
                                ? (item.isShowroom
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF00E5FF))
                                : Colors.white24,
                            width: isSel ? 2.0 : 1.0,
                          ),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color:
                                        (item.isShowroom
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF00E5FF))
                                            .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.isShowroom
                                  ? Icons.chair
                                  : Icons.auto_stories,
                              color: isSel
                                  ? (item.isShowroom
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF00E5FF))
                                  : Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.title,
                              style: TextStyle(
                                color: isSel ? Colors.white : Colors.white70,
                                fontSize: 11.5,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),

          // 3. BẢNG ĐIỀU KHIỂN DƯỚI ĐÁY: THÔNG TIN, TÙY BIẾN IKEA & NÚT MỞ CAMERA AR
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.44,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xF2080D1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: book.isShowroom
                        ? const Color(0xFF10B981)
                        : const Color(0xFF00E5FF),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x6600E5FF), blurRadius: 18),
                    BoxShadow(color: Colors.black, blurRadius: 24),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TIÊU ĐỀ & KÍCH THƯỚC
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${book.category}  •  ${book.dimensions}',
                                  style: TextStyle(
                                    color: book.isShowroom
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF00E5FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${book.rating}',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // TÍNH NĂNG 1: DÀNH CHO DẠNG IKEA SHOWROOM (BẢNG ĐỔI MÀU & CHẤT LIỆU THỜI GIAN THỰC)
                      if (book.isShowroom && book.colorVariants.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'CHẤT LIỆU & MÀU SẮC (IKEA CUSTOMIZER):',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              book
                                  .colorVariants[_selectedColorVariantIndex]
                                  .name,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(book.colorVariants.length, (
                            idx,
                          ) {
                            final variant = book.colorVariants[idx];
                            final isSel = idx == _selectedColorVariantIndex;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedColorVariantIndex = idx;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: variant.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel
                                        ? Colors.white
                                        : Colors.white24,
                                    width: isSel ? 2.5 : 1.0,
                                  ),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: variant.color.withValues(
                                              alpha: 0.7,
                                            ),
                                            blurRadius: 10,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSel
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // TÍNH NĂNG 2: DÀNH CHO DẠNG AR BẢN ĐỒ DU LỊCH 3D POP-UP (CÁC ĐIỂM GHIM POI)
                      if (!book.isShowroom && book.pois.isNotEmpty) ...[
                        const Text(
                          'ĐIỂM MỐC 3D NỔI TRÊN BẢN ĐỒ (CHẠM ĐỂ CHỌN):',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: book.pois.map((poi) {
                              final isSel = _selectedPoi?.id == poi.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  avatar: Icon(
                                    Icons.place,
                                    size: 14,
                                    color: isSel
                                        ? Colors.black
                                        : const Color(0xFF00E5FF),
                                  ),
                                  label: Text(
                                    poi.name,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSel,
                                  selectedColor: const Color(0xFF00E5FF),
                                  backgroundColor: const Color(0xFF1E293B),
                                  labelStyle: TextStyle(
                                    color: isSel ? Colors.black : Colors.white,
                                  ),
                                  onSelected: (_) {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _selectedPoi = poi;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        if (_selectedPoi != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF00E5FF)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              _selectedPoi!.description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                      ],

                      // NÚT BẬT CAMERA AR 6DOF CHIẾU TRỰC TIẾP LÊN SÁCH / BẢN ĐỒ NGOÀI ĐỜI
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: book.isShowroom
                                ? const Color(0xFF10B981)
                                : const Color(0xFF00E5FF),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 6,
                          ),
                          icon: const Icon(Icons.camera_alt, size: 20),
                          label: Text(
                            book.isShowroom
                                ? 'MỞ CAMERA AR ƯỚM VÀO PHÒNG BẠN (1:1)'
                                : 'MỞ CAMERA AR QUÉT & CHIẾU LÊN SÁCH THẬT',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            final targetIndex = book.isShowroom ? 4 : (book.id == 'barcelona_ar_map' ? 3 : 5);
                            if (widget.onSwitchToArCamera != null) {
                              widget.onSwitchToArCamera!(targetIndex);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
