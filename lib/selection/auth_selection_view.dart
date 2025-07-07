// lib/selection/auth_selection_view.dart - 다국어 지원이 추가된 인증 선택 화면

import 'package:flutter/material.dart';
import 'package:flutter_application_1/map/map_screen.dart';
import 'package:provider/provider.dart';
import '../signup/sign_up_view.dart';
import '../login/login_form_view.dart';
import '../auth/user_auth.dart';
import '../generated/app_localizations.dart';
import 'package:flutter_application_1/welcome_view.dart';

class AuthSelectionView extends StatefulWidget {
  const AuthSelectionView({super.key});

  @override
  State<AuthSelectionView> createState() => _AuthSelectionViewState();
}

class _AuthSelectionViewState extends State<AuthSelectionView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatingController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
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

    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
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

  /// 게스트 로그인 처리 - MainNavigationScreen으로 이동하도록 수정
  Future<void> _handleGuestLogin() async {
    final userAuth = Provider.of<UserAuth>(context, listen: false);
    
    await userAuth.loginAsGuest(context: context);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MapScreen(), // MapScreen에서 MainNavigationScreen으로 변경
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // 매우 진한 남색
              Color(0xFF1E3A8A), // 우송대 남색
              Color(0xFF3B82F6), // 밝은 남색
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // 배경 장식 요소들
            _buildFloatingDecorations(),
            
            // 메인 콘텐츠
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 
                              MediaQuery.of(context).padding.top - 48,
                      child: Column(
                        children: [
                          // 상단 헤더
                          _buildHeader(l10n),
                          
                          const SizedBox(height: 40),
                          
                          // 메인 콘텐츠 카드
                          Expanded(
                            child: _buildMainCard(l10n),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // 하단 정보
                          _buildFooter(l10n),
                        ],
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

  Widget _buildFloatingDecorations() {
    return Stack(
      children: [
        // 우상단 장식
        Positioned(
          top: 80,
          right: -80,
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
        
        // 좌하단 장식
        Positioned(
          bottom: 100,
          left: -100,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_floatingAnimation.value * 0.7),
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.03),
                  ),
                ),
              );
            },
          ),
        ),
        
        // 중앙 작은 장식들
        Positioned(
          top: 200,
          left: 50,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_floatingAnimation.value * 0.3, 0),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

Widget _buildHeader(AppLocalizations l10n) {
  return Row(
    children: [
      IconButton(
        onPressed: () {
          // UserAuth 상태를 먼저 초기화
          final userAuth = Provider.of<UserAuth>(context, listen: false);
          userAuth.resetToWelcome();
          
          // 약간의 지연 후 네비게이션 (상태 변경이 적용되도록)
          Future.delayed(const Duration(milliseconds: 100), () {
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(
    builder: (context) => const WelcomeView(),
  ),
  (route) => false,
);
          });
        },
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Colors.white,
          size: 24,
        ),
      ),
      Text(
        l10n.select_auth_method,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ],
  );
}


  Widget _buildMainCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Consumer<UserAuth>(
        builder: (context, userAuth, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 로고 섹션
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF3B82F6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 타이틀
              Text(
                l10n.campus_navigator,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // 서브타이틀
              Text(
                l10n.woosong_campus_guide_service,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 인증 옵션들
              _buildAuthOption(
                icon: Icons.person_add,
                title: l10n.register,
                subtitle: l10n.register_description,
                onTap: userAuth.isLoading ? null : () => _navigateToSignUp(),
              ),
              
              const SizedBox(height: 12),
              
              _buildAuthOption(
                icon: Icons.login,
                title: l10n.login,
                subtitle: l10n.login_description,
                onTap: userAuth.isLoading ? null : () => _navigateToLogin(),
              ),
              
              const SizedBox(height: 16),
              
              // 게스트 접속
              SizedBox(
                height: 36,
                child: TextButton(
                  onPressed: userAuth.isLoading ? null : () => _showGuestDialog(l10n),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.browse_as_guest,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              // 로딩 상태 표시
              if (userAuth.isLoading) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.processing,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 에러 메시지 표시
              if (userAuth.lastError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          userAuth.lastError!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildAuthOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap == null ? const Color(0xFFE2E8F0) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(onTap == null ? 0.5 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: onTap == null 
                    ? const Color(0xFF1E3A8A).withOpacity(0.5)
                    : const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: onTap == null 
                          ? const Color(0xFF1E3A8A).withOpacity(0.5)
                          : const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: onTap == null 
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: onTap == null 
                  ? const Color(0xFF64748B).withOpacity(0.5)
                  : const Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.woosong_university,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          l10n.campus_navigator_version,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  void _navigateToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SignUpView(),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginFormView(),
      ),
    );
  }

  void _showGuestDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange[600],
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.guest_mode,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: Text(
          l10n.guest_mode_description,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.cancel,
              style: const TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleGuestLogin();
            },
            child: Text(
              l10n.continue_as_guest,
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
