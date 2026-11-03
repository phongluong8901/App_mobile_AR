import 'package:flutter/material.dart';

/// Model dữ liệu Điểm Mốc Du Lịch 3D (POI - Point of Interest) nổi trên Bản đồ/Trang sách
class BookPoiModel {
  final String id;
  final String name;
  final String description;
  final double posX;
  final double posY;

  const BookPoiModel({
    required this.id,
    required this.name,
    required this.description,
    required this.posX,
    required this.posY,
  });
}

/// Tùy biến chất liệu / màu sắc cho Showroom nội thất 3D kiểu IKEA
class ShowroomColorVariant {
  final String name;
  final Color color;
  final String hex;

  const ShowroomColorVariant({
    required this.name,
    required this.color,
    required this.hex,
  });
}

/// Model dữ liệu thông tin và mô hình 3D của Cuốn Sách & Bản Đồ AR (AR Book, Map & IKEA Showroom Explorer)
class Book3dModel {
  final String id;
  final String title;
  final String author;
  final String category;
  final double rating;
  final int publishYear;
  final int pages;
  final String description;
  final String coverUrl;
  final String model3dUrl;
  final String themeColorHex;
  final List<BookPoiModel> pois;
  final bool isShowroom;
  final String dimensions;
  final List<ShowroomColorVariant> colorVariants;

  const Book3dModel({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.rating,
    required this.publishYear,
    required this.pages,
    required this.description,
    required this.coverUrl,
    required this.model3dUrl,
    required this.themeColorHex,
    this.pois = const [],
    this.isShowroom = false,
    this.dimensions = '1:1 True-Scale',
    this.colorVariants = const [],
  });

