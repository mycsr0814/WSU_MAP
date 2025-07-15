import 'dart:convert';
import 'package:http/http.dart' as http;
import 'timetable_item.dart';
import 'package:flutter_application_1/config/api_config.dart';

class TimetableApiService {
  static String get timetableBase => ApiConfig.timetableBase;
  static String get floorBase => ApiConfig.floorBase;
  static String get roomBase => ApiConfig.roomBase;

  /// 시간표 전체 조회
  Future<List<ScheduleItem>> fetchScheduleItems(String userId) async {
    final res = await http.get(Uri.parse('$timetableBase/$userId'));
    if (res.statusCode != 200) throw Exception('시간표 조회 실패');
    final List data = jsonDecode(res.body);
    return data.map((e) => ScheduleItem.fromJson(e)).toList();
  }

  /// 시간표 항목 추가
  Future<void> addScheduleItem(ScheduleItem item, String userId) async {
    final res = await http.post(
      Uri.parse('$timetableBase/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );
    if (res.statusCode != 201) throw Exception('시간표 추가 실패');
  }

  /// 시간표 항목 수정
  Future<void> updateScheduleItem({
    required String userId,
    required String originTitle,
    required String originDayOfWeek,
    required ScheduleItem newItem,
  }) async {
    final res = await http.put(
      Uri.parse('$timetableBase/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "origin_title": originTitle,
        "origin_day_of_week": originDayOfWeek,
        "new_title": newItem.title,
        "new_day_of_week": newItem.dayOfWeekText,
        "start_time": newItem.startTime,
        "end_time": newItem.endTime,
        "building_name": newItem.buildingName,
        "floor_number": newItem.floorNumber,
        "room_name": newItem.roomName,
        "professor": newItem.professor,
        "color": newItem.color.value.toRadixString(16),
        "memo": "",
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('시간표 수정 실패');
    }
  }

  /// 시간표 항목 삭제
  Future<void> deleteScheduleItem({
    required String userId,
    required String title,
    required String dayOfWeek,
  }) async {
    final res = await http.delete(
      Uri.parse('$timetableBase/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'day_of_week': dayOfWeek}),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('시간표 삭제 실패');
    }
  }

  // 건물에 해당하는 층 조회
  // Future<List<String>> fetchFloors(String building) async {
  //   // 서버 확정 엔드포인트 사용!
  //   final res = await http.get(Uri.parse('$baseUrl/floor/names/$building'));
  //   if (res.statusCode != 200) throw Exception('층수 조회 실패');
  //   // 서버 응답이 배열(예: ["2","3","4"])면 아래 코드 사용
  //   final arr = jsonDecode(res.body) as List;
  //   return arr.map((e) => e.toString()).toList();
  //   // 만약 [{"floor":"2"}, ...] 구조면
  //   // return arr.map((e) => e['floor'].toString()).toList();
  // }

  /// 건물에 해당하는 층 조회 - (GET /floor/names/:building) 서버 구조에 100% 맞춤
  Future<List<String>> fetchFloors(String building) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.floorBase}/names/$building'),
    );
    print('층수 응답 status: ${res.statusCode}, body: ${res.body}');
    if (res.statusCode != 200) throw Exception('층수 조회 실패');
    final arr = jsonDecode(res.body) as List;
    print('층수 파싱 결과: $arr');
    return arr.map((e) => e['Floor_Number'].toString()).toList();
  }

  /// 건물+층에 해당하는 강의실 조회 - (GET /room/:building/:floor) 서버 구조에 100% 맞춤
  Future<List<String>> fetchRooms(String building, String floor) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.roomBase}/$building/$floor'),
    );
    if (res.statusCode != 200) throw Exception('강의실 조회 실패');
    final arr = jsonDecode(res.body) as List;
    return arr.map((e) => e['Room_Name'].toString()).toList();
  }
}
