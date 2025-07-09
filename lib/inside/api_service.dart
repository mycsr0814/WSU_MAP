import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = "http://3.106.229.163:3000";

  /// 서버에서 선택 가능한 모든 건물 목록을 가져오는 함수
  Future<List<String>> fetchBuildingList() async {
    final response = await http.get(Uri.parse('$_baseUrl/buildings'));
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> buildingList = data['buildings'];
      return buildingList.cast<String>();
    } else {
      throw Exception('Failed to load building list from server');
    }
  }

  /// 특정 건물의 층 목록을 가져오는 함수
  Future<List<dynamic>> fetchFloorList(String buildingName) async {
    final response = await http.get(Uri.parse('$_baseUrl/floor/$buildingName'));
    if (response.statusCode == 200) {
      final List<dynamic> floorList = json.decode(utf8.decode(response.bodyBytes));
      return floorList;
    } else {
      throw Exception('Failed to load floor list for $buildingName');
    }
  }

  /// 서버에 길찾기를 요청하는 함수
  Future<Map<String, dynamic>> findPath({
    required String fromBuilding,
    int? fromFloor,
    String? fromRoom,
    required String toBuilding,
    int? toFloor,
    String? toRoom,
  }) async {
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
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Failed to find path');
    }
  }

  /// [추가] 방 설명을 서버에서 받아오는 함수
  Future<String> fetchRoomDescription({
    required String buildingName,
    required int floorNumber,
    required String roomName,
  }) async {
    final url = Uri.parse('$_baseUrl/desc/$buildingName/$floorNumber');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'room_name': roomName}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return data['Room_Description'] ?? '설명 없음';
    } else {
      throw Exception('방 설명을 불러오지 못했습니다.');
    }
  }
}
