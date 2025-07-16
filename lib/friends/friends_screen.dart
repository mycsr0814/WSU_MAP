// lib/screens/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/selection_header.dart';
import 'package:flutter_application_1/components/woosong_button.dart';
import 'package:flutter_application_1/components/woosong_input_field.dart';
import 'package:flutter_application_1/friends/friend.dart';
import 'package:flutter_application_1/friends/friend_api_service.dart';
import 'package:flutter_application_1/friends/friend_repository.dart';
import 'package:flutter_application_1/friends/friends_controller.dart';

class FriendsScreen extends StatefulWidget {
  final String myId;
  const FriendsScreen({required this.myId, super.key});

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
        FriendsController(FriendRepository(FriendApiService()), widget.myId)
          ..addListener(() => setState(() {}))
          ..loadAll();
  }

  @override
  void dispose() {
    controller.dispose();
    _addController.dispose();
    super.dispose();
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
              const SizedBox(height: 8),
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

  Widget _friendTile(Friend f) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
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
            child: f.profileImage.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : ClipOval(
                    child: Image.network(f.profileImage, fit: BoxFit.cover),
                  ),
          ),
        ),
        title: Text(
          f.userName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          'ID: ${f.userId}',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Color(0xFFEF4444)),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('친구 삭제'),
                content: Text('${f.userName}님을 삭제하시겠어요?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('삭제'),
                  ),
                ],
              ),
            );
            if (confirmed == true) controller.deleteFriend(f.userId);
          },
        ),
        onTap: () {
          // TODO: 채팅 또는 프로필 화면으로 이동
        },
      ),
    );
  }

  Widget _requestTile(FriendRequest r) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      color: const Color(0xFFFFFBEB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.03),
      child: ListTile(
        leading: const Icon(Icons.person_add, color: Color(0xFFF59E0B)),
        title: Text(
          r.fromUserName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          'ID: ${r.fromUserId}',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Color(0xFF10B981)),
              onPressed: () => controller.acceptRequest(r.fromUserId),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFFE11D48)),
              onPressed: () => controller.rejectRequest(r.fromUserId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Column(
      children: [
        const Icon(
          Icons.sentiment_satisfied,
          color: Color(0xFF94A3B8),
          size: 64,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final loading = controller.isLoading;
    final error = controller.errorMessage;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('친구'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text(error))
              : RefreshIndicator(
                  onRefresh: controller.loadAll,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 12),
                    children: [
                      SectionHeader(
                        '내 친구 (${controller.friends.length})',
                        icon: Icons.people_alt,
                      ),
                      if (controller.friends.isEmpty)
                        _emptyCard('아직 친구가 없습니다.\n상단의 + 버튼으로 친구를 추가해보세요!')
                      else
                        ...controller.friends.map(_friendTile),

                      if (controller.friendRequests.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SectionHeader(
                          '받은 친구 요청',
                          icon: Icons.notifications_active,
                        ),
                        ...controller.friendRequests.map(_requestTile),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