  static const List<Book3dModel> sampleBooks = [
    // 1. DẠNG 1: AR BẢN ĐỒ DU LỊCH 3D POP-UP (CHUẨN VIDEO BARCELONA MAP)
    Book3dModel(
      id: 'barcelona_ar_map',
      title: 'Bản Đồ AR Barcelona (Tourist 3D Map)',
      author: 'Barcelona Tourism Board',
      category: 'Bản Đồ Du Lịch AR 3D Pop-Up',
      rating: 5.0,
      publishYear: 2026,
      pages: 1,
      description: 'Mô phỏng trải nghiệm Web AR Barcelona: Khi lia camera vào bản đồ giấy, các kỳ quan kiến trúc và địa danh nổi tiếng sẽ mọc thẳng đứng lên từ mặt giấy kèm các điểm ghim POI tương tác.',
      coverUrl: 'https://images.unsplash.com/photo-1583422409516-2895a77efded?w=600',
      model3dUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
      themeColorHex: '#00E5FF',
      dimensions: 'Bản đồ du lịch A3',
      pois: [
        BookPoiModel(
          id: 'poi_sagrada',
          name: 'Vương Cung Thánh Đường Sagrada Família',
          description: 'Kiệt tác vĩ đại của kiến trúc sư Antoni Gaudí với các ngọn tháp vươn cao hùng vĩ.',
          posX: 0.5,
          posY: 0.35,
        ),
        BookPoiModel(
          id: 'poi_guell',
          name: 'Công Viên Park Güell',
          description: 'Khu vườn kiến trúc mosaic đầy màu sắc độc nhất vô nhị trên sườn đồi Carmelo.',
          posX: 0.25,
          posY: 0.55,
        ),
        BookPoiModel(
          id: 'poi_rambla',
          name: 'Đại Lộ La Rambla & Chợ Boqueria',
          description: 'Tuyến phố đi bộ sầm uất trái tim Barcelona với ẩm thực Tapas truyền thống.',
          posX: 0.72,
          posY: 0.65,
        ),
      ],
    ),

    // 2. DẠNG 2: AR IKEA 3D SHOWROOM & CATALOGUE CUSTOMIZER (CHUẨN VIDEO IKEA VR/AR)
    Book3dModel(
      id: 'ikea_lounge_chair',
      title: 'IKEA Showroom: Ghế Thư Giãn Bắc Âu',
      author: 'IKEA Design Lab Sweden',
      category: 'IKEA 3D AR Showroom & Catalogue',
      rating: 4.9,
      publishYear: 2026,
      pages: 1,
      description: 'Trải nghiệm IKEA VR/AR Showroom: Quét trang catalogue để khởi chiếu nội thất 3D. Tự do thay đổi chất liệu, màu sắc thời gian thực và đặt thử chuẩn tỉ lệ 1:1 vào góc phòng của bạn.',
      coverUrl: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600',
      model3dUrl: 'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/SheenChair/glTF-Binary/SheenChair.glb',
      themeColorHex: '#38BDF8',
      isShowroom: true,
      dimensions: '82 x 78 x 95 cm (Tỉ lệ thật 1:1)',
      colorVariants: [
        ShowroomColorVariant(name: 'Gỗ Sồi & Xám Bắc Âu', color: Color(0xFF64748B), hex: '#64748B'),
        ShowroomColorVariant(name: 'Cam Amber Da Bò', color: Color(0xFFF59E0B), hex: '#F59E0B'),
        ShowroomColorVariant(name: 'Xanh Navy Hoàng Gia', color: Color(0xFF0284C7), hex: '#0284C7'),
        ShowroomColorVariant(name: 'Đỏ Ruby Quý Phái', color: Color(0xFFE11D48), hex: '#E11D48'),
        ShowroomColorVariant(name: 'Đen Titan Cyber', color: Color(0xFF0F172A), hex: '#0F172A'),
      ],
      pois: [
        BookPoiModel(
          id: 'poi_cushion',
          name: 'Đệm Mút Hoạt Tính Foam',
          description: 'Đệm mút đàn hồi cao chống lún xẹp, bọc vải nỉ cao cấp thoáng khí.',
          posX: 0.5,
          posY: 0.45,
        ),
        BookPoiModel(
          id: 'poi_legs',
          name: 'Chân Hợp Kim Sơn Tĩnh Điện',
          description: 'Khung chân thép chịu lực 150kg, đế chống trầy xước sàn gỗ.',
          posX: 0.5,
          posY: 0.8,
        ),
      ],
    ),

    // 3. DẠNG 2: IKEA SMART DESK & WORKSPACE
    Book3dModel(
      id: 'ikea_smart_desk',
      title: 'IKEA Showroom: Bàn Nâng Hạ Smart Desk',
      author: 'IKEA Ergonomics Studio',
      category: 'IKEA 3D AR Showroom & Workspace',
      rating: 5.0,
      publishYear: 2026,
      pages: 1,
      description: 'Mô phỏng không gian làm việc hiện đại. Thay đổi màu sắc mặt bàn, kiểm tra chiều cao nâng hạ điện tử và ướm thử vị trí trong phòng làm việc thực tế ngoài đời.',
      coverUrl: 'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=600',
      model3dUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
      themeColorHex: '#10B981',
      isShowroom: true,
      dimensions: '140 x 70 x 65-125 cm',
      colorVariants: [
        ShowroomColorVariant(name: 'Gỗ Óc Chó Walnut', color: Color(0xFF854D0E), hex: '#854D0E'),
        ShowroomColorVariant(name: 'Trắng Sứ Ceramic', color: Color(0xFFF8FAFC), hex: '#F8FAFC'),
        ShowroomColorVariant(name: 'Đen Nhám Carbon', color: Color(0xFF1E293B), hex: '#1E293B'),
      ],
      pois: [
        BookPoiModel(
          id: 'poi_motor',
          name: 'Động Cơ Kép Dual-Motor',
          description: 'Nâng hạ êm ái < 45dB, nhớ 4 vị trí chiều cao thông minh.',
          posX: 0.3,
          posY: 0.6,
        ),
      ],
    ),

    // 4. DẠNG 1: SÁCH 3D POP-UP NỔI
    Book3dModel(
      id: 'dac_nhan_tam',
      title: 'Đắc Nhân Tâm (3D Pop-up Book)',
      author: 'Dale Carnegie',
      category: 'Sách 3D Pop-Up Giáo Dục',
      rating: 4.9,
      publishYear: 1936,
      pages: 320,
      description: 'Tác phẩm kinh điển thế giới. Khi mở trang sách, biểu tượng trái tim kết nối và các chỉ dẫn giao tiếp mọc nổi lên từ trang sách.',
      coverUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=600',
      model3dUrl: 'https://raw.githubusercontent.com/mrdoob/three.js/master/examples/models/gltf/RobotExpressive/RobotExpressive.glb',
      themeColorHex: '#F59E0B',
      dimensions: 'Khổ sách 14.5 x 20.5 cm',
      pois: [
        BookPoiModel(
          id: 'poi_chap1',
          name: 'Chương 1: Thu Phục Lòng Người',
          description: 'Không chỉ trích, oán trách hay than phiền người khác.',
          posX: 0.3,
          posY: 0.4,
        ),
      ],
    ),
  ];
}
