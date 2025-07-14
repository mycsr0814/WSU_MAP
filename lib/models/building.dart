import 'package:flutter/material.dart';

class Building {
  final String name;
  final String info;
  final double lat;
  final double lng;
  final String category;
  final String baseStatus;
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

  String get status => calculateCurrentStatus();

  String calculateCurrentStatus() {
    if (baseStatus != '운영중') return baseStatus;
    final now = DateTime.now();
    final currentHour = now.hour;
    if (currentHour >= 9 && currentHour < 18) {
      return '운영중';
    } else {
      return '운영종료';
    }
  }

  bool get isOpen => status == '운영중';

  String get nextStatusChangeTime {
    final now = DateTime.now();
    final currentHour = now.hour;
    if (baseStatus != '운영중') return baseStatus;
    if (currentHour < 9) {
      return '오전 9시에 운영 시작';
    } else if (currentHour < 18) {
      return '오후 6시에 운영 종료';
    } else {
      return '내일 오전 9시에 운영 시작';
    }
  }

  String get formattedHours {
    if (baseStatus != '운영중') return baseStatus;
    return '09:00 - 18:00';
  }

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

  Color get statusColor {
    switch (status) {
      case '운영중':
        return const Color(0xFF10B981);
      case '운영종료':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

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

  factory Building.fromServerJson(Map<String, dynamic> json) {
    try {
      print('📋 서버 응답 원본: $json');
      String buildingName = json['Building_Name'] ?? json['name'] ?? '';
      String description = json['Description'] ?? json['info'] ?? json['description'] ?? '';
      double latitude = 0.0;
      double longitude = 0.0;
      final locationField = json['Location'];
      if (locationField != null) {
        if (locationField is String) {
          final cleanLocation = locationField.replaceAll('(', '').replaceAll(')', '');
          final coordinates = cleanLocation.split(',');
          if (coordinates.length == 2) {
            latitude = double.tryParse(coordinates[0].trim()) ?? 0.0;
            longitude = double.tryParse(coordinates[1].trim()) ?? 0.0;
          }
        } else if (locationField is Map<String, dynamic>) {
          latitude = (locationField['x'] ?? locationField['lat'] ?? 0.0).toDouble();
          longitude = (locationField['y'] ?? locationField['lng'] ?? 0.0).toDouble();
        }
      }
      if (latitude == 0.0 && longitude == 0.0) {
        latitude = (json['lat'] ?? json['latitude'] ?? 0.0).toDouble();
        longitude = (json['lng'] ?? json['longitude'] ?? 0.0).toDouble();
      }
      print('📍 파싱된 좌표: ($latitude, $longitude)');
      String category = _mapBuildingNameToCategory(buildingName);
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
      return Building(
        name: json['Building_Name']?.toString() ?? json['name']?.toString() ?? 'Unknown',
        info: json['Description']?.toString() ?? json['info']?.toString() ?? '',
        lat: 36.337,
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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'info': info,
      'lat': lat,
      'lng': lng,
      'category': category,
      'baseStatus': baseStatus,
      'status': status,
      'hours': hours,
      'phone': phone,
      'imageUrl': imageUrl,
      'description': description,
    };
  }

  Map<String, dynamic> toServerJson() {
    return {
      'Building_Name': name,
      'Location': '($lat,$lng)',
      'Description': info,
      'File': imageUrl,
    };
  }

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

  // 🔥 추가: 방 정보로부터 Building 객체를 생성하는 팩토리 메서드
  static Building fromRoomInfo(Map<String, dynamic> roomInfo) {
    final String roomId = roomInfo['roomId'] ?? '';
    final String roomName = roomId.startsWith('R') ? roomId.substring(1) : roomId;
    final String buildingName = roomInfo['buildingName'] ?? '';
    final int? floorNumber = roomInfo['floorNumber'];
    
    return Building(
      name: '$buildingName $roomName호',
      info: '${floorNumber ?? ''}층 $roomName호',
      lat: 0.0, // 실제 좌표는 API에서 가져와야 함
      lng: 0.0,
      category: '강의실',
      baseStatus: '사용가능',
      hours: '',
      phone: '',
      imageUrl: '',
      description: '$buildingName ${floorNumber ?? ''}층 $roomName호',
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
