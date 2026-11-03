import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../data/robot_battle_html.dart';
import '../../../character_3d/data/selected_fighter_service.dart';

/// Màn hình Game 3D Three.js PvP Battle & Physics (Tab 3).
/// Đã được nâng cấp toàn diện:
/// - Đồng bộ trực tiếp tướng chọn từ Tab 2 (Tên, Màu, Máu, Sức mạnh, Tốc độ).
/// - Hệ thống Kỹ Năng Đấu Võ: Đấm (Punch), Lướt Tốc Biến (Dash), Siêu Tuyệt Kỹ (Ultimate).
/// - Hệ thống âm thanh Synthesizer chân thực.
/// - Đấu trường Cyberpunk Neon 3D + Bản đồ .GLB.
class ThreeJsGameScreen extends StatefulWidget {
  const ThreeJsGameScreen({super.key});

  @override
  State<ThreeJsGameScreen> createState() => _ThreeJsGameScreenState();
}

class _ThreeJsGameScreenState extends State<ThreeJsGameScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentFighterId = '';

  @override
  void initState() {
    super.initState();
    final fighter = SelectedFighterService.instance.currentFighter;
    _currentFighterId = fighter.id;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF050811))
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
      ..loadHtmlString(RobotBattleHtml.getContent(fighter: fighter));

    SelectedFighterService.instance.selectedFighterNotifier.addListener(_onFighterChanged);
  }

  @override
  void dispose() {
    SelectedFighterService.instance.selectedFighterNotifier.removeListener(_onFighterChanged);
    super.dispose();
  }

  void _onFighterChanged() {
    final fighter = SelectedFighterService.instance.currentFighter;
    if (fighter.id != _currentFighterId) {
      _currentFighterId = fighter.id;
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
        _controller.loadHtmlString(RobotBattleHtml.getContent(fighter: fighter));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fighter = SelectedFighterService.instance.currentFighter;

    return Scaffold(
      backgroundColor: const Color(0xFF050811),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Cyber Arena 3D',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: fighter.themeColor.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: fighter.themeColor, width: 1.2),
              ),
              child: Text(
                fighter.name,
                style: TextStyle(
                  color: fighter.themeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00E5FF)),
            tooltip: 'Tải lại Đấu Trường',
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _controller.loadHtmlString(RobotBattleHtml.getContent(fighter: SelectedFighterService.instance.currentFighter));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: const Color(0xFF050811),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF00E5FF)),
                    const SizedBox(height: 16),
                    Text(
                      'Khởi tạo Đấu Trường 3D & Chiến Binh [${fighter.name}]...',
                      style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold),
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
