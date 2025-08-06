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
  final String memo;

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
    this.memo = '',
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
      title: json['title'] ?? '',
      professor: json['professor'] ?? '',
      buildingName: json['building_name'] ?? '',
      floorNumber: json['floor_number'] ?? '',
      roomName: json['room_name'] ?? '',
      dayOfWeek: _dayOfWeekInt(json['day_of_week']),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      color: _parseColor(json['color']),
      memo: json['memo'] ?? '',
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

  /// 색상 파싱 함수 (fromJson에서 사용)
  static Color _parseColor(dynamic value) {
    if (value == null) return const Color(0xFF3B82F6); // 기본 파란색
    
    try {
      if (value is String) {
        // 16진수 문자열로 온 경우
        if (value.startsWith('FF')) {
          return Color(int.parse(value, radix: 16));
        } else if (value.startsWith('#')) {
          return Color(int.parse(value.substring(1), radix: 16));
        } else {
          // 숫자만 있는 경우 FF를 앞에 추가
          return Color(int.parse('FF$value', radix: 16));
        }
      } else if (value is int) {
        return Color(value);
      }
    } catch (e) {
      print('색상 파싱 오류: $value, $e');
    }
    
    return const Color(0xFF3B82F6); // 기본 파란색
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
      'memo': memo,
    };
    if (id != null) {
      map['id'] = id!;
    }
    return map;
  }
}
