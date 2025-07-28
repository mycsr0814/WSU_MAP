import 'package:flutter/material.dart';
import 'package:flutter_application_1/auth/user_auth.dart';
import '../generated/app_localizations.dart';

class ProfileActionPage extends StatefulWidget {
  final UserAuth userAuth;
  final AppLocalizations l10n;
  final VoidCallback onLogout;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ProfileActionPage({
    super.key,
    required this.userAuth,
    required this.l10n,
    required this.onLogout,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<ProfileActionPage> createState() => _ProfileActionPageState();
}

class _ProfileActionPageState extends State<ProfileActionPage> {
  bool _isLocationEnabled = true; // 기본값은 true

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.l10n.my_info),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 위치 허용 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  Icon(
                    Icons.location_on,
                    color: _isLocationEnabled ? const Color(0xFF10B981) : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '내 위치 허용',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isLocationEnabled ? const Color(0xFF1E293B) : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isLocationEnabled ? '위치 정보가 활성화되어 있습니다' : '위치 정보가 비활성화되어 있습니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isLocationEnabled ? Colors.grey[600] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isLocationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isLocationEnabled = value;
                      });
                      // 여기에 실제 위치 권한 처리 로직을 추가할 수 있습니다
                    },
                    activeColor: const Color(0xFF10B981),
                    activeTrackColor: const Color(0xFF10B981).withOpacity(0.3),
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[300],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // 회원정보 수정
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(widget.l10n.edit_profile, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 회원탈퇴
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline),
                label: Text(widget.l10n.delete_account, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 로그아웃
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout, color: Color(0xFF1E3A8A)),
                label: Text(widget.l10n.logout, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: const Color(0xFF1E3A8A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 