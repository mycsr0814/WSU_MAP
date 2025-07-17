// lib/friends/friend_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'friend.dart';
import 'package:flutter_application_1/config/api_config.dart';

class FriendApiService {
  static String get baseUrl => ApiConfig.friendBase;

  /// 내 친구 목록 조회
  Future<List<Friend>> fetchMyFriends(String myId) async {
    final res = await http.get(Uri.parse('$baseUrl/myfriend/$myId'));
    print('[친구 목록 응답] ${res.body}');

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

  /// 친구 상세 정보 조회
  Future<Friend?> fetchFriendInfo(String friendId) async {
    final res = await http.get(Uri.parse('$baseUrl/info/$friendId'));
    print('[친구 정보 응답] ${res.body}');

    if (res.statusCode != 200) {
      print('[ERROR] 친구 정보 조회 실패: ${res.body}');
      return null;
    }

    try {
      final Map<String, dynamic> data = jsonDecode(res.body);
      print('[친구 정보 파싱 데이터] $data');
      return Friend.fromJson(data);
    } catch (e, stack) {
      print('[ERROR] 친구 정보 파싱 실패: $e');
      print(stack);
      return null;
    }
  }

  /// 친구 추가 요청
  Future<void> addFriend(String myId, String addId) async {
    if (addId.isEmpty) {
      print('[ERROR] 친구 추가 add_id가 비어있음! 요청 차단');
      throw Exception('상대방 ID가 올바르지 않습니다.');
    }

    print('[DEBUG] 친구 추가 요청 - myId: $myId, addId: $addId');

    final res = await http.post(
      Uri.parse('$baseUrl/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'my_id': myId, 'add_id': addId}),
    );

    print('[DEBUG] 친구 추가 응답: ${res.statusCode} ${res.body}');

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

  /// 내가 보낸 친구 요청 목록 조회 (서버 수정 완료 후 단순화)
  Future<List<SentFriendRequest>> fetchSentFriendRequests(String myId) async {
    try {
      print('[DEBUG] ===== 보낸 친구 요청 조회 시작 =====');
      print('[DEBUG] myId: $myId');
      print('[DEBUG] 요청 URL: $baseUrl/my_request_list/$myId');

      final res = await http.get(
        Uri.parse('$baseUrl/my_request_list/$myId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('[DEBUG] 응답 상태: ${res.statusCode}');
      print('[DEBUG] 응답 본문: ${res.body}');

      if (res.statusCode != 200) {
        print('[ERROR] 보낸 친구 요청 조회 실패: ${res.statusCode} ${res.body}');
        return [];
      }

      // 빈 응답 처리
      if (res.body.isEmpty || res.body.trim() == '[]') {
        print('[DEBUG] 보낸 친구 요청이 없음');
        return [];
      }

      // JSON 파싱
      final dynamic responseData = jsonDecode(res.body);

      if (responseData is List) {
        print('[DEBUG] 보낸 친구 요청 원시 데이터: $responseData');

        final requests = responseData
            .map((e) => SentFriendRequest.fromJson(e as Map<String, dynamic>))
            .where((req) => req.toUserId.isNotEmpty)
            .toList();

        print('[DEBUG] 파싱된 보낸 친구 요청 수: ${requests.length}');

        // 각 요청의 세부 내용 로그
        for (int i = 0; i < requests.length; i++) {
          final req = requests[i];
          print(
            '[DEBUG] 요청 ${i + 1}: ID=${req.toUserId}, 이름=${req.toUserName}',
          );
        }

        return requests;
      } else {
        print('[ERROR] 응답이 배열이 아님: $responseData');
        return [];
      }
    } catch (e, stack) {
      print('[ERROR] 보낸 친구 요청 조회 중 오류: $e');
      print('[ERROR] 스택 트레이스: $stack');
      return [];
    }
  }

  /// 친구 요청 수락
  Future<void> acceptFriendRequest(String myId, String addId) async {
    if (addId.isEmpty) {
      print('[ERROR] 친구 요청 수락 add_id가 비어있음! 요청 차단');
      throw Exception('친구 요청 정보가 올바르지 않습니다.');
    }

    print('[DEBUG] 친구 요청 수락 시도 - myId: $myId, addId: $addId');

    final res = await http.post(
      Uri.parse('$baseUrl/accept'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'my_id': myId, 'add_id': addId}),
    );

    print('[DEBUG] 친구 요청 수락 응답: ${res.statusCode} ${res.body}');

    if (res.statusCode != 200) {
      print('[ERROR] 친구 요청 수락 실패: ${res.body}');
      throw Exception('친구 요청 수락 실패');
    }
  }

  /// 친구 요청 거절
  Future<void> rejectFriendRequest(String myId, String addId) async {
    if (addId.isEmpty) {
      print('[ERROR] 친구 요청 거절 add_id가 비어있음! 요청 차단');
      throw Exception('친구 요청 정보가 올바르지 않습니다.');
    }

    print('[DEBUG] 친구 요청 거절 시도 - myId: $myId, addId: $addId');

    final res = await http.post(
      Uri.parse('$baseUrl/reject'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'my_id': myId, 'add_id': addId}),
    );

    print('[DEBUG] 친구 요청 거절 응답: ${res.statusCode} ${res.body}');

    if (res.statusCode != 200) {
      print('[ERROR] 친구 요청 거절 실패: ${res.body}');
      throw Exception('친구 요청 거절 실패');
    }
  }

  /// 내가 보낸 친구 요청 취소 (서버 명세 완벽 준수)
  Future<void> cancelSentFriendRequest(String myId, String friendId) async {
    if (friendId.isEmpty) {
      print('[ERROR] 친구 요청 취소 friend_id가 비어있음! 요청 차단');
      throw Exception('친구 요청 정보가 올바르지 않습니다.');
    }

    try {
      print('[DEBUG] ===== 친구 요청 취소 시작 =====');
      print('[DEBUG] myId: $myId, friendId: $friendId');
      print('[DEBUG] 요청 URL: $baseUrl/mistake/$myId');
      print('[DEBUG] 요청 Body: {"friend_id": "$friendId"}');

      final res = await http.post(
        Uri.parse('$baseUrl/mistake/$myId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'friend_id': friendId}),
      );

      print('[DEBUG] 친구 요청 취소 응답 상태: ${res.statusCode}');
      print('[DEBUG] 친구 요청 취소 응답 본문: ${res.body}');

      if (res.statusCode == 200) {
        print('[SUCCESS] 친구 요청 취소 성공');

        // 서버 응답 메시지 확인
        try {
          final responseData = jsonDecode(res.body);
          if (responseData['message'] == "실수 인정") {
            print('[DEBUG] 서버 확인 메시지: ${responseData['message']}');
          } else {
            print('[DEBUG] 예상과 다른 응답 메시지: ${responseData['message']}');
          }
        } catch (e) {
          print('[DEBUG] 응답 메시지 파싱 실패: $e');
          print('[DEBUG] 하지만 상태코드 200이므로 성공으로 처리');
        }

        return;
      } else {
        print('[ERROR] 친구 요청 취소 실패 - 상태코드: ${res.statusCode}');
        print('[ERROR] 응답 내용: ${res.body}');
        throw Exception('친구 요청 취소 실패: ${res.statusCode}');
      }
    } catch (e) {
      print('[ERROR] 친구 요청 취소 API 호출 실패: $e');
      throw Exception('친구 요청 취소 중 오류가 발생했습니다: $e');
    }
  }

  /// 친구 삭제
  Future<void> deleteFriend(String myId, String addId) async {
    if (addId.isEmpty) {
      print('[ERROR] 친구 삭제 add_id가 비어있음! 요청 차단');
      throw Exception('친구 정보가 올바르지 않습니다.');
    }

    print('[DEBUG] 친구 삭제 시도 - myId: $myId, addId: $addId');

    final res = await http.delete(
      Uri.parse('$baseUrl/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'my_id': myId, 'add_id': addId}),
    );

    print('[DEBUG] 친구 삭제 응답: ${res.statusCode} ${res.body}');

    if (res.statusCode != 200) {
      print('[ERROR] 친구 삭제 실패: ${res.body}');
      throw Exception('친구 삭제 실패');
    }
  }
}
