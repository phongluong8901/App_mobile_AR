import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../data/robot_battle_html.dart';

/// Màn hình Game 3D Three.js PvP Battle & Physics (Tab 3).
/// Đã được tái cấu trúc thư mục sạch sẽ, module hóa:
/// - Mã nguồn HTML/WebGL/Three.js được tách riêng tại `RobotBattleHtml`.
/// - Widget Flutter ngắn gọn, dễ đọc, dễ mở rộng và bảo trì.
class ThreeJsGameScreen extends StatefulWidget {
  const ThreeJsGameScreen({super.key});

  @override
  State<ThreeJsGameScreen> createState() => _ThreeJsGameScreenState();
}

class _ThreeJsGameScreenState extends State<ThreeJsGameScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF070B14))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadHtmlString(RobotBattleHtml.content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        title: const Text('Robot 3D Battle Arena', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại Game',
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: const Color(0xFF070B14),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00E5FF)),
                    SizedBox(height: 16),
                    Text(
                      'Khởi tạo Đấu Trường 3D & 2 Robot PvP...',
                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

