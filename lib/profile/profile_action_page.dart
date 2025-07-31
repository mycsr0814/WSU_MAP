import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../auth/user_auth.dart';
import '../services/auth_service.dart';
import '../services/websocket_service.dart';

class ProfileActionPage extends StatefulWidget {
  final UserAuth userAuth;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLogout;

  const ProfileActionPage({
    required this.userAuth,
    required this.onEdit,
    required this.onDelete,
    required this.onLogout,
    super.key,
  });

  @override
  State<ProfileActionPage> createState() => _ProfileActionPageState();
}

class _ProfileActionPageState extends State<ProfileActionPage> {
  bool _isLocationEnabled = false;
  bool _isUpdating = false;
  StreamSubscription? _websocketSubscription;

  @override
  void initState() {
    super.initState();
    _loadLocationShareStatus();
    _setupWebSocketListener();
  }

  @override
  void dispose() {
    _websocketSubscription?.cancel();
    super.dispose();
  }



  /// 🔥 웹소켓 리스너 설정
  void _setupWebSocketListener() {
    final wsService = WebSocketService();
    _websocketSubscription = wsService.messageStream.listen((message) {
      if (message['type'] == 'friend_location_share_status_change') {
        final userId = message['userId'];
        final isLocationPublic = message['isLocationPublic'] ?? false;
        
        // 현재 사용자의 위치 공유 상태 변경인 경우에만 업데이트
        if (userId == widget.userAuth.userId) {
          debugPrint('📍 현재 사용자 위치 공유 상태 변경: $isLocationPublic');
          setState(() {
            _isLocationEnabled = isLocationPublic;
          });
          // SharedPreferences에도 저장
          _saveLocationShareStatus(isLocationPublic);
        }
      }
    });
  }

