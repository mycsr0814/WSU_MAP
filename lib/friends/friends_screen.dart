// lib/screens/friends_screen.dart - 위치 제거 버튼이 추가된 완전한 코드
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/components/woosong_button.dart';
import 'package:flutter_application_1/components/woosong_input_field.dart';
import 'package:flutter_application_1/friends/friend.dart';
import 'package:flutter_application_1/friends/friend_api_service.dart';
import 'package:flutter_application_1/friends/friend_repository.dart';
import 'package:flutter_application_1/friends/friends_controller.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/controllers/map_controller.dart';

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

  /// 🔥 친구 상세 정보 다이얼로그 - 위치 제거 버튼 추가
  Future<void> _showFriendDetailsDialog(Friend friend) async {
    HapticFeedback.lightImpact();

    // 🔥 친구 위치 표시 상태 확인
    final mapController = Provider.of<MapScreenController>(
      context,
      listen: false,
    );
    final isLocationDisplayed = mapController.isFriendLocationDisplayed(
      friend.userId,
    );

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
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
                        color: const Color(0xFF1E3A8A).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF1E3A8A),
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
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: friend.isLogin
                                      ? Colors.green
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                friend.isLogin ? '온라인' : '오프라인',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: friend.isLogin
                                      ? Colors.green
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
                    _buildDetailRow(Icons.badge, 'ID', friend.userId),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.phone,
                      '연락처',
                      friend.phone.isEmpty ? '정보 없음' : friend.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.location_on,
                      '마지막 위치',
                      friend.lastLocation.isEmpty
                          ? '위치 정보 없음'
                          : friend.lastLocation,
                    ),
                  ],
                ),
              ),

              // 🔥 버튼 영역 - 위치 제거 버튼 추가
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                child: Column(
                  children: [
                    // 위치 관련 버튼들
                    if (friend.lastLocation.isNotEmpty) ...[
                      Row(
                        children: [
                          // 위치 표시 버튼
                          if (!isLocationDisplayed) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await _showFriendLocationOnMap(friend);
                                },
                                icon: const Icon(Icons.location_on, size: 18),
                                label: const Text('위치 보기'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],

                          // 위치 제거 버튼
                          if (isLocationDisplayed) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await _removeFriendLocationFromMap(friend);
                                },
                                icon: const Icon(Icons.location_off, size: 18),
                                label: const Text('위치 제거'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 닫기 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('닫기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
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
  }

  /// 상세 정보 행 위젯
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
        ),
      ],
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

      _showSuccessMessage('${friend.userName}님의 위치를 지도에서 제거했습니다.');

      debugPrint('✅ 친구 위치 제거 완료: ${friend.userName}');
    } catch (e) {
      debugPrint('❌ 친구 위치 제거 오류: $e');
      _showErrorMessage('친구 위치를 제거할 수 없습니다.');
    }
  }

  /// 친구 위치 표시 성공 메시지
  void _showFriendLocationSuccess(Friend friend) {
    _showSuccessMessage('${friend.userName}님의 위치를 지도에 표시했습니다.');
  }

  /// 친구 추가 처리 함수
  Future<void> _handleAddFriend([StateSetter? setModalState]) async {
    final id = _addController.text.trim();

    if (id.isEmpty) {
      _showErrorMessage('친구 ID를 입력해주세요.');
      return;
    }

    if (id == widget.userId) {
      _showErrorMessage('자기 자신은 친구로 추가할 수 없습니다.');
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      _isAddingFriend = true;
    });

    setModalState?.call(() {
      _isAddingFriend = true;
    });

    try {
      await controller.addFriend(id);

      if (controller.errorMessage == null) {
        _showSuccessMessage('$id님에게 친구 요청을 전송했습니다!');
        _addController.clear();
        setModalState?.call(() {});
      } else {
        _showErrorMessage(controller.errorMessage ?? '친구 추가 중 오류가 발생했습니다.');
      }
    } catch (e) {
      _showErrorMessage('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
    } finally {
      if (mounted) {
        setState(() {
          _isAddingFriend = false;
        });
      }

      setModalState?.call(() {
        _isAddingFriend = false;
      });
    }
  }

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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people_alt,
                  color: Color(0xFF1E3A8A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '친구',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          '친구 관리 및 요청',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 🔥 실시간 업데이트 상태 표시
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
              // 🔥 새로고침 버튼 추가
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
          // 🔥 실시간 업데이트 정보 표시
          if (controller.isRealTimeEnabled) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi, color: Colors.green.shade600, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '실시간 동기화 활성 • ${controller.lastUpdateTime}',
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
                              const Text(
                                '친구 관리',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 🔥 실시간 상태 표시
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

                    // 🔥 실시간 업데이트되는 탭 바
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TabBar(
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
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
                          color: const Color(0xFF1E3A8A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tabs: [
                          Tab(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_add, size: 16),
                                  SizedBox(width: 4),
                                  Text('추가'),
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
                                    '보낸 (${controller.sentFriendRequests.length})',
                                  ),
                                  // 🔥 변경 표시기
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
                                    '받은 (${controller.friendRequests.length})',
                                  ),
                                  // 🔥 새 요청 표시기
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
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
        const Text(
          '추가할 친구의 ID를 입력해주세요',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 20),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: WoosongInputField(
            icon: Icons.person_add_alt,
            label: '친구 ID',
            controller: _addController,
            hint: '상대방 ID를 입력하세요',
            enabled: !_isAddingFriend,
          ),
        ),

        const SizedBox(height: 20),

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
                : const Text('친구 요청 보내기'),
          ),
        ),

        const SizedBox(height: 20),
      ],
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
        // 🔥 실시간 상태 표시
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.update, color: Colors.blue.shade600, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '실시간 동기화 중 • 자동으로 업데이트됩니다',
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
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_outlined,
                      color: Color(0xFF1E3A8A),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '보낸 친구 요청이 없습니다.',
                    style: TextStyle(
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
        // 🔥 새 요청 알림
        if (controller.friendRequests.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                    '새로운 친구 요청 ${controller.friendRequests.length}개',
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
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      color: Color(0xFF1E3A8A),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '받은 친구 요청이 없습니다.',
                    style: TextStyle(
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
            color: Colors.black.withOpacity(0.05),
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
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
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
                  'ID: ${_maskUserId(request.toUserId)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                if (request.requestDate.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '요청일: ${request.requestDate}',
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
              color: const Color(0xFFEF4444).withOpacity(0.1),
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
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: const Color(0xFFF59E0B).withOpacity(0.1),
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
                    // 🔥 새 요청 표시기
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade500,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
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
                  'ID: ${_maskUserId(request.fromUserId)}',
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
                  color: const Color(0xFF10B981).withOpacity(0.1),
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
                      '${request.fromUserName}님의 친구 요청을 수락했습니다.',
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
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
                      '${request.fromUserName}님의 친구 요청을 거절했습니다.',
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '친구 요청 취소',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A8A),
          ),
        ),
        content: Text(
          '${request.toUserName}님에게 보낸 친구 요청을 취소하시겠습니까?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '아니요',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '취소하기',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.lightImpact();
      await controller.cancelSentRequest(request.toUserId);
      setModalState?.call(() {});
      _showSuccessMessage('${request.toUserName}님에게 보낸 친구 요청을 취소했습니다.');
    }
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          _buildSectionHeader(
            '내 친구 (${controller.friends.length})',
            icon: Icons.people_alt,
          ),
          if (controller.friends.isEmpty)
            _buildEmptyState('아직 친구가 없습니다.\n상단의 + 버튼으로 친구를 추가해보세요!')
          else
            // 🔥 애니메이션과 함께 친구 목록 표시
            ...controller.friends.asMap().entries.map((entry) {
              final index = entry.key;
              final friend = entry.value;
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutBack,
                child: _buildFriendTile(friend),
              );
            }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 🔥 친구 타일 - 클릭 시 상세 정보 다이얼로그 표시
  Widget _buildFriendTile(Friend friend) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: friend.isLogin
              ? const Color(0xFF10B981).withOpacity(0.3)
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFriendDetailsDialog(friend), // 🔥 상세 정보 다이얼로그 표시
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 프로필 아이콘
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: friend.isLogin
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFF1E3A8A).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: friend.isLogin
                          ? const Color(0xFF10B981).withOpacity(0.3)
                          : const Color(0xFF1E3A8A).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: friend.isLogin
                        ? const Color(0xFF10B981)
                        : const Color(0xFF1E3A8A),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // 친구 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${_maskUserId(friend.userId)}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: friend.isLogin
                                  ? Colors.green
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            friend.isLogin ? '온라인' : '오프라인',
                            style: TextStyle(
                              fontSize: 12,
                              color: friend.isLogin
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 삭제 버튼
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.person_remove,
                      color: Color(0xFFEF4444),
                      size: 18,
                    ),
                    onPressed: () => _showDeleteFriendDialog(friend),
                  ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '친구 삭제',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A8A),
          ),
        ),
        content: Text(
          '${friend.userName}님을 친구 목록에서 삭제하시겠습니까?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.deleteFriend(friend.userId);
      _showSuccessMessage('${friend.userName}님을 친구 목록에서 삭제했습니다.');
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
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
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
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 16, bottom: 32),
                          child: _buildFriendsContent(),
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
