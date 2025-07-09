import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String _baseUrl = "http://3.106.229.163:3000";

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

  Future<List<dynamic>> fetchFloorList(String buildingName) async {
    final response = await http.get(Uri.parse('$_baseUrl/floor/$buildingName'));
    if (response.statusCode == 200) {
      final List<dynamic> floorList = json.decode(utf8.decode(response.bodyBytes));
      return floorList;
    } else {
      throw Exception('Failed to load floor list for $buildingName');
    }
  }

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

  /// GET 방식으로 방 설명 받아오기 (일관성 있게 작성)
  Future<String> fetchRoomDescription({
    required String buildingName,
    required String floorNumber,
    required String roomName,
  }) async {
    print('$buildingName,$floorNumber,$roomName');
    final response = await http.get(
      Uri.parse('$_baseUrl/room/desc/${Uri.encodeComponent(buildingName)}/$floorNumber/${Uri.encodeComponent(roomName)}')
    );
    print('fuckyou');
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return data['Room_Description'] ?? '설명 없음';
    } else if (response.statusCode == 404) {
      return '설명 없음';
    } else {
      throw Exception('방 설명을 불러오지 못했습니다.');
    }
  }
}
