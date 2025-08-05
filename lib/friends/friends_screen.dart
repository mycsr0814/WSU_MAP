// lib/screens/friends_screen.dart - 위치 제거 버튼이 추가된 완전한 코드
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/components/woosong_button.dart';
import 'package:flutter_application_1/components/woosong_input_field.dart';
import 'package:flutter_application_1/friends/friend.dart';
import 'package:flutter_application_1/friends/friend_api_service.dart';
import 'package:flutter_application_1/friends/friend_repository.dart';
import 'package:flutter_application_1/friends/friends_controller.dart';
import 'package:flutter_application_1/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/controllers/map_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_1/services/auth_service.dart';

class FriendsScreen extends StatefulWidget {
  final String userId;
  final Function(Friend)? onShowFriendLocation; // 🔥 콜백 함수 추가

  const FriendsScreen({
    required this.userId,
    this.onShowFriendLocation, // 🔥 선택적 매개변수
    super.key,
  });

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with WidgetsBindingObserver {
  late final FriendsController controller;
  final _addController = TextEditingController();
  bool _isAddingFriend = false;
  List<Map<String, String>>? _cachedUserList;
  Future<List<Map<String, String>>>? _userListFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    controller =
        FriendsController(FriendRepository(FriendApiService()), widget.userId)
          ..addListener(() {
            if (mounted) {
              setState(() {});
            }
          })
          ..loadAll();

    debugPrint('🚀 친구 화면 초기화 완료 - 실시간 업데이트 활성화');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    _addController.dispose();
    super.dispose();
  }