  /// 🔥 SharedPreferences에서 위치공유 상태 로드
  Future<void> _loadLocationShareStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStatus = prefs.getBool('location_share_enabled');
    debugPrint('🔥 SharedPreferences에서 로드한 위치공유 상태: $savedStatus');
    if (savedStatus != null) {
      setState(() {
        _isLocationEnabled = savedStatus;
      });
    } else {
      // 저장된 상태가 없으면 서버에서 가져오기
      await _fetchLocationShareStatus();
    }
  }

  /// 🔥 SharedPreferences에 위치공유 상태 저장
  Future<void> _saveLocationShareStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_share_enabled', status);
    debugPrint('🔥 SharedPreferences에 위치공유 상태 저장: $status');
  }

  /// 🔥 서버에서 위치공유 상태 조회 (필요할 때만 호출)
  Future<void> _fetchLocationShareStatus() async {
    setState(() => _isUpdating = true);
    final userId = widget.userAuth.userId;
    if (userId != null && userId.isNotEmpty) {
      final status = await AuthService().getShareLocationStatus(userId);
      debugPrint('🔥 서버에서 받아온 위치공유 상태: $status');
      if (status != null) {
        setState(() {
          _isLocationEnabled = status;
        });
        // 서버 상태를 SharedPreferences에 저장
        await _saveLocationShareStatus(_isLocationEnabled);
      }
    } else {
      debugPrint('❗ userId가 null 또는 빈 문자열');
    }
    setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          '내 정보',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 위치 허용 섹션
              _buildLocationSection(),
              const SizedBox(height: 24),
              
              // 회원정보 수정 섹션
              _buildEditProfileSection(),
              const SizedBox(height: 24),
              
              // 회원탈퇴 섹션
              _buildDeleteAccountSection(),
              const SizedBox(height: 24),
              
              // 로그아웃 섹션
              _buildLogoutSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    '위치 정보 공유',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
              onChanged: _isUpdating ? null : _onLocationToggleChanged,
              activeColor: const Color(0xFF10B981),
              activeTrackColor: const Color(0xFF10B981).withOpacity(0.3),
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditProfileSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: Icon(Icons.edit_outlined, color: const Color(0xFF1E3A8A)),
        title: Text(
          '프로필 정보 수정',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        subtitle: Text(
          '이름, 이메일, 전화번호, 비밀번호 변경',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
        onTap: widget.onEdit,
      ),
    );
  }

  Widget _buildDeleteAccountSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(Icons.delete_outline, color: Colors.red),
        title: Text(
          '계정 삭제',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
        ),
        subtitle: Text(
          '모든 데이터가 영구적으로 삭제됩니다',
          style: TextStyle(
            fontSize: 12,
            color: Colors.red.withOpacity(0.7),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.red.withOpacity(0.5), size: 16),
        onTap: widget.onDelete,
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A8A)),
      ),
      child: ListTile(
        leading: Icon(Icons.logout, color: const Color(0xFF1E3A8A)),
        title: Text(
          '로그아웃',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        subtitle: Text(
          '현재 계정에서 로그아웃합니다',
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF1E3A8A).withOpacity(0.7),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: const Color(0xFF1E3A8A).withOpacity(0.5), size: 16),
        onTap: widget.onLogout,
      ),
    );
  }

  /// 🔥 위치 허용 토글 변경 처리
  void _onLocationToggleChanged(bool value) async {
    debugPrint('🔥 위치 공유 상태 변경 시도: $value');
    
    setState(() {
      _isUpdating = true;
    });
    
    final userId = widget.userAuth.userId;
    final prev = _isLocationEnabled;
    
    // UI를 즉시 업데이트
    setState(() {
      _isLocationEnabled = value;
    });
    
    // SharedPreferences에 즉시 저장
    await _saveLocationShareStatus(value);
    
    if (userId != null && userId.isNotEmpty) {
      try {
        final success = await AuthService().updateShareLocation(userId, value);
        if (success) {
          debugPrint('✅ 서버에 위치 공유 상태 저장 성공');
          // 🔥 웹소켓을 통해 다른 사용자들에게 위치 공유 상태 변경 알림
          _sendLocationShareStatusChangeNotification(userId, value);
        } else {
          debugPrint('❌ 서버에 위치 공유 상태 저장 실패');
          if (mounted) {
            // 실패 시 원래대로 롤백
            setState(() {
              _isLocationEnabled = prev;
            });
            // SharedPreferences도 롤백
            await _saveLocationShareStatus(prev);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('서버에 위치공유 상태 저장에 실패했습니다.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('❌ 위치 공유 상태 업데이트 중 오류: $e');
        if (mounted) {
          // 오류 시 원래대로 롤백
          setState(() {
            _isLocationEnabled = prev;
          });
          // SharedPreferences도 롤백
          await _saveLocationShareStatus(prev);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('위치공유 상태 저장 중 오류가 발생했습니다: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      debugPrint('❌ userId가 null 또는 빈 문자열');
    }
    
    setState(() {
      _isUpdating = false;
    });
  }

  /// 🔥 웹소켓을 통해 위치 공유 상태 변경 알림 전송
  void _sendLocationShareStatusChangeNotification(String userId, bool isLocationPublic) {
    try {
      final wsService = WebSocketService();
      if (wsService.isConnected) {
        // 🔥 웹소켓 메시지 전송 (나중에 구현)
        // wsService.sendMessage({
        //   'type': 'friend_location_share_status_change',
        //   'userId': userId,
        //   'isLocationPublic': isLocationPublic,
        //   'message': '친구의 위치 공유 상태가 변경되었습니다.',
        //   'timestamp': DateTime.now().toIso8601String(),
        // });
        debugPrint('📍 위치 공유 상태 변경 알림 전송: $userId - ${isLocationPublic ? '공유' : '비공유'}');
      } else {
        debugPrint('⚠️ 웹소켓이 연결되지 않아 알림을 전송할 수 없습니다.');
      }
    } catch (e) {
      debugPrint('❌ 위치 공유 상태 변경 알림 전송 실패: $e');
    }
  }
} 