// lib/screens/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/components/woosong_button.dart';
import 'package:flutter_application_1/components/woosong_input_field.dart';
import 'package:flutter_application_1/friends/friend.dart';
import 'package:flutter_application_1/friends/friend_api_service.dart';
import 'package:flutter_application_1/friends/friend_repository.dart';
import 'package:flutter_application_1/friends/friends_controller.dart';

class FriendsScreen extends StatefulWidget {
  final String userId;
  const FriendsScreen({required this.userId, super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  late final FriendsController controller;
  final _addController = TextEditingController();
  bool _isAddingFriend = false;

  @override
  void initState() {
    super.initState();
    controller =
        FriendsController(FriendRepository(FriendApiService()), widget.userId)
          ..addListener(() => setState(() {}))
          ..loadAll();
  }

  @override
  void dispose() {
    controller.dispose();
    _addController.dispose();
    super.dispose();
  }

  /// 사용자 ID 마스킹 함수
  String _maskUserId(String userId) {
    if (userId.length <= 4) return userId;
    return userId.substring(0, 4) + '*' * (userId.length - 4);
  }

  /// 성공 메시지 표시
  void _showSuccessMessage(String message) {
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

    // 모달 상태도 업데이트
    setModalState?.call(() {
      _isAddingFriend = true;
    });

    try {
      await controller.addFriend(id);

      if (controller.errorMessage == null) {
        _showSuccessMessage('$id님에게 친구 요청을 전송했습니다!');
        _addController.clear();

        // 모달 상태 업데이트
        setModalState?.call(() {});

        // 모달 닫기 주석 처리 (실시간 업데이트를 위해)
        // Navigator.pop(context);
      } else {
        _showErrorMessage(controller.errorMessage ?? '친구 추가 중 오류가 발생했습니다.');
      }
    } catch (e) {
      _showErrorMessage('네트워크 오류가 발생했습니다. 다시 시도해주세요.');
    } finally {
      setState(() {
        _isAddingFriend = false;
      });

      setModalState?.call(() {
        _isAddingFriend = false;
      });
    }
  }

  // 헤더 빌드
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
      child: Row(
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
                Text(
                  '친구 관리 및 요청',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
    );
  }

  // 친구 관리 다이얼로그 - DraggableScrollableSheet 적용 + 키보드 대응
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
                          const Text(
                            '친구 관리',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 탭 바 (실시간 업데이트)
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_add, size: 16),
                                  const SizedBox(width: 4),
                                  const Text('추가'),
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

  // 친구 추가 탭 - 키보드 대응 개선
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

        // 입력 필드
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

        // 버튼
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

  // 보낸 요청 탭 - scrollController 추가
  Widget _buildSentRequestsTab(
    StateSetter setModalState,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
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

  // 받은 요청 탭 - scrollController 추가
  Widget _buildReceivedRequestsTab(
    StateSetter setModalState,
    ScrollController scrollController,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      children: [
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

  // 보낸 요청 타일 - setModalState 매개변수 추가
  Widget _buildSentRequestTile(
    SentFriendRequest request, [
    StateSetter? setModalState,
  ]) {
    return Container(
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

  // 받은 요청 타일 - setModalState 매개변수 추가
  Widget _buildReceivedRequestTile(
    FriendRequest request, [
    StateSetter? setModalState,
  ]) {
    return Container(
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
                Text(
                  request.fromUserName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF1E3A8A),
                  ),
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
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    controller.acceptRequest(request.fromUserId);
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
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    controller.rejectRequest(request.fromUserId);
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

  // 요청 취소 다이얼로그 - setModalState 매개변수 추가
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

      // 모달 상태 즉시 업데이트
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

  // 메인 화면 친구 목록 (받은 친구 요청 섹션 제거)
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
            ...controller.friends.map((friend) => _buildFriendTile(friend)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFriendTile(Friend friend) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showFriendInfoDialog(friend);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: friend.profileImage.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 24)
                    : ClipOval(
                        child: Image.network(
                          friend.profileImage,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showFriendInfoDialog(friend);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        friend.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: friend.isLogin ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${_maskUserId(friend.userId)}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
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
                Icons.person_remove,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                _showDeleteDialog(friend);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 친구 정보 다이얼로그
  Future<void> _showFriendInfoDialog(Friend friend) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: friend.profileImage.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 40)
                    : ClipOval(
                        child: Image.network(
                          friend.profileImage,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  friend.userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: friend.isLogin ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    friend.isLogin ? '온라인' : '오프라인',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildInfoRow(Icons.badge, 'ID', _maskUserId(friend.userId)),
            _buildInfoRow(
              Icons.phone,
              '전화번호',
              friend.phone.isEmpty ? '정보 없음' : friend.phone,
            ),
            _buildInfoRow(
              Icons.location_on,
              '마지막 위치',
              friend.lastLocation.isEmpty ? '정보 없음' : friend.lastLocation,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: WoosongButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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

  Future<void> _showDeleteDialog(Friend friend) async {
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
