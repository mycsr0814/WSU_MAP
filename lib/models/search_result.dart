// lib/models/search_result.dart - 통합 검색 결과 모델

import 'package:flutter_application_1/models/building.dart';

enum SearchResultType {
  building,  // 건물
  room,      // 호실
}

class SearchResult {
  final SearchResultType type;
  final String displayName;    // 표시될 이름 (예: "W19 101호")
  final String searchText;     // 검색용 텍스트
  final Building building;     // 기본 건물 정보
  final String? roomNumber;    // 호실 번호 (호실인 경우)
  final int? floorNumber;      // 층 번호 (호실인 경우)
  final String? roomDescription; // 호실 설명 (호실인 경우)

  SearchResult({
    required this.type,
    required this.displayName,
    required this.searchText,
    required this.building,
    this.roomNumber,
    this.floorNumber,
    this.roomDescription,
  });

  // 건물 검색 결과 생성
  factory SearchResult.fromBuilding(Building building) {
    return SearchResult(
      type: SearchResultType.building,
      displayName: building.name,
      searchText: '${building.name} ${building.info} ${building.category} ${building.description}',
      building: building,
    );
  }

  // 호실 검색 결과 생성
  factory SearchResult.fromRoom({
    required Building building,
    required String roomNumber,
    required int floorNumber,
    String? roomDescription,
  }) {
    return SearchResult(
      type: SearchResultType.room,
      displayName: '${building.name} ${roomNumber}호',
      searchText: '${building.name} ${roomNumber}호 ${roomDescription ?? ''}',
      building: building,
      roomNumber: roomNumber,
      floorNumber: floorNumber,
      roomDescription: roomDescription,
    );
  }

  // 검색 결과가 건물인지 확인
  bool get isBuilding => type == SearchResultType.building;
  
  // 검색 결과가 호실인지 확인
  bool get isRoom => type == SearchResultType.room;

  // 🔥 전체 표시명 (건물 + 호실 정보 포함)
  String get fullDisplayName {
    if (isRoom) {
      return '${building.name} ${floorNumber}층 ${roomNumber}호';
    }
    return displayName;
  }

  // 🔥 검색용 텍스트 (검색 매칭에 사용) - 기존 searchText와 호환
  String get searchableText {
    final parts = <String>[
      building.name.toLowerCase(),
      displayName.toLowerCase(),
    ];
    
    if (roomNumber != null) {
      parts.add(roomNumber!.toLowerCase());
    }
    
    if (roomDescription != null && roomDescription!.isNotEmpty) {
      parts.add(roomDescription!.toLowerCase());
    }
    
    return parts.join(' ');
  }

  // 호실인 경우 Building 객체를 호실 좌표로 생성 (필요시)
  Building toBuildingWithRoomLocation() {
    if (isRoom) {
      return Building(
        name: building.name, // ✅ 건물명만 (예: "W19")
        info: roomDescription ?? '${building.name} ${roomNumber}호',
        lat: building.lat,
        lng: building.lng,
        category: building.category,
        baseStatus: building.baseStatus,
        hours: building.hours,
        phone: building.phone,
        imageUrl: building.imageUrl,
        // ✅ description에 floor/room 정보를 함께 포함
        description: 'floor:$floorNumber,room:$roomNumber',
      );
    }
    return building;
  }

  // 🔥 toString 메서드 추가
  @override
  String toString() {
    return 'SearchResult{type: $type, building: ${building.name}, displayName: $displayName, roomNumber: $roomNumber, floorNumber: $floorNumber}';
  }

  // 🔥 equality 비교 메서드 추가
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is SearchResult &&
        other.type == type &&
        other.building == building &&
        other.displayName == displayName &&
        other.roomNumber == roomNumber &&
        other.floorNumber == floorNumber;
  }

  // 🔥 hashCode 메서드 추가
  @override
  int get hashCode {
    return type.hashCode ^
        building.hashCode ^
        displayName.hashCode ^
        (roomNumber?.hashCode ?? 0) ^
        (floorNumber?.hashCode ?? 0);
  }
}

// 🔥 검색 결과 그룹화를 위한 확장
extension SearchResultGrouping on List<SearchResult> {
  
  // 건물별로 그룹화
  Map<Building, List<SearchResult>> groupByBuilding() {
    final Map<Building, List<SearchResult>> grouped = {};
    
    for (final result in this) {
      grouped.putIfAbsent(result.building, () => []).add(result);
    }
    
    return grouped;
  }
  
  // 타입별로 그룹화
  Map<SearchResultType, List<SearchResult>> groupByType() {
    final Map<SearchResultType, List<SearchResult>> grouped = {};
    
    for (final result in this) {
      grouped.putIfAbsent(result.type, () => []).add(result);
    }
    
    return grouped;
  }
  
  // 건물만 필터링
  List<SearchResult> get buildingsOnly {
    return where((result) => result.isBuilding).toList();
  }
  
  // 호실만 필터링
  List<SearchResult> get roomsOnly {
    return where((result) => result.isRoom).toList();
  }
  
  // 특정 건물의 결과만 필터링
  List<SearchResult> fromBuilding(Building building) {
    return where((result) => result.building == building).toList();
  }
}