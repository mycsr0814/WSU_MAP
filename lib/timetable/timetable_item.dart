//timetable_item.dart

import 'package:flutter/material.dart';

/// 서버와 주고받는 시간표 데이터 모델
class ScheduleItem {
  final String? id; // 숫자/영문 혼용 가능
  final String title;
  final String professor;
  final String buildingName;
  final String floorNumber;
  final String roomName;
  final int dayOfWeek; // 1~5 (월~금)
  final String startTime;
  final String endTime;
  final Color color;

  ScheduleItem({
    this.id,
    required this.title,
    required this.professor,
    required this.buildingName,
    required this.floorNumber,
    required this.roomName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.color,
  });

  /// int(1~5) → 영어 요일 변환
  String get dayOfWeekText {
    switch (dayOfWeek) {
      case 1: return 'mon';
      case 2: return 'tue';
      case 3: return 'wed';
      case 4: return 'thu';
      case 5: return 'fri';
      default: return '';
    }
  }

  /// 서버에서 받은 JSON을 ScheduleItem 객체로 변환
  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id']?.toString(),
      title: json['title'],
      professor: json['professor'],
      buildingName: json['building_name'] ?? '',
      floorNumber: json['floor_number'] ?? '',
      roomName: json['room_name'] ?? '',
      dayOfWeek: _dayOfWeekInt(json['day_of_week']),
      startTime: json['start_time'],
      endTime: json['end_time'],
      color: Color(int.parse(json['color'], radix: 16)),
    );
  }

  /// 한글 요일 → int 변환 함수 (fromJson에서 사용)
  static int _dayOfWeekInt(dynamic value) {
    if (value is int) return value;
    switch (value) {
      case 'mon': return 1;
      case 'tue': return 2;
      case 'wed': return 3;
      case 'thu': return 4;
      case 'fri': return 5;
      default:
        if (value is String && int.tryParse(value) != null) return int.parse(value);
        return 0;
    }
  }

  /// ScheduleItem 객체를 서버로 보낼 JSON으로 변환
  Map<String, dynamic> toJson() {
    final map = {
      'title': title,
      'professor': professor,
      'building_name': buildingName,
      'floor_number': floorNumber,
      'room_name': roomName,
      'day_of_week': dayOfWeekText,
      'start_time': startTime,
      'end_time': endTime,
      'color': color.value.toRadixString(16),
    };
    if (id != null) {
      map['id'] = id!;
    }
    return map;
  }
}
