import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/woosong_button.dart';
///import '../selection/auth_selection_view.dart';
import '../generated/app_localizations.dart'; // 생성된 localization 파일 import
import '../auth/user_auth.dart';
import 'providers/app_language_provider.dart';

enum AppLanguage { korean, chinese, english }

String languageToString(AppLanguage lang) {
  switch (lang) {
    case AppLanguage.korean:
      return '한국어';
    case AppLanguage.chinese:
      return '中文';
    case AppLanguage.english:
      return 'English';
  }
}

AppLanguage localeToAppLanguage(Locale locale) {
  switch (locale.languageCode) {
    case 'ko':
      return AppLanguage.korean;
    case 'zh':
      return AppLanguage.chinese;
    case 'en':
      return AppLanguage.english;
    default:
      return AppLanguage.korean;
  }
}

Locale appLanguageToLocale(AppLanguage lang) {
  switch (lang) {
    case AppLanguage.korean:
      return const Locale('ko');
    case AppLanguage.chinese:
      return const Locale('zh');
    case AppLanguage.english:
      return const Locale('en');
  }
}

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingAnimation;
  late AppLanguage _selectedLanguage;

  @override
  void initState() {
    super.initState();
    final locale = Provider.of<AppLanguageProvider>(context, listen: false).locale;
  _selectedLanguage = localeToAppLanguage(locale);

    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    _floatingAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
    _slideController.forward();
    _floatingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  // 기본 텍스트 반환 함수들 (localization이 없을 때 사용)
  String _getAppTitle() {
    switch (_selectedLanguage) {
      case AppLanguage.korean:
        return 'Campus Navigator';
      case AppLanguage.chinese:
        return 'Campus\nNavigator';
      case AppLanguage.english:
        return 'Campus Navigator';
    }
  }

  String _getSubtitle() {
    switch (_selectedLanguage) {
      case AppLanguage.korean:
        return '우송대학교 캠퍼스를\n쉽고 빠르게 탐색하세요';
      case AppLanguage.chinese:
        return '轻松快捷地探索又松大学校园';
      case AppLanguage.english:
        return 'Explore Woosong University campus easily and quickly';
    }
  }

  String _getStartText() {
    switch (_selectedLanguage) {
      case AppLanguage.korean:
        return '시작하기';
      case AppLanguage.chinese:
        return '开始';
      case AppLanguage.english:
        return 'Get Started';
    }
  }

  String _getLanguageText() {
    switch (_selectedLanguage) {
      case AppLanguage.korean:
        return '언어 선택';
      case AppLanguage.chinese:
        return '选择语言';
      case AppLanguage.english:
        return 'Select Language';
    }
  }

  String _getWoosongText() {
    switch (_selectedLanguage) {
      case AppLanguage.korean:
        return '우송대학교';
      case AppLanguage.chinese:
        return '又松大学';
      case AppLanguage.english:
        return 'Woosong University';
    }
  }

void _showLanguageDialog() async {
  final result = await showDialog<AppLanguage>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(_getLanguageText()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((lang) {
            return RadioListTile<AppLanguage>(
              value: lang,
              groupValue: _selectedLanguage,
              title: Text(languageToString(lang)),
              onChanged: (value) {
                Navigator.of(context).pop(value);
              },
            );
          }).toList(),
        ),
      );
    },
  );

  if (result != null && result != _selectedLanguage) {
    setState(() {
      _selectedLanguage = result;
    });
    Provider.of<AppLanguageProvider>(context, listen: false)
        .setLocale(appLanguageToLocale(result));
  }
}




  @override
  Widget build(BuildContext context) {
    // AppLocalizations를 안전하게 가져오기 (null일 수 있음)
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // 배경 애니메이션 원들
            Positioned(
              top: 100,
              right: -50,
              child: AnimatedBuilder(
                animation: _floatingAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatingAnimation.value),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 150,
              left: -100,
              child: AnimatedBuilder(
                animation: _floatingAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_floatingAnimation.value * 0.5),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.03),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // 메인 컨텐츠
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      
                      // 로고 및 타이틀 섹션
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // 로고
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.school,
                                size: 40,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 30),
                            
                            // 앱 타이틀
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.white, Color(0xFFE2E8F0)],
                              ).createShader(bounds),
                              child: Text(
                                localizations?.appTitle ?? _getAppTitle(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // 서브타이틀
                            Text(
                              localizations?.subtitle ?? _getSubtitle(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.8),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(flex: 3),
                      
                      // 시작 버튼
                      AnimatedBuilder(
                        animation: _floatingAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatingAnimation.value * 0.3),
                            child: WoosongButton(
                              onPressed: () {
                                // 첫 실행 완료 표시 - Consumer가 자동으로 AuthSelectionView로 전환
                                Provider.of<UserAuth>(context, listen: false).completeFirstLaunch();
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(localizations?.start ?? _getStartText()),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // 언어 선택 버튼
                      Padding(
                        padding: const EdgeInsets.only(right: 24, top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.12),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.language, size: 18),
                              label: Text(languageToString(_selectedLanguage)),
                              onPressed: _showLanguageDialog,
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(flex: 1),
                      
                      // 하단 대학교 이름
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Text(
                          localizations?.woosong ?? _getWoosongText(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
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
