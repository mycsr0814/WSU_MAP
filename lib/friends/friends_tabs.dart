import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/components/woosong_button.dart';
import 'package:flutter_application_1/components/woosong_input_field.dart';
import 'package:flutter_application_1/friends/friends_controller.dart';
import 'package:flutter_application_1/friends/friends_screen.dart';
import 'package:flutter_application_1/friends/friends_dialogs.dart';
import 'package:flutter_application_1/friends/friends_tiles.dart';
import 'package:flutter_application_1/friends/friend.dart';
import 'package:flutter_application_1/generated/app_localizations.dart';
import 'package:flutter_application_1/services/auth_service.dart';

/// 탭 관련 위젯들
class FriendsTabs {
  /// 친구 추가 탭
  static Widget buildAddFriendTab(
    BuildContext context,
    StateSetter setModalState,
    ScrollController scrollController,
    TextEditingController addController,
    bool isAddingFriend,
    VoidCallback onAddFriend,
    VoidCallback onRefreshUserList,
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
                controller: addController,
                hint: AppLocalizations.of(context)!.enterFriendId,
                enabled: !isAddingFriend,
              ),
            ),

            const SizedBox(height: 20),

            // 사용자 목록 표시
            if (userList.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.available_user_list,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    onPressed: onRefreshUserList,
                    tooltip: AppLocalizations.of(context)!.refresh_user_list,
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
                        addController.text = user['id']!;
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
                onPressed: isAddingFriend ? null : onAddFriend,
                child: isAddingFriend
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
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

  /// 실시간 업데이트되는 보낸 요청 탭
  static Widget buildSentRequestsTab(
    BuildContext context,
    StateSetter setModalState,
    ScrollController scrollController,
    FriendsController controller,
    Function(SentFriendRequest) onCancelRequest,
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
            (request) => FriendsTiles.buildSentRequestTile(
              context,
              request,
              () => onCancelRequest(request),
            ),
          ),
      ],
    );
  }

  /// 실시간 업데이트되는 받은 요청 탭
  static Widget buildReceivedRequestsTab(
    BuildContext context,
    StateSetter setModalState,
    ScrollController scrollController,
    FriendsController controller,
    Function(FriendRequest) onAcceptRequest,
    Function(FriendRequest) onRejectRequest,
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
            (request) => FriendsTiles.buildReceivedRequestTile(
              context,
              request,
              () => onAcceptRequest(request),
              () => onRejectRequest(request),
            ),
          ),
      ],
    );
  }

  /// 캐시된 사용자 목록 가져오기
  static Future<List<Map<String, String>>> _getCachedUserList() async {
    try {
      return await AuthService().getUserList();
    } catch (e) {
      debugPrint('사용자 목록 가져오기 오류: $e');
      return [];
    }
  }
}
