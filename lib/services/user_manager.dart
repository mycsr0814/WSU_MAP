// lib/services/user_manager.dart - 현재 사용자 정보 관리

import 'package:shared_preferences/shared_preferences.dart';

class UserManager {
  static UserManager? _instance;
  static UserManager get instance => _instance ??= UserManager._();

  UserManager._();

  // 현재 로그인한 사용자 정보
  String? _currentUserId;
  String? _currentUserName;
  bool _isLoggedIn = false;
  bool _isGuest = false;

  // Getter들
  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuest => _isGuest;

  /// 로그인 성공 시 사용자 정보 저장
  Future<void> setCurrentUser({
    required String userId,
    required String userName,
    bool isGuest = false,
  }) async {
    _currentUserId = userId;
    _currentUserName = userName;
    _isLoggedIn = true;
    _isGuest = isGuest;

    // SharedPreferences에도 저장 (앱 재시작 시 복원용)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);
    await prefs.setString('current_user_name', userName);
    await prefs.setBool('is_logged_in', true);
    await prefs.setBool('is_guest', isGuest);

    print('사용자 정보 저장: ID=$userId, Name=$userName, isGuest=$isGuest');
  }

  /// 게스트 로그인
  Future<void> setGuestUser() async {
    final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    await setCurrentUser(
      userId: guestId,
      userName: 'Guest User',
      isGuest: true,
    );
  }

  /// 로그아웃
  Future<void> logout() async {
    _currentUserId = null;
    _currentUserName = null;
    _isLoggedIn = false;
    _isGuest = false;

    // SharedPreferences에서도 제거
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    await prefs.remove('current_user_name');
    await prefs.remove('is_logged_in');
    await prefs.remove('is_guest');

    print('사용자 정보 삭제됨');
  }

  /// ================================
  /// 회원탈퇴(회원 삭제) - 서버에서 성공 응답을 받은 뒤 호출
  /// ================================
  ///
  /// 모든 사용자 정보와 SharedPreferences 데이터를 완전히 삭제합니다.
  /// 로그아웃과 거의 동일하지만, 탈퇴 후 복구 불가를 명확히 하기 위해 별도 메서드로 분리.
  Future<void> deleteAccount() async {
    _currentUserId = null;
    _currentUserName = null;
    _isLoggedIn = false;
    _isGuest = false;

    // SharedPreferences의 모든 사용자 관련 데이터 삭제
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    await prefs.remove('current_user_name');
    await prefs.remove('is_logged_in');
    await prefs.remove('is_guest');
    // 필요하다면 추가로 사용자 관련 데이터 키도 여기서 삭제

    print('회원탈퇴: 사용자 정보 및 로컬 데이터 완전 삭제 완료');
  }

  /// ================================

  /// 앱 시작 시 저장된 사용자 정보 복원
  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();

    _currentUserId = prefs.getString('current_user_id');
    _currentUserName = prefs.getString('current_user_name');
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    _isGuest = prefs.getBool('is_guest') ?? false;

    print(
      '사용자 정보 복원: ID=$_currentUserId, Name=$_currentUserName, isGuest=$_isGuest',
    );
  }

  /// 사용자별 데이터 키 생성 (SharedPreferences용)
  String getUserDataKey(String dataType) {
    final userId = _currentUserId ?? 'unknown';
    return '${dataType}_$userId';
  }

  /// 현재 사용자가 유효한지 확인
  bool isValidUser() {
    return _currentUserId != null && _currentUserId!.isNotEmpty;
  }
}
