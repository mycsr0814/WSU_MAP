// lib/models/building.dart - 자동 운영상태 계산 기능 추가
import 'package:flutter/material.dart'; // 이 줄 추가

class Building {
  final String name;
  final String info;
  final double lat;
  final double lng;
  final String category;
  final String baseStatus; // 기본 운영상태 (휴무, 폐점 등)
  final String hours;
  final String phone;
  final String? imageUrl;
  final String description;

  const Building({
    required this.name,
    required this.info,
    required this.lat,
    required this.lng,
    required this.category,
    required this.baseStatus,
    required this.hours,
    required this.phone,
    this.imageUrl,
    required this.description,
  });

  /// 현재 시간을 기반으로 운영상태 계산
  String get status {
    return calculateCurrentStatus();
  }

  /// 현재 운영상태를 계산하는 메서드
  String calculateCurrentStatus() {
    // 기본 상태가 운영중이 아니면 그대로 반환
    if (baseStatus != '운영중') {
      return baseStatus;
    }

    final now = DateTime.now();
    final currentHour = now.hour;
    
    // 운영시간: 09:00 - 18:00
    if (currentHour >= 9 && currentHour < 18) {
      return '운영중';
    } else {
      return '운영종료';
    }
  }

  /// 운영 여부 확인
  bool get isOpen {
    return status == '운영중';
  }

  /// 다음 운영 시작/종료 시간 계산
  String get nextStatusChangeTime {
    final now = DateTime.now();
    final currentHour = now.hour;
    
    if (baseStatus != '운영중') {
      return baseStatus; // 기본 상태가 운영중이 아니면 변경 없음
    }

    if (currentHour < 9) {
      return '오전 9시에 운영 시작';
    } else if (currentHour < 18) {
      return '오후 6시에 운영 종료';
    } else {
      return '내일 오전 9시에 운영 시작';
    }
  }

  /// 운영시간 정보를 포맷팅해서 반환
  String get formattedHours {
    if (baseStatus != '운영중') {
      return baseStatus;
    }
    return '09:00 - 18:00';
  }

  /// 운영상태 아이콘 반환
  String get statusIcon {
    switch (status) {
      case '운영중':
        return '🟢';
      case '운영종료':
        return '🔴';
      default:
        return '⚪';
    }
  }

  /// 운영상태 색상 반환
  Color get statusColor {
    switch (status) {
      case '운영중':
        return const Color(0xFF10B981); // 초록색
      case '운영종료':
        return const Color(0xFFEF4444); // 빨간색
      default:
        return const Color(0xFF6B7280); // 회색
    }
  }

