import 'dart:convert';
import 'package:http/http.dart' as http;
import 'friend.dart';
import 'package:flutter_application_1/config/api_config.dart';

class FriendApiService {
  static String get baseUrl => ApiConfig.friendBase;

  /// 내 친구 목록 조회
  Future<List<Friend>> fetchMyFriends(String myId) async {
    final res = await http.get(Uri.parse('$baseUrl/myfriend/$myId'));
    print('[친구 목록 응답] ${res.body}'); // 서버 응답 전체를 로그로 출력

    if (res.body.isEmpty || !res.body.trim().startsWith('[')) {
      print('[WARN] 친구 목록 응답이 비었거나 JSON 배열이 아님');
      return [];
    }

    try {
      final List data = jsonDecode(res.body);
      print('[친구 목록 파싱 데이터] $data');
      return data.map((e) => Friend.fromJson(e)).toList();
    } catch (e, stack) {
      print('[ERROR] 친구 목록 파싱 실패: $e');
      print(stack);
      return [];
    }
  }

  /// 친구 추가 요청
  Future<void> addFriend(String myId, String addId) async {
    if (addId == null || addId.isEmpty) {
      print('[ERROR] 친구 추가 add_id가 비어있음! 요청 차단');
      throw Exception('상대방 ID가 올바르지 않습니다.');
    }
    final res = await http.post(
      Uri.parse('$baseUrl/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'my_id': myId, 'add_id': addId}),
    );
    if (res.statusCode != 200) {
      print('[ERROR] 친구 추가 실패: ${res.body}');
      throw Exception('친구 추가 실패');
    }
  }

  /// 받은 친구 요청 목록 조회
  Future<List<FriendRequest>> fetchFriendRequests(String myId) async {
    final res = await http.get(Uri.parse('$baseUrl/request_list/$myId'));
    print('[친구 요청 응답] ${res.body}');

    if (res.body.isEmpty || !res.body.trim().startsWith('[')) {
      print('[WARN] 친구 요청 응답이 비었거나 JSON 배열이 아님');
      return [];
    }

    try {
      final List data = jsonDecode(res.body);
      print('[친구 요청 파싱 데이터] $data');
      // fromUserId가 빈 값인 요청은 거르기
      return data
          .map((e) => FriendRequest.fromJson(e))
          .where((req) => req.fromUserId.isNotEmpty)
          .toList();
    } catch (e, stack) {
      print('[ERROR] 친구 요청 파싱 실패: $e');
      print(stack);
      return [];
    }
  }

  /// 친구 요청 수락
  Future<void> acceptFriendRequest(String myId, String addId) async {
    if (addId == null || addId.isEmpty) {
      print('[ERROR] 친구 요청 수락 add_id가 비어있음! 요청 차단');
      throw Exception('친구 요청 정보가 올바르지 않습니다.');
    }
    final res = await http.post(
      Uri.parse('$baseUrl/accept'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'my_id': myId, 'add_id': addId}),
    );
    if (res.statusCode != 200) {
      print('[ERROR] 친구 요청 수락 실패: ${res.body}');
      throw Exception('친구 요청 수락 실패');
    }
  }

  /// 친구 요청 거절
  Future<void> rejectFriendRequest(String myId, String addId) async {
    if (addId == null || addId.isEmpty) {
      print('[ERROR] 친구 요청 거절 add_id가 비어있음! 요청 차단');
      throw Exception('친구 요청 정보가 올바르지 않습니다.');
    }
    final res = await http.post(
      Uri.parse('$baseUrl/reject'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'my_id': myId, 'add_id': addId}),
    );
    if (res.statusCode != 200) {
      print('[ERROR] 친구 요청 거절 실패: ${res.body}');
      throw Exception('친구 요청 거절 실패');
    }
  }

  /// 친구 삭제
  Future<void> deleteFriend(String myId, String addId) async {
    if (addId == null || addId.isEmpty) {
      print('[ERROR] 친구 삭제 add_id가 비어있음! 요청 차단');
      throw Exception('친구 정보가 올바르지 않습니다.');
    }
    final res = await http.delete(
      Uri.parse('$baseUrl/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'my_id': myId, 'add_id': addId}),
    );
    if (res.statusCode != 200) {
      print('[ERROR] 친구 삭제 실패: ${res.body}');
      throw Exception('친구 삭제 실패');
    }
  }
}
