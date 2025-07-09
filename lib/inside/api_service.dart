import 'dart:convert';
import 'package:http/http.dart' as http;

/// 서버와 통신하는 API 서비스 클래스
class ApiService {
  final String _baseUrl = "http://3.106.229.163:3000";

  /// 서버에서 건물 목록을 받아오는 함수
  Future<List<String>> fetchBuildingList() async {
    // GET /buildings 요청
    final response = await http.get(Uri.parse('$_baseUrl/buildings'));
    if (response.statusCode == 200) {
      // 서버 응답을 디코딩하여 buildingList 추출
      final data = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> buildingList = data['buildings'];
      return buildingList.cast<String>();
    } else {
      throw Exception('Failed to load building list from server');
    }
  }

  /// 특정 건물의 층 목록을 받아오는 함수
  Future<List<dynamic>> fetchFloorList(String buildingName) async {
    // GET /floor/{buildingName} 요청
    final response = await http.get(Uri.parse('$_baseUrl/floor/$buildingName'));
    if (response.statusCode == 200) {
      // 서버 응답을 디코딩하여 floorList 추출
      final List<dynamic> floorList = json.decode(utf8.decode(response.bodyBytes));
      return floorList;
    } else {
      throw Exception('Failed to load floor list for $buildingName');
    }
  }

  /// 길찾기(경로 탐색) 요청 함수
  Future<Map<String, dynamic>> findPath({
    required String fromBuilding,
    int? fromFloor,
    String? fromRoom,
    required String toBuilding,
    int? toFloor,
    String? toRoom,
  }) async {
    // POST /path 요청 (JSON body 포함)
    final response = await http.post(
      Uri.parse('$_baseUrl/path'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'from_building': fromBuilding,
        'from_floor': fromFloor,
        'from_room': fromRoom,
        'to_building': toBuilding,
        'to_floor': toFloor,
        'to_room': toRoom,
      }),
    );
    if (response.statusCode == 200) {
      // 서버 응답을 디코딩하여 반환
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to find path');
    }
  }

  /// GET 방식으로 방(강의실) 설명을 받아오는 함수
  /// buildingName: 건물 이름
  /// floorNumber: 층 번호 (String, 예: '4')
  /// roomName: 방 이름 (예: '401')
  Future<String> fetchRoomDescription({
    required String buildingName,
    required String floorNumber,
    required String roomName,
  }) async {
    // GET /room/desc/{buildingName}/{floorNumber}/{roomName} 요청
    // buildingName, roomName에 한글/특수문자 있을 수 있으니 encodeComponent로 인코딩
    final response = await http.get(
      Uri.parse('$_baseUrl/room/desc/${Uri.encodeComponent(buildingName)}/$floorNumber/${Uri.encodeComponent(roomName)}')
    );
    if (response.statusCode == 200) {
      // 서버 응답에서 Room_Description 추출
      final data = json.decode(utf8.decode(response.bodyBytes));
      return data['Room_Description'] ?? '설명 없음';
    } else if (response.statusCode == 404) {
      return '설명 없음';
    } else {
      throw Exception('방 설명을 불러오지 못했습니다.');
    }
  }
}