  /// 기존 생성자 (하위 호환성)
  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      name: json['name'] ?? '',
      info: json['info'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      category: json['category'] ?? '기타',
      baseStatus: json['baseStatus'] ?? json['status'] ?? '운영중',
      hours: json['hours'] ?? '09:00 - 18:00',
      phone: json['phone'] ?? '',
      imageUrl: json['imageUrl'],
      description: json['description'] ?? '',
    );
  }

  /// 서버 API 응답을 위한 새로운 팩토리 생성자 - 강화된 에러 처리
  factory Building.fromServerJson(Map<String, dynamic> json) {
    try {
      print('📋 서버 응답 원본: $json'); // 디버깅용
      
      String buildingName = json['Building_Name'] ?? json['name'] ?? '';
      String description = json['Description'] ?? json['info'] ?? json['description'] ?? '';
      
      // Location 필드 처리 - 여러 형태 지원
      double latitude = 0.0;
      double longitude = 0.0;
      
      final locationField = json['Location'];
      
      if (locationField != null) {
        if (locationField is String) {
          // 문자열 형태: "(36.336305,127.445375)"
          final cleanLocation = locationField.replaceAll('(', '').replaceAll(')', '');
          final coordinates = cleanLocation.split(',');
          
          if (coordinates.length == 2) {
            latitude = double.tryParse(coordinates[0].trim()) ?? 0.0;
            longitude = double.tryParse(coordinates[1].trim()) ?? 0.0;
          }
        } else if (locationField is Map<String, dynamic>) {
          // 객체 형태: {"x": 36.336305, "y": 127.445375}
          latitude = (locationField['x'] ?? locationField['lat'] ?? 0.0).toDouble();
          longitude = (locationField['y'] ?? locationField['lng'] ?? 0.0).toDouble();
        }
      }
      
      // lat, lng 필드가 직접 있는 경우도 처리
      if (latitude == 0.0 && longitude == 0.0) {
        latitude = (json['lat'] ?? json['latitude'] ?? 0.0).toDouble();
        longitude = (json['lng'] ?? json['longitude'] ?? 0.0).toDouble();
      }
      
      print('📍 파싱된 좌표: ($latitude, $longitude)'); // 디버깅용
      
      // 카테고리 매핑 (서버 데이터에 맞게 조정)
      String category = _mapBuildingNameToCategory(buildingName);
      
      // 운영상태 처리 - 서버에서 특별한 상태가 없으면 기본값 '운영중'
      String baseStatus = json['baseStatus'] ?? json['status'] ?? '운영중';
      
      return Building(
        name: buildingName,
        info: description,
        lat: latitude,
        lng: longitude,
        category: category,
        baseStatus: baseStatus,
        hours: json['hours'] ?? '09:00 - 18:00',
        phone: json['phone'] ?? '042-821-5678',
        imageUrl: json['File'] ?? json['imageUrl'],
        description: description,
      );
    } catch (e) {
      print('❌ Building.fromServerJson 오류: $e');
      print('📋 문제가 된 JSON: $json');
      
      // 오류 발생 시 기본값으로 Building 생성
      return Building(
        name: json['Building_Name']?.toString() ?? json['name']?.toString() ?? 'Unknown',
        info: json['Description']?.toString() ?? json['info']?.toString() ?? '',
        lat: 36.337, // 우송대 중앙 좌표
        lng: 127.445,
        category: '기타',
        baseStatus: '운영중',
        hours: '09:00 - 18:00',
        phone: '042-821-5678',
        imageUrl: null,
        description: '',
      );
    }
  }

  /// 건물명을 기반으로 카테고리 자동 분류 - 확장된 매핑
  static String _mapBuildingNameToCategory(String buildingName) {
    final name = buildingName.toLowerCase();
    
    if (name.contains('도서관') || name.contains('library')) {
      return '도서관';
    } else if (name.contains('기숙사') || name.contains('생활관') || name.contains('숙')) {
      return '기숙사';
    } else if (name.contains('카페') || name.contains('cafe') || 
               name.contains('솔카페') || name.contains('스타리코')) {
      return '카페';
    } else if (name.contains('식당') || name.contains('restaurant') || 
               name.contains('베이커리') || name.contains('레스토랑')) {
      return '식당';
    } else if (name.contains('체육관') || name.contains('스포츠') || name.contains('gym')) {
      return '체육시설';
    } else if (name.contains('유치원')) {
      return '유치원';
    } else if (name.contains('학군단')) {
      return '군사시설';
    } else if (name.contains('타워') || name.contains('tower')) {
      return '복합시설';
    } else if (name.contains('회관') || name.contains('관') || name.contains('center') ||
               name.contains('학과') || name.contains('전공') || name.contains('학부') ||
               name.contains('교육') || name.contains('강의') || name.contains('실습')) {
      return '교육시설';
    } else {
      return '기타';
    }
  }

  /// JSON 변환 (API 전송용)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'info': info,
      'lat': lat,
      'lng': lng,
      'category': category,
      'baseStatus': baseStatus,
      'status': status, // 현재 계산된 상태도 포함
      'hours': hours,
      'phone': phone,
      'imageUrl': imageUrl,
      'description': description,
    };
  }

  /// 서버 형태로 변환
  Map<String, dynamic> toServerJson() {
    return {
      'Building_Name': name,
      'Location': '($lat,$lng)',
      'Description': info,
      'File': imageUrl,
    };
  }

  /// 복사 생성자
  Building copyWith({
    String? name,
    String? info,
    double? lat,
    double? lng,
    String? category,
    String? baseStatus,
    String? hours,
    String? phone,
    String? imageUrl,
    String? description,
  }) {
    return Building(
      name: name ?? this.name,
      info: info ?? this.info,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      category: category ?? this.category,
      baseStatus: baseStatus ?? this.baseStatus,
      hours: hours ?? this.hours,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'Building(name: $name, lat: $lat, lng: $lng, category: $category, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Building && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}