  // 🔥 앱 생명주기 관리 (백그라운드/포그라운드 전환)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('📱 앱 포그라운드 전환 - 실시간 업데이트 재시작');
        controller.resumeRealTimeUpdates();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        debugPrint('📱 앱 백그라운드 전환 - 실시간 업데이트 일시중지');
        controller.stopRealTimeUpdates();
        break;
      default:
        break;
    }
  }

  /// 사용자 ID 마스킹 함수
  String _maskUserId(String userId) {
    if (userId.length <= 4) return userId;
    return userId.substring(0, 4) + '*' * (userId.length - 4);
  }

  /// 🔥 캐시된 사용자 목록 가져오기
  Future<List<Map<String, String>>> _getCachedUserList() async {
    if (_cachedUserList != null) {
      debugPrint('📋 캐시된 사용자 목록 사용: ${_cachedUserList!.length}명');
      return _cachedUserList!;
    }

    if (_userListFuture != null) {
      debugPrint('📋 진행 중인 사용자 목록 요청 재사용');
      return _userListFuture!;
    }

    debugPrint('📋 새로운 사용자 목록 요청 시작');
    _userListFuture = AuthService().getUserList();
    _cachedUserList = await _userListFuture!;
    _userListFuture = null;
    
    debugPrint('📋 사용자 목록 캐시 완료: ${_cachedUserList!.length}명');
    return _cachedUserList!;
  }

  /// 🔥 캐시된 사용자 목록 초기화
  void _clearCachedUserList() {
    _cachedUserList = null;
    _userListFuture = null;
    debugPrint('📋 사용자 목록 캐시 초기화 완료');
  }

  /// 🔥 사용자 목록 새로고침
  Future<void> _refreshUserList() async {
    _clearCachedUserList();
    await _getCachedUserList();
    if (mounted) setState(() {});
  }

  /// 성공 메시지 표시
  void _showSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 에러 메시지 표시
  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// 🔥 친구 상세 정보 다이얼로그 - 위치 제거 버튼 추가 및 오프라인 처리, 모달창 닫기 통일
  Future<void> _showFriendDetailsDialog(Friend friend) async {
    HapticFeedback.lightImpact();

    final mapController = Provider.of<MapScreenController>(
      context,
      listen: false,
    );
    final isLocationDisplayed = mapController.isFriendLocationDisplayed(
      friend.userId,
    );

    // 🔥 친구의 최신 온라인 상태 확인 (서버 데이터 우선)
    final friendsController = Provider.of<FriendsController>(
      context,
      listen: false,
    );
    
    // 현재 친구 목록에서 해당 친구의 최신 상태 가져오기
    final currentFriend = friendsController.friends.firstWhere(
      (f) => f.userId == friend.userId,
      orElse: () => friend, // 찾지 못하면 원본 사용
    );
    
    // 🔥 서버 데이터 기반 온라인 상태 확인
    final isOnline = currentFriend.isLogin;
    debugPrint('🔍 친구 상세 정보 - ${friend.userName} (${friend.userId}): 온라인=$isOnline');

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFF10B981).withValues(alpha: 0.2) // 🔥 온라인 친구는 초록색 배경
                              : const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isOnline
                                ? const Color(0xFF10B981).withValues(alpha: 0.5) // 🔥 온라인 친구는 초록색 테두리
                                : const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                            width: isOnline ? 2 : 1, // 🔥 온라인 친구는 더 두꺼운 테두리
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          color: isOnline
                              ? const Color(0xFF10B981) // 🔥 온라인 친구는 초록색 아이콘
                              : const Color(0xFF1E3A8A),
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              friend.userName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isOnline
                                    ? const Color(0xFF10B981) // 🔥 온라인 친구는 초록색 텍스트
                                    : const Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isOnline
                                        ? const Color(0xFF10B981) // 🔥 초록색 온라인 표시
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOnline
                                      ? AppLocalizations.of(context)!.online
                                      : AppLocalizations.of(context)!.offline,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isOnline
                                        ? const Color(0xFF10B981) // 🔥 초록색 온라인 텍스트
                                        : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 내용
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        Icons.badge,
                        AppLocalizations.of(context)!.id,
                        friend.userId,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.phone,
                        AppLocalizations.of(context)!.contact,
                        friend.phone.isEmpty
                            ? AppLocalizations.of(context)!.noContactInfo
                            : friend.phone,
                        isClickable: friend.phone.isNotEmpty,
                        onTap: friend.phone.isNotEmpty
                            ? () => _handlePhone(context, friend.phone)
                            : null,
                      ),
                    ],
                  ),
                ),

                // 버튼 영역
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                  child: Column(
                    children: [
                      // 위치 관련 버튼들
                      if (friend.lastLocation.isNotEmpty) ...[
                        Row(
                          children: [
                            // 위치 표시/제거 버튼
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    HapticFeedback.lightImpact();
                                    Navigator.of(context).pop(); // 항상 모달창 닫기
                                    
                                    // 🔥 위치 공유 상태 확인
                                    if (!friend.isLocationPublic) {
                                      _showErrorMessage(
                                        '${friend.userName}님이 위치 공유를 허용하지 않았습니다.',
                                      );
                                      return;
                                    }
                                    
                                    if (!isOnline) {
                                      _showErrorMessage(
                                        AppLocalizations.of(
                                          context,
                                        )!.friendOfflineError,
                                      );
                                      return;
                                    }
                                    
                                    if (!isLocationDisplayed) {
                                      await _showFriendLocationOnMap(friend);
                                    } else {
                                      await _removeFriendLocationFromMap(friend);
                                    }
                                  },
                                  icon: Icon(
                                    isLocationDisplayed ? Icons.location_off : Icons.location_on,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isLocationDisplayed
                                        ? AppLocalizations.of(context)!.removeLocation
                                        : AppLocalizations.of(context)!.showLocation,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isLocationDisplayed
                                        ? const Color(0xFFEF4444)
                                        : friend.isLocationPublic 
                                            ? const Color(0xFF10B981)
                                            : Colors.grey[400]!,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // 닫기 버튼
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close, size: 18),
                                  label: Text(AppLocalizations.of(context)!.close),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[100],
                                    foregroundColor: Colors.grey[700],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // 위치 정보가 없을 때는 닫기 버튼만
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, size: 18),
                            label: Text(AppLocalizations.of(context)!.close),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.grey[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 상세 정보 행 위젯
  Widget _buildDetailRow(IconData icon, String label, String value, {bool isClickable = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: isClickable ? onTap : null,
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                  style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                    color: isClickable ? const Color(0xFF10B981) : const Color(0xFF1E3A8A),
                    decoration: isClickable ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
      ],
      ),
    );
  }

  /// 🔥 친구 위치를 지도에 표시 - 콜백 함수 사용
  Future<void> _showFriendLocationOnMap(Friend friend) async {
    try {
      if (widget.onShowFriendLocation != null) {
        // 콜백 함수 호출 (MapScreen에서 전달받은 함수)
        await widget.onShowFriendLocation!(friend);
      } else {
        // 기본 동작 (Provider 사용)
        final mapController = Provider.of<MapScreenController>(
          context,
          listen: false,
        );
        await mapController.showFriendLocation(friend);
        _showFriendLocationSuccess(friend);
      }
    } catch (e) {
      debugPrint('❌ 친구 위치 표시 오류: $e');
      _showErrorMessage('친구 위치를 표시할 수 없습니다.');
    }
  }

  /// 🔥 친구 위치를 지도에서 제거
  Future<void> _removeFriendLocationFromMap(Friend friend) async {
    try {
      final mapController = Provider.of<MapScreenController>(
        context,
        listen: false,
      );
      await mapController.removeFriendLocationMarker(friend.userId);

      _showSuccessMessage(
        AppLocalizations.of(context)!.friendLocationRemoved(friend.userName),
      );

      debugPrint('✅ 친구 위치 제거 완료: ${friend.userName}');
    } catch (e) {
      debugPrint('❌ 친구 위치 제거 오류: $e');
      _showErrorMessage(
        AppLocalizations.of(context)!.errorCannotRemoveLocation,
      );
    }
  }

  /// 친구 위치 표시 성공 메시지
  void _showFriendLocationSuccess(Friend friend) {
    _showSuccessMessage(
      AppLocalizations.of(context)!.friendLocationShown(friend.userName),
    );
  }

  /// 친구 추가 처리 함수
  Future<void> _handleAddFriend([StateSetter? setModalState]) async {
    // 🔥 이미 제출 중이면 중복 제출 방지
    if (_isAddingFriend) {
      debugPrint('이미 친구 추가 중입니다. 중복 제출 방지');
      return;
    }

    final id = _addController.text.trim();
    if (id.isEmpty) {
      _showErrorMessage('아이디를 입력하세요');
      return;
    }

    debugPrint('🔍 친구 추가 시도 - 입력된 ID: $id');

    setState(() => _isAddingFriend = true);
    
    try {
      debugPrint('🔄 UI: controller.addFriend 시작...');
      await controller.addFriend(id);
      debugPrint('📤 친구 요청 전송 완료');
      
      // 성공 - 예외가 발생하지 않았으면 성공
      debugPrint('✅ UI: 친구 요청 성공으로 판단');
      _showSuccessMessage('친구 요청이 성공적으로 전송되었습니다');
      _addController.clear();
      _clearCachedUserList(); // 캐시 초기화
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('❌ UI: 친구 추가 중 오류: $e');
      debugPrint('❌ UI: 예외 타입: ${e.runtimeType}');
      debugPrint('❌ UI: 예외 스택: ${StackTrace.current}');
      debugPrint('❌ UI: 예외 메시지: ${e.toString()}');
      
      // 🔥 구체적인 에러 메시지 처리
      String errorMsg = '친구 추가 중 오류가 발생했습니다';
      if (e.toString().contains('존재하지 않는 사용자')) {
        errorMsg = '존재하지 않는 사용자입니다';
      } else if (e.toString().contains('이미 친구')) {
        errorMsg = '이미 친구인 사용자입니다';
      } else if (e.toString().contains('이미 요청')) {
        errorMsg = '이미 친구 요청을 보낸 사용자입니다';
      } else if (e.toString().contains('자기 자신')) {
        errorMsg = '자기 자신을 친구로 추가할 수 없습니다';
      } else if (e.toString().contains('잘못된')) {
        errorMsg = '잘못된 사용자 ID입니다';
      } else if (e.toString().contains('서버 오류')) {
        errorMsg = '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요';
      } else {
        errorMsg = e.toString().replaceAll('Exception: ', '');
      }
      
      _showErrorMessage(errorMsg);
      // 실패 시에도 모달창 닫기
      if (mounted) Navigator.of(context).pop();
    } finally {
      setState(() => _isAddingFriend = false);
    }
  }

  void _handlePhone(BuildContext context, String phone) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Text('전화앱을 열 수 없습니다.')),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // 🔥 실시간 상태 표시기가 포함된 헤더
  // 🔥 실시간 상태 표시기가 포함된 헤더
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.friends,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.friendManagementAndRequests,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: controller.isRealTimeEnabled
                                ? Colors.green
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 새로고침 버튼과 추가 버튼은 그대로...
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    controller.loadAll();
                  },
                  icon: AnimatedRotation(
                    turns: controller.isLoading ? 1 : 0,
                    duration: const Duration(milliseconds: 500),
                    child: const Icon(
                      Icons.refresh,
                      color: Color(0xFF1E3A8A),
                      size: 24,
                    ),
                  ),
                ),
              ),
              AnimatedScale(
                scale: _isAddingFriend ? 0.95 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: IconButton(
                  onPressed: _isAddingFriend ? null : _showAddDialog,
                  icon: _isAddingFriend
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF1E3A8A),
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person_add,
                          color: Color(0xFF1E3A8A),
                          size: 28,
                        ),
                ),
              ),
            ],
          ),
          // 실시간 업데이트 정보 표시
          if (controller.isRealTimeEnabled) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi, color: Colors.green.shade600, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.realTimeSyncStatus(controller.lastUpdateTime),
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 친구 관리 다이얼로그 - 실시간 업데이트 적용
  Future<void> _showAddDialog() async {
    HapticFeedback.lightImpact();

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    // 드래그 핸들
                    Container(
                      padding: const EdgeInsets.only(top: 20, bottom: 10),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.friendManagement,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 탭 바
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TabBar(
                        isScrollable: false,
                        tabAlignment: TabAlignment.fill,
                        labelColor: const Color(0xFF1E3A8A),
                        unselectedLabelColor: Colors.grey,
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        indicator: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tabs: [
                          Tab(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_add, size: 16),
                                  const SizedBox(width: 4),
                                  Text(AppLocalizations.of(context)!.add),
                                ],
                              ),
                            ),
                          ),
                          Tab(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.send, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.sentRequestsCount(
                                      controller.sentFriendRequests.length,
                                    ),
                                  ),
                                  if (controller.sentFriendRequests.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(left: 4),
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF59E0B),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Tab(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.notifications_active,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.receivedRequestsCount(
                                      controller.friendRequests.length,
                                    ),
                                  ),
                                  if (controller.friendRequests.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(left: 4),
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 탭 내용
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildAddFriendTab(setModalState, scrollController),
                          _buildSentRequestsTab(
                            setModalState,
                            scrollController,
                          ),
                          _buildReceivedRequestsTab(
                            setModalState,
                            scrollController,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 친구 추가 탭
  Widget _buildAddFriendTab(
    StateSetter setModalState,
    ScrollController scrollController,
  ) {
    return FutureBuilder<List<Map<String, String>>>(
      future: _getCachedUserList(),
      builder: (context, snapshot) {
        List<Map<String, String>> userList = [];
        if (snapshot.hasData) {
          userList = snapshot.data!;
        }

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            Text(
              AppLocalizations.of(context)!.enterFriendIdPrompt,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: WoosongInputField(
                icon: Icons.person_add_alt,
                label: AppLocalizations.of(context)!.friendId,
                controller: _addController,
                hint: AppLocalizations.of(context)!.enterFriendId,
                enabled: !_isAddingFriend,
              ),
            ),

            const SizedBox(height: 20),

            // 사용자 목록 표시
            if (userList.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '사용 가능한 사용자 목록:',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    onPressed: () => _refreshUserList(),
                    tooltip: '사용자 목록 새로고침',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: userList.length,
                  itemBuilder: (context, index) {
                    final user = userList[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        '${user['name']} (${user['id']})',
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        _addController.text = user['id']!;
                        setModalState(() {});
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            SizedBox(
              width: double.infinity,
              child: WoosongButton(
                onPressed: _isAddingFriend
                    ? null
                    : () => _handleAddFriend(setModalState),
                child: _isAddingFriend
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(AppLocalizations.of(context)!.sendFriendRequest),
              ),
            ),

            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  // 🔥 실시간 업데이트되는 보낸 요청 탭
  Widget _buildSentRequestsTab(
    StateSetter setModalState,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.update, color: Colors.blue.shade600, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.realTimeSyncActive,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (controller.sentFriendRequests.isEmpty)
          SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_outlined,
                      color: Color(0xFF1E3A8A),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noSentRequests,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...controller.sentFriendRequests.map(
            (request) => _buildSentRequestTile(request, setModalState),
          ),
      ],
    );
  }

  // 🔥 실시간 업데이트되는 받은 요청 탭
  Widget _buildReceivedRequestsTab(
    StateSetter setModalState,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        if (controller.friendRequests.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.red.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.newFriendRequests(controller.friendRequests.length),
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (controller.friendRequests.isEmpty)
          SizedBox(
            height: 300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      color: Color(0xFF1E3A8A),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noReceivedRequests,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...controller.friendRequests.map(
            (request) => _buildReceivedRequestTile(request, setModalState),
          ),
      ],
    );
  }

  // 🔥 애니메이션이 추가된 보낸 요청 타일
  Widget _buildSentRequestTile(
    SentFriendRequest request, [
    StateSetter? setModalState,
  ]) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule,
              color: Color(0xFF1E3A8A),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.toUserName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppLocalizations.of(context)!.id}: ${_maskUserId(request.toUserId)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                if (request.requestDate.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.requestDate(request.requestDate),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.cancel,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              onPressed: () => _showCancelRequestDialog(request, setModalState),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 애니메이션이 추가된 받은 요청 타일
  Widget _buildReceivedRequestTile(
    FriendRequest request, [
    StateSetter? setModalState,
  ]) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add,
              color: Color(0xFFF59E0B),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      request.fromUserName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade500,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.newBadge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppLocalizations.of(context)!.id}: ${_maskUserId(request.fromUserId)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.check,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await controller.acceptRequest(request.fromUserId);
                    setModalState?.call(() {});
                    _showSuccessMessage(
                      AppLocalizations.of(
                        context,
                      )!.friendRequestAccepted(request.fromUserName),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await controller.rejectRequest(request.fromUserId);
                    setModalState?.call(() {});
                    _showSuccessMessage(
                      AppLocalizations.of(
                        context,
                      )!.friendRequestRejected(request.fromUserName),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 요청 취소 다이얼로그
  Future<void> _showCancelRequestDialog(
    SentFriendRequest request, [
    StateSetter? setModalState,
  ]) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔥 헤더
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.cancelFriendRequest,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '보낸 친구 요청을 취소합니다',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 🔥 내용
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.cancelFriendRequestConfirm(request.toUserName),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 🔥 버튼 영역
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.no,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.cancelRequest,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
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

    if (confirmed == true) {
      HapticFeedback.lightImpact();
      await controller.cancelSentRequest(request.toUserId);
      setModalState?.call(() {});
      _showSuccessMessage(
        AppLocalizations.of(context)!.friendRequestCanceled(request.toUserName),
      );
    }
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 실시간 업데이트되는 메인 친구 목록
  Widget _buildFriendsContent() {
    return Container(
      margin: EdgeInsets.zero, // 화면에 꽉 차게
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSectionHeader(
            AppLocalizations.of(
              context,
            )!.friendCount(controller.friends.length),
            icon: Icons.people_alt,
          ),
          if (controller.friends.isEmpty)
            _buildEmptyState(AppLocalizations.of(context)!.noFriends)
          else
            ...controller.friends.asMap().entries.map((entry) {
              final index = entry.key;
              final friend = entry.value;
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutBack,
                child: Consumer<FriendsController>(
                  builder: (context, friendsController, child) {
                    return _buildFriendTile(friend);
                  },
                ),
              );
            }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 🔥 친구 타일 - 클릭 시 상세 정보 다이얼로그 표시
  Widget _buildFriendTile(Friend friend) {
    // 🔥 FriendsController에서 최신 상태 가져오기
    final friendsController = Provider.of<FriendsController>(context, listen: false);
    final currentFriend = friendsController.friends.firstWhere(
      (f) => f.userId == friend.userId,
      orElse: () => friend, // 찾지 못하면 원본 사용
    );
    
    // 🔥 디버깅: 친구 상태 로그
    debugPrint('🎨 ${friend.userName} (${friend.userId}) 타일 렌더링 - 원본 온라인: ${friend.isLogin}, 최신 온라인: ${currentFriend.isLogin}');
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: currentFriend.isLogin
              ? const Color(0xFF10B981).withValues(alpha: 0.5) // 🔥 더 진한 초록색 테두리
              : const Color(0xFFE2E8F0),
          width: currentFriend.isLogin ? 2 : 1, // 🔥 온라인 친구는 더 두꺼운 테두리
        ),
        boxShadow: [
          BoxShadow(
            color: currentFriend.isLogin 
                ? const Color(0xFF10B981).withValues(alpha: 0.1) // 🔥 온라인 친구는 초록색 그림자
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFriendDetailsDialog(friend),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: currentFriend.isLogin
                        ? const Color(0xFF10B981).withValues(alpha: 0.15) // 🔥 더 진한 초록색 배경
                        : const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: currentFriend.isLogin
                          ? const Color(0xFF10B981).withValues(alpha: 0.5) // 🔥 더 진한 초록색 테두리
                          : const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                      width: currentFriend.isLogin ? 2.5 : 2, // 🔥 온라인 친구는 더 두꺼운 테두리
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: currentFriend.isLogin
                        ? const Color(0xFF10B981) // 🔥 초록색 아이콘
                        : const Color(0xFF1E3A8A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: currentFriend.isLogin 
                              ? const Color(0xFF10B981) // 🔥 온라인 친구는 초록색 텍스트
                              : const Color(0xFF1E3A8A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: currentFriend.isLogin
                                  ? const Color(0xFF10B981) // 🔥 초록색 온라인 표시
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currentFriend.isLogin
                                ? AppLocalizations.of(context)!.online
                                : AppLocalizations.of(context)!.offline,
                            style: TextStyle(
                              fontSize: 12,
                              color: currentFriend.isLogin
                                  ? const Color(0xFF10B981) // 🔥 초록색 온라인 텍스트
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_remove, color: Color(0xFFEF4444)),
                  tooltip: '친구 삭제',
                  onPressed: () => _showDeleteFriendDialog(friend),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 친구 삭제 다이얼로그
  Future<void> _showDeleteFriendDialog(Friend friend) async {
    final l10n = AppLocalizations.of(context)!; // 다국어 텍스트 불러오기

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더 - 경고 스타일
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_outlined,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.friendDeleteTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.friendDeleteWarning,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 내용
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.friendDeleteHeader,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.friendDeleteToConfirm(friend.userName),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 버튼 영역
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            l10n.friendDeleteCancel,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            l10n.friendDeleteButton,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
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

    if (confirmed == true) {
      await controller.deleteFriend(friend.userId);
      final l10n = AppLocalizations.of(context)!;
      final message = l10n.friendDeleteSuccessMessage(friend.userName);
      _showSuccessMessage(message);
    }
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              color: Color(0xFF1E3A8A),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = controller.isLoading;
    final error = controller.errorMessage;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: true,
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
              _buildHeader(),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1E3A8A),
                        ),
                      )
                    : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFEF4444),
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              error,
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                controller.loadAll();
                              },
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF1E3A8A),
                        onRefresh: controller.loadAll,
                        child: ListView(
                          padding: const EdgeInsets.only(top: 16, bottom: 32),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [_buildFriendsContent()],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
