import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentPage = 0;
  late PageController _pageController;
  bool _dontShowAgain = false;

  final List<TutorialItem> tutorialItems = [
    TutorialItem(
      title: '따라우송 사용법',
      description: '우송대학교 캠퍼스 네비게이터로\n캠퍼스 생활을 더욱 편리하게 만들어보세요',
      imagePath: '',
      icon: Icons.help_outline,
      color: const Color(0xFF1E3A8A),
      isIntro: true,
    ),
    TutorialItem(
      title: '디테일한 검색 기능',
      description: '우송대에서는 건물뿐만이 아닌 강의실도 검색이 가능해요!\n강의실의 위치부터 편의시설까지 디테일하게 검색해 보세요 😊',
      imagePath: 'lib/asset/1.png',
      icon: Icons.search,
      color: const Color(0xFF3B82F6),
      isIntro: false,
    ),
    TutorialItem(
      title: '시간표 연동',
      description: '수업 시간표를 앱에 연동하여\n다음 수업까지의 최적 경로를 자동으로 안내받으세요',
      imagePath: 'lib/asset/2.png',
      icon: Icons.schedule,
      color: const Color(0xFF10B981),
      isIntro: false,
    ),
    TutorialItem(
      title: '길찾기',
      description: '캠퍼스 내 정확한 경로 안내로\n목적지까지 쉽고 빠르게 도착하세요',
      imagePath: 'lib/asset/3.png',
      icon: Icons.directions,
      color: const Color(0xFFF59E0B),
      isIntro: false,
    ),
    TutorialItem(
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
    final isLastPage = _currentPage == tutorialItems.length - 1;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더 (뒤로가기 버튼 없음)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.tutorial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            
            // 페이지뷰 (중앙에 위치)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: tutorialItems.length,
                itemBuilder: (context, index) {
                  return _buildTutorialPage(tutorialItems[index]);
                },
              ),
            ),
            
            // 페이지 인디케이터 (아래쪽에 위치)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  tutorialItems.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentPage 
                          ? const Color(0xFF1E3A8A) 
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            
            // 하단 버튼 영역
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 다시 보지 않기 체크박스 (마지막 페이지에서만 표시)
                  if (isLastPage)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _dontShowAgain,
                            onChanged: (value) {
                              setState(() {
                                _dontShowAgain = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFF1E3A8A),
                          ),
                          const Text(
                            '다시 보지 않기',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // 돌아가기 버튼 (마지막 페이지에서만 활성화)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLastPage ? () {
                        Navigator.of(context).pop();
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLastPage 
                            ? const Color(0xFF1E3A8A)
                            : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '돌아가기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isLastPage ? Colors.white : Colors.grey.shade500,
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
    );
  }

  Widget _buildTutorialPage(TutorialItem item) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘 또는 이미지
          if (item.isIntro)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                item.icon,
                size: 60,
                color: item.color,
              ),
            )
          else if (item.imagePath.isNotEmpty)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          const SizedBox(height: 32),
          
          // 제목
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // 설명
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class TutorialItem {
  final String title;
  final String description;
  final String imagePath;
  final IconData icon;
  final Color color;
  final bool isIntro;

  TutorialItem({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.icon,
    required this.color,
    required this.isIntro,
  });
} 