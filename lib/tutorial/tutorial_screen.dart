import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';
import 'package:provider/provider.dart';
import '../auth/user_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentPage = 0;
  late PageController _pageController;
  bool _dontShowAgain = false;

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

  /// 🔥 게스트 튜토리얼 설정 저장
  Future<void> _saveGuestTutorialSetting(bool showTutorial) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('guest_tutorial_show', showTutorial);
      debugPrint('✅ 게스트 튜토리얼 설정 저장: $showTutorial');
    } catch (e) {
      debugPrint('❌ 게스트 튜토리얼 설정 저장 오류: $e');
    }
  }

  /// 🔥 튜토리얼 완료 처리
  Future<void> _finishTutorial() async {
    final userAuth = context.read<UserAuth>();

    if (_dontShowAgain) {
      if (userAuth.isLoggedIn) {
        // 로그인된 사용자는 서버에 설정 업데이트
        try {
          final success = await userAuth.updateTutorial(showTutorial: false);
          if (success) {
            debugPrint('✅ 로그인 사용자 튜토리얼 설정 업데이트 성공');
          } else {
            debugPrint('❌ 로그인 사용자 튜토리얼 설정 업데이트 실패');
          }
        } catch (e) {
          debugPrint('❌ 로그인 사용자 튜토리얼 설정 업데이트 오류: $e');
        }
      } else {
        // 게스트는 로컬에 설정 저장
        await _saveGuestTutorialSetting(false);
      }
    }

    // 튜토리얼 화면 닫기
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLastPage = _currentPage == 4; // tutorialItems length - 1 (5 items)
    // tutorialItems 를 build 내부에서 l10n으로 생성
    final List<TutorialItem> tutorialItems = [
      TutorialItem(
        title: l10n.tutorialTitleIntro, // ex: '따라우송 사용법'
        description: l10n.tutorialDescIntro, // ex: '우송대학교 캠퍼스 네비게이터로\n캠퍼스 생활을 더욱 편리하게 만들어보세요'
        imagePath: '',
        icon: Icons.help_outline,
        color: const Color(0xFF1E3A8A),
        isIntro: true,
      ),
      TutorialItem(
        title: l10n.tutorialTitleSearch,
        description: l10n.tutorialDescSearch,
        imagePath: 'lib/asset/1.png',
        icon: Icons.search,
        color: const Color(0xFF3B82F6),
        isIntro: false,
      ),
      TutorialItem(
        title: l10n.tutorialTitleSchedule,
        description: l10n.tutorialDescSchedule,
        imagePath: 'lib/asset/2.png',
        icon: Icons.schedule,
        color: const Color(0xFF10B981),
        isIntro: false,
      ),
      TutorialItem(
        title: l10n.tutorialTitleDirections,
        description: l10n.tutorialDescDirections,
        imagePath: 'lib/asset/3.png',
        icon: Icons.directions,
        color: const Color(0xFFF59E0B),
        isIntro: false,
      ),
      TutorialItem(
        title: l10n.tutorialTitleIndoorMap,
        description: l10n.tutorialDescIndoorMap,
        imagePath: 'lib/asset/4.png',
        icon: Icons.map,
        color: const Color(0xFF8B5CF6),
        isIntro: false,
      ),
    ];

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
                          Text(
                            l10n.dontShowAgain,
                            style: const TextStyle(
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
                      onPressed: isLastPage
                          ? () {
                              _finishTutorial();
                            }
                          : null,
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
                        l10n.goBack,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isLastPage ? Colors.white : Colors.grey.shade500,
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
