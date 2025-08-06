import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';

// 이미지 확대 다이얼로그 위젯
class ImageZoomDialog extends StatelessWidget {
  final String imagePath;
  final String title;

  const ImageZoomDialog({
    super.key,
    required this.imagePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: ValueKey('image_zoom_dialog_$title'),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // 이미지
            Expanded(
              child: InteractiveViewer(
                child: Center(
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '이미지를 불러올 수 없습니다',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  int _currentPage = 0;
  late PageController _pageController;

  final List<HelpItem> helpItems = [
    HelpItem(
      title: '따라우송 사용법',
      description: '우송대학교 캠퍼스 네비게이터로\n캠퍼스 생활을 더욱 편리하게 만들어보세요',
      imagePath: '', // 첫 번째 슬라이드는 이미지 없음
      icon: Icons.help_outline,
      color: const Color(0xFF1E3A8A),
      isIntro: true, // 소개 슬라이드 표시
    ),
    HelpItem(
      title: '세부 검색',
      description: '건물명, 강의실 번호, 편의시설까지\n정확하고 빠른 검색으로 원하는 곳을 찾아보세요',
      imagePath: 'lib/asset/1.png',
      icon: Icons.search,
      color: const Color(0xFF3B82F6),
      isIntro: false,
    ),
    HelpItem(
      title: '시간표 연동',
      description: '수업 시간표를 앱에 연동하여\n다음 수업까지의 최적 경로를 자동으로 안내받으세요',
      imagePath: 'lib/asset/2.png',
      icon: Icons.schedule,
      color: const Color(0xFF10B981),
      isIntro: false,
    ),
    HelpItem(
      title: '길찾기',
      description: '캠퍼스 내 정확한 경로 안내로\n목적지까지 쉽고 빠르게 도착하세요',
      imagePath: 'lib/asset/3.png',
      icon: Icons.directions,
      color: const Color(0xFFF59E0B),
      isIntro: false,
    ),
    HelpItem(
      title: '건물 내부 도면',
      description: '건물 내부의 상세한 도면으로\n강의실과 편의시설을 쉽게 찾아보세요',
      imagePath: 'lib/asset/4.png',
      icon: Icons.map,
      color: const Color(0xFF8B5CF6),
      isIntro: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.help),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 페이지뷰 영역
              Expanded(
                child: PageView.builder(
                  key: const ValueKey('help_page_view'),
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: helpItems.length,
                  itemBuilder: (context, index) {
                    final item = helpItems[index];
                    return _buildHelpCard(item, index);
                  },
                ),
              ),

              // 페이지 인디케이터
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    helpItems.length,
                    (index) => Container(
                      width: index == _currentPage ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: index == _currentPage
                            ? const Color(0xFF1E3A8A)
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),

              // 하단 버튼
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // 이전 버튼
                    if (_currentPage > 0)
                      Expanded(
                        child: Container(
                          height: 50,
                          margin: const EdgeInsets.only(right: 8),
                          child: OutlinedButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF1E3A8A)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '이전',
                              style: TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 다음/완료 버튼
                    Expanded(
                      child: Container(
                        height: 50,
                        margin: EdgeInsets.only(left: _currentPage > 0 ? 8 : 0),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage < helpItems.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentPage < helpItems.length - 1 ? '다음' : '완료',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpCard(HelpItem item, int index) {
    return Container(
      key: ValueKey('help_card_$index'),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: item.isIntro
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 아이콘
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: Icon(item.icon, size: 60, color: item.color),
                    ),
                    const SizedBox(height: 40),

                    // 제목
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // 설명
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF4B5563),
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 상단 이미지 영역
                  Expanded(flex: 3, child: _buildImageContent(item)),

                  // 하단 텍스트 영역
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 아이콘과 제목 행
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: item.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 24,
                                  color: item.color,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 설명 텍스트
                          Expanded(
                            child: Text(
                              item.description,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF4B5563),
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildImageContent(HelpItem item) {
    return GestureDetector(
      key: ValueKey('image_content_${item.title}'),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) =>
              ImageZoomDialog(imagePath: item.imagePath, title: item.title),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      item.color.withOpacity(0.1),
                      item.color.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          item.color.withOpacity(0.1),
                          item.color.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '이미지를 불러올 수 없습니다',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 확대 아이콘 오버레이
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.zoom_in, color: item.color, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpItem {
  final String title;
  final String description;
  final String imagePath;
  final IconData icon;
  final Color color;
  final bool isIntro;

  HelpItem({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.icon,
    required this.color,
    this.isIntro = false,
  });
}
