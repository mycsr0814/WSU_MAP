// lib/signup/sign_up_view.dart - 다국어 지원이 완전히 적용된 버전

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/login/login_form_view.dart';
import 'package:provider/provider.dart';
import '../components/woosong_input_field.dart';
import '../components/woosong_button.dart';
import '../auth/user_auth.dart';
import '../generated/app_localizations.dart';

enum UserType { student, professor, external }

extension UserTypeExtension on UserType {
  String displayName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case UserType.student:
        return l10n.student;
      case UserType.professor:
        return l10n.professor;
      case UserType.external:
        return l10n.external_user;
    }
  }
}

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> with TickerProviderStateMixin {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final stuNumberController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    
    // 전화번호 포맷팅 리스너 추가
    phoneController.addListener(_formatPhoneNumber);
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    stuNumberController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// 전화번호 자동 포맷팅
  void _formatPhoneNumber() {
    final text = phoneController.text;
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length <= 3) {
      phoneController.value = TextEditingValue(
        text: digitsOnly,
        selection: TextSelection.collapsed(offset: digitsOnly.length),
      );
    } else if (digitsOnly.length <= 7) {
      final formatted = '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3)}';
      phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } else {
      final formatted = '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 7)}-${digitsOnly.substring(7, 11)}';
      phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  /// 회원가입 처리
  void _handleSignUp() async {
    final l10n = AppLocalizations.of(context)!;
    final id = usernameController.text.trim();
    final pw = passwordController.text.trim();
    final confirmPw = confirmPasswordController.text.trim();
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final stuNumber = stuNumberController.text.trim();

    // 입력 검증
    if (id.isEmpty || pw.isEmpty || name.isEmpty || phone.isEmpty) {
      _showDialog(l10n.required_fields_empty, isError: true);
      return;
    }

    if (pw != confirmPw) {
      _showDialog(l10n.password_mismatch, isError: true);
      return;
    }

    if (pw.length < 6) {
      _showDialog(l10n.password_too_short, isError: true);
      return;
    }

    // 전화번호 형식 검증
    if (!_isValidPhoneNumber(phone)) {
      _showDialog(l10n.invalid_phone_format, isError: true);
      return;
    }

    // 이메일 형식 검증 (선택사항)
    if (email.isNotEmpty && !_isValidEmail(email)) {
      _showDialog(l10n.invalid_email_format, isError: true);
      return;
    }

    final userAuth = Provider.of<UserAuth>(context, listen: false);
    
    // 서버 API를 통한 회원가입 시도
    final success = await userAuth.register(
      id: id,
      password: pw,
      name: name,
      phone: phone,
      stuNumber: stuNumber.isEmpty ? null : stuNumber,
      email: email.isEmpty ? null : email,
      context: context,
    );

    if (success && mounted) {
      // 회원가입 성공
      _showDialog(l10n.register_success_message, isSuccess: true);
    } else if (mounted) {
      // 회원가입 실패
      _showDialog(userAuth.lastError ?? l10n.register_error, isError: true);
    }
  }

  /// 전화번호 형식 검증
  bool _isValidPhoneNumber(String phone) {
    // 010-1234-5678 또는 01012345678 형식 허용
    final phoneRegex = RegExp(r'^010[-]?\d{4}[-]?\d{4}$');
    return phoneRegex.hasMatch(phone);
  }

  /// 이메일 형식 검증
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// 결과 다이얼로그 표시
  void _showDialog(String message, {bool isSuccess = false, bool isError = false}) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Icon(
          isSuccess ? Icons.check_circle : (isError ? Icons.error : Icons.info),
          color: isSuccess ? Colors.green : (isError ? Colors.red : Colors.blue),
          size: 48,
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (isSuccess) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginFormView()),
                );
              }
            },
            child: Text(
              l10n.confirm,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
            ],
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
                      // 헤더
                      Row(
                        children: [
                          IconButton(
                            onPressed: userAuth.isLoading ? null : () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          Text(
                            l10n.register,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      
                      // 서브타이틀
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          l10n.welcome_to_campus_navigator,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // 사용자 유형 선택 UI 제거
                      const SizedBox(height: 24),

                      // 회원가입 폼
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // 필수 입력 필드들
                            WoosongInputField(
                              icon: Icons.person_outline,
                              label: '${l10n.username} *',
                              controller: usernameController,
                              hint: l10n.enter_username,
                            ),
                            WoosongInputField(
                              icon: Icons.lock_outline,
                              label: '${l10n.password} *',
                              controller: passwordController,
                              isPassword: true,
                              hint: l10n.password_hint,
                            ),
                            WoosongInputField(
                              icon: Icons.lock_outline,
                              label: '${l10n.confirm_password} *',
                              controller: confirmPasswordController,
                              isPassword: true,
                              hint: l10n.confirm_password_hint,
                            ),
                            WoosongInputField(
                              icon: Icons.badge_outlined,
                              label: '${l10n.name} *',
                              controller: nameController,
                              hint: l10n.enter_real_name,
                            ),
                            WoosongInputField(
                              icon: Icons.phone_outlined,
                              label: '${l10n.phone} *',
                              controller: phoneController,
                              hint: l10n.phone_format_hint,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                            
                            // 선택 입력 필드들
                              WoosongInputField(
                                icon: Icons.numbers_outlined,
                                label: '${l10n.student_number} (${l10n.optional})',
                                controller: stuNumberController,
                                hint: l10n.enter_student_number,
                              ),
                            WoosongInputField(
                              icon: Icons.email_outlined,
                              label: '${l10n.email} (${l10n.optional})',
                              controller: emailController,
                              hint: l10n.email_hint,
                            ),

                            const SizedBox(height: 8),

                            // 필수 항목 안내
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.required_fields_notice,
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 회원가입 버튼
                            WoosongButton(
                              onPressed: userAuth.isLoading ? null : _handleSignUp,
                              child: userAuth.isLoading 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(l10n.create_account),
                            ),

                            const SizedBox(height: 12),

                            // 취소 버튼
                            WoosongButton(
                              onPressed: userAuth.isLoading ? null : () => Navigator.of(context).pop(),
                              isPrimary: false,
                              isOutlined: true,
                              child: Text(l10n.cancel),
                            ),

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
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
