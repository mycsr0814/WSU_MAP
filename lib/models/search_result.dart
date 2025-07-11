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

  // 호실인 경우 Building 객체를 호실 좌표로 생성 (필요시)
  Building toBuildingWithRoomLocation() {
    if (isRoom) {
      // 호실의 경우 건물 좌표를 그대로 사용하거나
      // 필요하다면 호실별 세부 좌표 계산 로직 추가
      return Building(
        name: displayName,
        info: roomDescription ?? '${building.name} ${roomNumber}호',
        lat: building.lat, // 동일한 건물 좌표 사용
        lng: building.lng,
        category: '강의실',
        baseStatus: building.baseStatus,
        hours: building.hours,
        phone: building.phone,
        imageUrl: building.imageUrl,
        description: roomDescription ?? '',
      );
    }
    return building;
  }
}