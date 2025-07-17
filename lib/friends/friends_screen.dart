// lib/screens/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/selection_header.dart';
import 'package:flutter_application_1/components/woosong_button.dart';
import 'package:flutter_application_1/components/woosong_input_field.dart';
import 'package:flutter_application_1/friends/friend.dart';
import 'package:flutter_application_1/friends/friend_api_service.dart';
import 'package:flutter_application_1/friends/friend_repository.dart';
import 'package:flutter_application_1/friends/friends_controller.dart';
import '../generated/app_localizations.dart';

class FriendsScreen extends StatefulWidget {
  final String userId;
  const FriendsScreen({required this.userId, super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  late final FriendsController controller;
  final _addController = TextEditingController();

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

  // 헤더 빌드 (시간표/프로필 화면과 동일한 스타일)
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
          IconButton(
            onPressed: _showAddDialog,
            icon: const Icon(
              Icons.person_add,
              color: Color(0xFF1E3A8A),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog() async {
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: MediaQuery.of(ctx).viewInsets,
        child: Container(
          padding: const EdgeInsets.only(
            top: 32,
            left: 20,
            right: 20,
            bottom: 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WoosongInputField(
                icon: Icons.person_add_alt,
                label: '친구 ID',
                controller: _addController,
                hint: '상대방 ID를 입력하세요',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: WoosongButton(
                      isOutlined: true,
                      onPressed: () {
                        Navigator.pop(ctx);
                        _addController.clear();
                      },
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: WoosongButton(
                      onPressed: () async {
                        final id = _addController.text.trim();
                        if (id.isEmpty) return;
                        await controller.addFriend(id);
                        if (controller.errorMessage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('친구 요청이 전송되었습니다!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                        Navigator.pop(ctx);
                        _addController.clear();
                      },
                      child: const Text('추가하기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

          if (controller.friendRequests.isNotEmpty) ...[
            const Divider(height: 1),
            _buildSectionHeader(
              '받은 친구 요청 (${controller.friendRequests.length})',
              icon: Icons.notifications_active,
            ),
            ...controller.friendRequests.map(
              (request) => _buildRequestTile(request),
            ),
          ],

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
          Container(
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
          const SizedBox(width: 16),
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
                  'ID: ${friend.userId}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
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
                Icons.person_remove,
                color: Color(0xFFEF4444),
                size: 20,
              ),
              onPressed: () => _showDeleteDialog(friend),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTile(FriendRequest request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
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
                  'ID: ${request.fromUserId}',
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
                  onPressed: () => controller.acceptRequest(request.fromUserId),
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
                  onPressed: () => controller.rejectRequest(request.fromUserId),
                ),
              ),
            ],
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = controller.isLoading;
    final error = controller.errorMessage;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                            Icon(
                              Icons.error_outline,
                              color: const Color(0xFFEF4444),
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
