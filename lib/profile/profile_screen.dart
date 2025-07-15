import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/auth/user_auth.dart';
import 'package:flutter_application_1/selection/auth_selection_view.dart';
import '../generated/app_localizations.dart';
import 'package:flutter_application_1/services/auth_service.dart';

import 'help_page.dart';
import 'app_info_page.dart';
import 'profile_edit_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Consumer<UserAuth>(
              builder: (context, userAuth, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.my_page,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.my_info,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildUserInfoCard(context, userAuth, l10n),
                    const SizedBox(height: 24),
                    if (userAuth.isLoggedIn) ...[
                      _buildMenuList(userAuth, l10n),
                    ] else ...[
                      _buildGuestSection(l10n),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(
    BuildContext context,
    UserAuth userAuth,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              userAuth.currentUserIcon,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userAuth.isLoggedIn
                      ? userAuth.getCurrentUserDisplayName(context)
                      : l10n.guest_user,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    userAuth.isLoggedIn
                        ? (userAuth.userRole?.displayName(context) ?? l10n.user)
                        : l10n.guest_role,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (userAuth.isLoggedIn)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuList(UserAuth userAuth, AppLocalizations l10n) {
    final menuItems = [
      if (!userAuth.isGuest)
        {
          'icon': Icons.edit_outlined,
          'title': l10n.edit_profile,
          'subtitle': l10n.edit_profile_subtitle,
        },
      {
        'icon': Icons.help_outline,
        'title': l10n.help,
        'subtitle': l10n.help_subtitle,
      },
      {
        'icon': Icons.info_outline,
        'title': l10n.app_info,
        'subtitle': l10n.app_info_subtitle,
      },
      if (!userAuth.isGuest)
        {
          'icon': Icons.delete_outline,
          'title': l10n.delete_account,
          'subtitle': l10n.delete_account_subtitle,
          'isDestructive': true,
        },
    ];

    return Column(
      children: [
        ...menuItems.map(
          (item) => _buildMenuItem(
            icon: item['icon'] as IconData,
            title: item['title'] as String,
            subtitle: item['subtitle'] as String,
            isDestructive: item['isDestructive'] as bool? ?? false,
            onTap: () => _handleMenuTap(item['title'] as String),
          ),
        ),
        const SizedBox(height: 24),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildGuestSection(AppLocalizations l10n) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.person_add, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                l10n.login_required,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.login_message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _buildLoginButton(l10n),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildMenuItem(
          icon: Icons.help_outline,
          title: l10n.help,
          subtitle: l10n.help_subtitle,
          onTap: () => _handleMenuTap(l10n.help),
        ),
        _buildMenuItem(
          icon: Icons.info_outline,
          title: l10n.app_info,
          subtitle: l10n.app_info_subtitle,
          onTap: () => _handleMenuTap(l10n.app_info),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDestructive
                    ? Colors.red.withOpacity(0.2)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withOpacity(0.1)
                        : const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isDestructive
                        ? Colors.red[600]
                        : const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDestructive
                              ? Colors.red[600]
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _navigateToAuth,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            l10n.login_signup,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Consumer<UserAuth>(
      builder: (context, userAuth, child) {
        final l10n = AppLocalizations.of(context)!;
        return GestureDetector(
          onTap: () => _handleLogout(userAuth),
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E3A8A), width: 2),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, size: 18, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 8),
                  Text(
                    userAuth.isGuest ? l10n.login : l10n.logout,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleMenuTap(String title) {
    final l10n = AppLocalizations.of(context)!;

    if (title == l10n.help) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HelpPage()),
      );
    } else if (title == l10n.app_info) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AppInfoPage()),
      );
    } else if (title == l10n.edit_profile) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileEditPage()),
      );
    } else if (title == l10n.delete_account) {
      _showDeleteDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title ${l10n.feature_in_progress}'),
          backgroundColor: const Color(0xFF1E3A8A),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// ================================
  /// 회원탈퇴 다이얼로그 및 실제 탈퇴 기능
  /// ================================
  void _showDeleteDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final userAuth = Provider.of<UserAuth>(context, listen: false);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_outlined, color: Colors.red[600], size: 24),
            const SizedBox(width: 8),
            Text(
              l10n.delete_account_confirm,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: Text(
          l10n.delete_account_message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.yes,
              style: TextStyle(
                color: Colors.red[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    // 실제 회원탈퇴 처리
    if (result == true) {
      // 1. 서버에 회원탈퇴 요청
      final apiResult = await AuthService.deleteUser(id: userAuth.userId ?? '');
      if (apiResult.isSuccess) {
        // 2. 로컬 사용자 정보 초기화
        await userAuth.deleteAccount(context: context);

        // 3. 탈퇴 성공 안내 및 로그인/웰컴 화면 이동
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthSelectionView()),
            (route) => false,
          );
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.delete_account_success)));
      } else {
        // 4. 탈퇴 실패 안내
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiResult.message)));
      }
    }
  }

  /// ================================
  /// 🔥 수정된 로그아웃 함수
  /// ================================
  void _handleLogout(UserAuth userAuth) async {
    final l10n = AppLocalizations.of(context)!;

    if (userAuth.isGuest) {
      _navigateToAuth();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: const Color(0xFF1E3A8A), size: 24),
            const SizedBox(width: 8),
            Text(
              l10n.logout_confirm,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          l10n.logout_message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.logout,
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      debugPrint('🔥 ProfileScreen: 로그아웃 시작');

      // 1. 로그아웃 처리
      final success = await userAuth.logout();

      if (success && mounted) {
        debugPrint('🔥 ProfileScreen: 로그아웃 성공 - 네비게이션 스택 클리어');

        // 2. 🔥 네비게이션 스택 완전 클리어 후 루트 화면으로 이동
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  void _navigateToAuth() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AuthSelectionView()));
  }
}
