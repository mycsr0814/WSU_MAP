// friends_screen.dart
// 친구 목록, 친구 추가, 친구 요청 UI를 모두 포함한 메인 화면
//
// 이 파일은 친구 목록 조회, 친구 추가, 친구 요청 수락/거절 등
// 친구 관련 주요 UI와 로직을 모두 제공합니다.

import 'package:flutter/material.dart';
import 'friends_controller.dart';
import 'friend_repository.dart';
import 'friend_api_service.dart';
import 'friend.dart';

/// 친구 메인 화면 위젯
///
/// 친구 목록, 친구 추가, 친구 요청 수락/거절 등
/// 모든 친구 관련 기능을 한 화면에서 제공합니다.
/// 반드시 내 ID(myId)를 생성자 파라미터로 전달해야 합니다.
class FriendsScreen extends StatefulWidget {
  final String myId; // 내 ID

  const FriendsScreen({Key? key, required this.myId}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

/// FriendsScreen의 상태 클래스
class _FriendsScreenState extends State<FriendsScreen> {
  // 친구 및 친구 요청 상태를 관리하는 컨트롤러
  late final FriendsController controller;

  // 친구 추가 다이얼로그 입력값을 위한 컨트롤러
  final TextEditingController _addFriendController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 반드시 내 ID(widget.myId)를 넘겨서 컨트롤러 생성
    controller = FriendsController(
      FriendRepository(FriendApiService()),
      widget.myId,
    );
    controller.loadAll();
    // 상태 변경 시 setState로 UI 갱신
    controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    controller.dispose();
    _addFriendController.dispose();
    super.dispose();
  }

  /// 친구 추가 다이얼로그를 띄우는 함수
  /// 사용자가 친구의 ID를 입력해 친구 요청을 보낼 수 있음
  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('친구 추가'),
        content: TextField(
          controller: _addFriendController,
          decoration: const InputDecoration(hintText: '상대방 ID 입력'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addFriendController.clear();
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = _addFriendController.text.trim();
              if (id.isNotEmpty) {
                await controller.addFriend(id);
                Navigator.pop(context);
                _addFriendController.clear();
                // 친구 요청 성공 시 스낵바 표시 (실패 시는 controller.errorMessage로 처리)
                if (controller.errorMessage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('친구 요청이 전송되었습니다!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              }
            },
            child: const Text('추가하기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = controller.isLoading;
    final error = controller.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구'),
        actions: [
          // 친구 추가 버튼 (우상단)
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddFriendDialog,
          ),
        ],
      ),
      body: isLoading
          // 1. 로딩 중이면 로딩 인디케이터
          ? const Center(child: CircularProgressIndicator())
          // 2. 에러 발생 시 에러 메시지 표시
          : error != null
          ? Center(child: Text('오류: $error'))
          // 3. 정상 데이터 표시
          : RefreshIndicator(
              onRefresh: controller.loadAll,
              child: ListView(
                children: [
                  // --- 친구 목록 섹션 ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '내 친구 (${controller.friends.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  // --- 친구 리스트 ---
                  ...controller.friends.map(
                    (f) => ListTile(
                      leading: CircleAvatar(
                        // 프로필 이미지가 있으면 이미지, 없으면 기본 아이콘
                        backgroundImage: f.profileImage.isNotEmpty
                            ? NetworkImage(f.profileImage)
                            : null,
                        child: f.profileImage.isEmpty
                            ? const Icon(Icons.person, color: Color(0xFF1E3A8A))
                            : null,
                      ),
                      title: Text(f.userName), // 친구 이름
                      subtitle: Text('ID: ${f.userId}'), // 친구 ID
                      // --- 친구 삭제 버튼(trailing) 추가 ---
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: '친구 삭제',
                        onPressed: () async {
                          // 삭제 전 확인 다이얼로그 표시
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('친구 삭제'),
                              content: Text(
                                '${f.userName}님을 친구 목록에서 삭제하시겠습니까?',
                              ),
                              actions: [
                                // 취소 버튼
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('취소'),
                                ),
                                // 삭제 버튼
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('삭제'),
                                ),
                              ],
                            ),
                          );
                          // 삭제 확인 시
                          if (confirmed == true) {
                            try {
                              // FriendsController를 통해 친구 삭제 API 호출
                              await controller.deleteFriend(f.userId);
                              // 성공 시 스낵바 안내
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('친구가 삭제되었습니다.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } catch (e) {
                              // 실패 시 에러 안내
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('친구 삭제 중 오류 발생: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      // 필요에 따라 친구 상세/메시지 등 추가 가능
                    ),
                  ),

                  // --- 친구 요청 목록 섹션 ---
                  if (controller.friendRequests.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '받은 친구 요청',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    // 친구 요청 리스트
                    ...controller.friendRequests.map(
                      (req) => ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(req.fromUserName),
                        subtitle: Text('ID: ${req.fromUserId}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 친구 요청 수락 버튼
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              onPressed: () async {
                                // add_id(=req.fromUserId)가 null/빈 값이면 서버로 요청 보내지 않음
                                if (req.fromUserId == null ||
                                    req.fromUserId.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('친구 요청 정보가 올바르지 않습니다.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                await controller.acceptRequest(req.fromUserId);
                                if (controller.errorMessage == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('친구 요청을 수락했습니다!'),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                }
                              },
                            ),
                            // 친구 요청 거절 버튼
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () async {
                                // add_id(=req.fromUserId)가 null/빈 값이면 서버로 요청 보내지 않음
                                if (req.fromUserId == null ||
                                    req.fromUserId.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('친구 요청 정보가 올바르지 않습니다.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                await controller.rejectRequest(req.fromUserId);
                                if (controller.errorMessage == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('친구 요청을 거절했습니다.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // --- 친구가 없을 때 안내 메시지 ---
                  if (controller.friends.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          '아직 친구가 없습니다.\n상단의 + 버튼으로 친구를 추가해보세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// 친구 바텀시트를 국제화 진입점으로 띄우는 함수
void showFriendsBottomSheetI18n(BuildContext context, String myId) {
  FriendsBottomSheet.show(context, myId);
}

/// 친구 바텀시트 위젯 클래스
///
/// showFriendsBottomSheetI18n(context, myId)로 호출하면
/// 바텀시트에 FriendsScreen(myId: myId)가 뜬다.
class FriendsBottomSheet {
  static void show(BuildContext context, String myId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: FriendsScreen(myId: myId), // 실제 친구 UI가 바텀시트에 뜸!
      ),
    );
  }
}
