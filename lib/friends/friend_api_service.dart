// lib/friends/friend_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'friend.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:flutter_application_1/services/auth_service.dart';

class FriendApiService {
  static String get baseUrl => ApiConfig.friendBase;

  /// 🔥 사용자 존재 여부 확인
  Future<bool> checkUserExists(String userId) async {
    try {
      print('[DEBUG] 사용자 존재 여부 확인: $userId');
      
      final authService = AuthService();
      return await authService.checkUserExists(userId);
    } catch (e) {
      print('[ERROR] 사용자 존재 여부 확인 실패: $e');
      return false;
    }
  }

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

    // 🔥 친구 추가 전에 사용자 존재 여부 확인 (API가 있는 경우에만)
    try {
      print('[DEBUG] 사용자 존재 여부 확인 중...');
      final userExists = await checkUserExists(addId);
      
      if (!userExists) {
        print('[ERROR] 존재하지 않는 사용자: $addId');
        throw Exception('존재하지 않는 사용자입니다');
      }
      
      print('[DEBUG] 사용자 존재 확인 완료, 친구 추가 요청 진행');
    } catch (e) {
      print('[WARN] 사용자 확인 API를 사용할 수 없음, 서버 응답으로 판단: $e');
      // 사용자 확인 API가 없으면 서버 응답으로 판단
    }

    final res = await http.post(
      Uri.parse('$baseUrl/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'my_id': myId, 'add_id': addId}),
    );

    print('[DEBUG] 친구 추가 응답: ${res.statusCode} ${res.body}');
    print('[DEBUG] 응답 길이: ${res.body.length}');
    print('[DEBUG] 응답 내용 (원본): "${res.body}"');
    print('[DEBUG] 응답 내용 (소문자): "${res.body.toLowerCase()}"');
    print('[DEBUG] 응답 헤더: ${res.headers}');

    // 🔥 응답 상태 코드 확인 (200이 아닌 모든 경우를 에러로 처리)
    if (res.statusCode != 200) {
      print('[ERROR] 친구 추가 실패: ${res.statusCode} ${res.body}');
      
      // 🔥 상태 코드별 에러 메시지
      String errorMessage = '친구 추가 실패';
      
      switch (res.statusCode) {
        case 400:
          errorMessage = '잘못된 요청입니다';
          break;
        case 401:
          errorMessage = '인증이 필요합니다';
          break;
        case 403:
          errorMessage = '권한이 없습니다';
          break;
        case 404:
          errorMessage = '존재하지 않는 사용자입니다';
          break;
        case 409:
          errorMessage = '이미 친구이거나 요청을 보낸 사용자입니다';
          break;
        case 500:
          errorMessage = '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요';
          break;
        default:
          // 🔥 서버 응답 내용에 따라 구체적인 에러 메시지 제공
          final responseBody = res.body.toLowerCase();
          
          if (responseBody.contains('이미 친구') || responseBody.contains('already friend')) {
            errorMessage = '이미 친구인 사용자입니다';
          } else if (responseBody.contains('존재하지 않는') || responseBody.contains('not found') || responseBody.contains('user not found')) {
            errorMessage = '존재하지 않는 사용자입니다';
          } else if (responseBody.contains('이미 요청') || responseBody.contains('already requested')) {
            errorMessage = '이미 친구 요청을 보낸 사용자입니다';
          } else if (responseBody.contains('자기 자신') || responseBody.contains('self')) {
            errorMessage = '자기 자신을 친구로 추가할 수 없습니다';
          } else if (responseBody.contains('invalid') || responseBody.contains('잘못된')) {
            errorMessage = '잘못된 사용자 ID입니다';
          } else {
            // 🔥 서버 응답 내용을 그대로 표시
            errorMessage = '친구 추가에 실패했습니다: ${res.body}';
          }
      }
      
      print('[ERROR] 에러 메시지: $errorMessage');
      throw Exception(errorMessage);
    }
    
    // 🔥 성공 응답(200)이어도 실제 처리 결과 확인
    final responseBody = res.body.toLowerCase();
    print('[DEBUG] 친구 추가 성공 응답 내용: ${res.body}');
    
    // 🔥 성공 응답에서도 실패 메시지가 포함되어 있는지 확인
    if (responseBody.contains('존재하지 않는') || 
        responseBody.contains('not found') || 
        responseBody.contains('user not found') ||
        responseBody.contains('실패') ||
        responseBody.contains('fail') ||
        responseBody.contains('error') ||
        responseBody.contains('추가되지 않았습니다') ||
        responseBody.contains('not added') ||
        responseBody.contains('없는') ||
        responseBody.contains('invalid') ||
        responseBody.contains('잘못된')) {
      
      String errorMessage = '친구 추가에 실패했습니다';
      
      if (responseBody.contains('존재하지 않는') || responseBody.contains('not found') || responseBody.contains('user not found') || responseBody.contains('없는')) {
        errorMessage = '존재하지 않는 사용자입니다';
      } else if (responseBody.contains('이미 친구') || responseBody.contains('already friend')) {
        errorMessage = '이미 친구인 사용자입니다';
      } else if (responseBody.contains('이미 요청') || responseBody.contains('already requested')) {
        errorMessage = '이미 친구 요청을 보낸 사용자입니다';
      } else if (responseBody.contains('자기 자신') || responseBody.contains('self')) {
        errorMessage = '자기 자신을 친구로 추가할 수 없습니다';
      } else {
        errorMessage = '친구 추가에 실패했습니다: ${res.body}';
      }
      
      print('[ERROR] 성공 응답이지만 실제로는 실패: $errorMessage');
      throw Exception(errorMessage);
    }
    
    // 🔥 실제 성공인지 추가 확인
    // 서버에서 성공 메시지를 보내는 경우도 확인
    if (responseBody.contains('성공') || 
        responseBody.contains('success') || 
        responseBody.contains('추가됨') ||
        responseBody.contains('요청됨') ||
        responseBody.contains('requested')) {
      print('[DEBUG] 친구 추가 요청이 성공적으로 처리됨');
    } else {
      // 🔥 성공/실패 메시지가 명확하지 않은 경우, 응답 내용을 다시 분석
      print('[WARN] 응답 내용이 모호함: ${res.body}');
      
      // 🔥 응답이 비어있거나 의미가 없는 경우 실패로 처리
      if (res.body.trim().isEmpty || 
          res.body.trim() == '{}' || 
          res.body.trim() == '[]' ||
          res.body.length < 5) {
        print('[ERROR] 응답이 비어있거나 의미가 없음');
        throw Exception('친구 추가에 실패했습니다: 서버 응답이 올바르지 않습니다');
      }
      
      // 🔥 응답에 실패 관련 키워드가 있는지 다시 확인
      final failureKeywords = ['실패', 'fail', 'error', '없음', 'invalid', '잘못'];
      bool hasFailureKeyword = failureKeywords.any((keyword) => responseBody.contains(keyword));
      
      if (hasFailureKeyword) {
        print('[ERROR] 응답에 실패 키워드가 포함됨');
        throw Exception('존재하지 않는 사용자입니다');
      }
      
      print('[DEBUG] 응답이 성공으로 판단됨: ${res.body}');
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
