// lib/friends/friends_bottom_sheet_i18n.dart - 다국어 지원 친구창

import 'package:flutter/material.dart';
import '../generated/app_localizations.dart';

class FriendsBottomSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FriendsBottomSheetContentI18n(),
    );
  }
}

class FriendsBottomSheetContentI18n extends StatefulWidget {
  const FriendsBottomSheetContentI18n({super.key});

  @override
  State<FriendsBottomSheetContentI18n> createState() => _FriendsBottomSheetContentI18nState();
}

class _FriendsBottomSheetContentI18nState extends State<FriendsBottomSheetContentI18n> {
  final List<Map<String, dynamic>> _friends = [
    {
      'name': '김철수',
      'nameEn': 'Kim Cheolsu',
      'nameZh': '金哲洙',
      'status': 'online',
      'location': '중앙도서관',
      'locationEn': 'Central Library',
      'locationZh': '中央图书馆',
      'avatar': '👨‍🎓',
      'isOnline': true,
    },
    {
      'name': '이영희',
      'nameEn': 'Lee Younghee',
      'nameZh': '李英姬',
      'status': 'in_class',
      'location': '공학관 201호',
      'locationEn': 'Engineering Building 201',
      'locationZh': '工学馆201号',
      'avatar': '👩‍🎓',
      'isOnline': true,
    },
    {
      'name': '박민수',
      'nameEn': 'Park Minsu',
      'nameZh': '朴民洙',
      'status': 'offline',
      'location': '마지막 위치: 학생회관',
      'locationEn': 'Last seen: Student Union',
      'locationZh': '最后位置：学生会馆',
      'avatar': '👨‍🎓',
      'isOnline': false,
    },
    {
      'name': '최지원',
      'nameEn': 'Choi Jiwon',
      'nameZh': '崔智媛',
      'status': 'online',
      'location': '카페테리아',
      'locationEn': 'Cafeteria',
      'locationZh': '咖啡厅',
      'avatar': '👩‍🎓',
      'isOnline': true,
    },
  ];

  final TextEditingController _addFriendController = TextEditingController();

  @override
  void dispose() {
    _addFriendController.dispose();
    super.dispose();
  }

  String _getLocalizedName(Map<String, dynamic> friend, String locale) {
    switch (locale) {
      case 'en':
        return friend['nameEn'] ?? friend['name'];
      case 'zh':
        return friend['nameZh'] ?? friend['name'];
      default:
        return friend['name'];
    }
  }

  String _getLocalizedLocation(Map<String, dynamic> friend, String locale) {
    switch (locale) {
      case 'en':
        return friend['locationEn'] ?? friend['location'];
      case 'zh':
        return friend['locationZh'] ?? friend['location'];
      default:
        return friend['location'];
    }
  }

  String _getLocalizedStatus(String status, AppLocalizations l10n) {
    switch (status) {
      case 'online':
        return l10n.online;
      case 'in_class':
        return l10n.in_class;
      case 'offline':
        return l10n.offline;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(l10n),
          Expanded(
            child: _buildFriendsList(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final onlineFriends = _friends.where((friend) => friend['isOnline']).length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.people,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.my_friends,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.friends_count_status(_friends.length, onlineFriends),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () => _showAddFriendDialog(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).languageCode;
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return _buildFriendCard(friend, l10n, locale);
      },
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend, AppLocalizations l10n, String locale) {
    final friendName = _getLocalizedName(friend, locale);
    final friendLocation = _getLocalizedLocation(friend, locale);
    final friendStatus = _getLocalizedStatus(friend['status'], l10n);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          onTap: () => _showFriendDetails(friend, l10n, locale),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          friend['avatar'],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    if (friend['isOnline'])
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friendName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        friendStatus,
                        style: TextStyle(
                          fontSize: 12,
                          color: friend['isOnline'] 
                            ? const Color(0xFF10B981) 
                            : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              friendLocation,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.message, color: Color(0xFF1E3A8A)),
                  onPressed: () => _sendMessage(friend, l10n, locale),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddFriendDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(l10n.add_friend),
        content: TextField(
          controller: _addFriendController,
          decoration: InputDecoration(
            hintText: l10n.enter_friend_info,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _addFriendController.clear();
              Navigator.pop(context);
            },
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              _addFriendController.clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.friend_request_sent),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
            ),
            child: Text(l10n.add, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFriendDetails(Map<String, dynamic> friend, AppLocalizations l10n, String locale) {
    final friendName = _getLocalizedName(friend, locale);
    final friendLocation = _getLocalizedLocation(friend, locale);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              friend['avatar'],
              style: const TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 16),
            Text(
              friendName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              friendLocation,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.message,
                  label: l10n.message,
                  onPressed: () => _sendMessage(friend, l10n, locale),
                ),
                _buildActionButton(
                  icon: Icons.location_on,
                  label: l10n.view_location,
                  onPressed: () => _showLocation(friend, l10n, locale),
                ),
                _buildActionButton(
                  icon: Icons.phone,
                  label: l10n.call,
                  onPressed: () => _makeCall(friend, l10n, locale),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: IconButton(
            icon: Icon(icon, color: const Color(0xFF1E3A8A)),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _sendMessage(Map<String, dynamic> friend, AppLocalizations l10n, String locale) {
    final friendName = _getLocalizedName(friend, locale);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.start_chat_with(friendName)),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
    );
  }

  void _showLocation(Map<String, dynamic> friend, AppLocalizations l10n, String locale) {
    final friendName = _getLocalizedName(friend, locale);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.show_location_on_map(friendName)),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _makeCall(Map<String, dynamic> friend, AppLocalizations l10n, String locale) {
    final friendName = _getLocalizedName(friend, locale);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.calling(friendName)),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }
}

// 사용 방법:
// 하단 네비게이션에서 친구 찾기 버튼을 눌렀을 때 호출하는 함수
void showFriendsBottomSheetI18n(BuildContext context) {
  FriendsBottomSheet.show(context);
}
