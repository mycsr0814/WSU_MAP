// lib/models/search_result.dart - roomUser 포함 안전성 강화버전

import 'package:flutter/foundation.dart';
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
  final List<String>? roomUser;  // ▶︎ 호실 사용자/담당자
  final List<String>? roomPhone;  // 추가
  final List<String>? roomEmail;  

  SearchResult({
    required this.type,
    required this.displayName,
    required this.searchText,
    required this.building,
    this.roomNumber,
    this.floorNumber,
    this.roomDescription,
    this.roomUser,
    this.roomPhone,    // 추가
    this.roomEmail,
  });

  // 건물 검색 결과 생성
  factory SearchResult.fromBuilding(Building building) {
    try {
      if (building == null) {
        throw ArgumentError('Building cannot be null');
      }

      final buildingName = building.name.isNotEmpty ? building.name : '알 수 없는 건물';
      final searchTextParts = <String>[
        buildingName,
        building.info.isNotEmpty ? building.info : '',
        building.category.isNotEmpty ? building.category : '',
        building.description.isNotEmpty ? building.description : '',
      ].where((part) => part.isNotEmpty).toList();

      return SearchResult(
        type: SearchResultType.building,
        displayName: buildingName,
        searchText: searchTextParts.join(' '),
        building: building,
      );
    } catch (e) {
      debugPrint('❌ SearchResult.fromBuilding 생성 오류: $e');
      return SearchResult(
        type: SearchResultType.building,
        displayName: building?.name ?? '알 수 없는 건물',
        searchText: building?.name ?? '알 수 없는 건물',
        building: building ?? _createFallbackBuilding(),
      );
    }
  }

  // 호실(방) 검색 결과 생성, roomUser 포함
  factory SearchResult.fromRoom({
    required Building building,
    required String roomNumber,
    required int floorNumber,
    String? roomDescription,
    List<String>? roomUser,
    List<String>? roomPhone,    // 추가
    List<String>? roomEmail,    
  }) {
    try {
      if (building == null) {
        throw ArgumentError('Building cannot be null');
      }
      if (roomNumber.isEmpty) {
        throw ArgumentError('Room number cannot be empty');
      }
      if (floorNumber < 1) {
        debugPrint('⚠️ 잘못된 층 번호: $floorNumber, 1로 설정');
        floorNumber = 1;
      }

      final buildingName = building.name.isNotEmpty ? building.name : '알 수 없는 건물';
      final safeRoomNumber = roomNumber.isNotEmpty ? roomNumber : '알 수 없는 호실';
      final displayName = '$buildingName ${safeRoomNumber}호';

      final searchTextParts = <String>[
        buildingName,
        '${safeRoomNumber}호',
        roomDescription?.isNotEmpty == true ? roomDescription! : '',
        if (roomUser != null && roomUser.isNotEmpty)
          roomUser.where((u) => u.isNotEmpty).join(' '), // 여러 명일 때 합침
      ].where((part) => part.isNotEmpty).toList();

      return SearchResult(
        type: SearchResultType.room,
        displayName: displayName,
        searchText: searchTextParts.join(' '),
        building: building,
        roomNumber: safeRoomNumber,
        floorNumber: floorNumber,
        roomDescription: roomDescription,
        roomUser: roomUser,
        roomPhone: roomPhone,   // 추가
        roomEmail: roomEmail,  
      );
    } catch (e) {
      debugPrint('❌ SearchResult.fromRoom 생성 오류: $e');
      return SearchResult.fromBuilding(building);
    }
  }

  static Building _createFallbackBuilding() {
    return Building(
      name: '알 수 없는 건물',
      info: '정보 없음',
      lat: 0.0,
      lng: 0.0,
      category: '건물',
      baseStatus: '알 수 없음',
      hours: '',
      phone: '',
      imageUrl: '',
      description: '오류로 인한 기본 건물',
    );
  }

  bool get isBuilding {
    try {
      return type == SearchResultType.building;
    } catch (e) {
      debugPrint('❌ isBuilding getter 오류: $e');
      return false;
    }
  }

  bool get isRoom {
    try {
      return type == SearchResultType.room &&
          roomNumber?.isNotEmpty == true;
    } catch (e) {
      debugPrint('❌ isRoom getter 오류: $e');
      return false;
    }
  }

  String get fullDisplayName {
    try {
      if (isRoom) {
        final buildingName = building.name.isNotEmpty ? building.name : '알 수 없는 건물';
        final floor = floorNumber != null && floorNumber! > 0 ? '${floorNumber}층 ' : '';
        final room = roomNumber?.isNotEmpty == true ? '${roomNumber}호' : '알 수 없는 호실';
        return '$buildingName $floor$room';
      }
      return displayName.isNotEmpty ? displayName : '알 수 없는 건물';
    } catch (e) {
      debugPrint('❌ fullDisplayName getter 오류: $e');
      return displayName.isNotEmpty ? displayName : '정보 없음';
    }
  }

  // user(담당자 등)도 검색 텍스트에 포함
  String get searchableText {
    try {
      final parts = <String>[];

      if (building.name.isNotEmpty) parts.add(building.name.toLowerCase());
      if (displayName.isNotEmpty) parts.add(displayName.toLowerCase());
      if (roomNumber?.isNotEmpty == true) parts.add(roomNumber!.toLowerCase());
      if (roomDescription?.isNotEmpty == true) parts.add(roomDescription!.toLowerCase());
      // roomUser도 추가
      if (roomUser != null && roomUser!.isNotEmpty) {
        parts.add(roomUser!
            .where((user) => user.isNotEmpty)
            .map((user) => user.toLowerCase())
            .join(' '));
      }
      return parts.join(' ');
    } catch (e) {
      debugPrint('❌ searchableText getter 오류: $e');
      return searchText.isNotEmpty ? searchText.toLowerCase() : '';
    }
  }

  Building toBuildingWithRoomLocation() {
    try {
      if (isRoom) {
        final buildingName = building.name.isNotEmpty ? building.name : '알 수 없는 건물';
        final roomInfo = roomNumber?.isNotEmpty == true ? roomNumber! : '알 수 없는 호실';
        final description = 'floor:${floorNumber ?? 1},room:$roomInfo';

        return Building(
          name: buildingName,
          info: roomDescription?.isNotEmpty == true
              ? roomDescription!
              : '$buildingName ${roomInfo}호',
          lat: building.lat,
          lng: building.lng,
          category: building.category.isNotEmpty ? building.category : '강의실',
          baseStatus: building.baseStatus.isNotEmpty ? building.baseStatus : '사용가능',
          hours: building.hours,
          phone: building.phone,
          imageUrl: building.imageUrl,
          description: description,
        );
      }
      return building;
    } catch (e) {
      debugPrint('❌ toBuildingWithRoomLocation 오류: $e');
      return building;
    }
  }

  @override
  String toString() {
    try {
      return 'SearchResult{type: $type, building: ${building.name}, displayName: $displayName, roomNumber: $roomNumber, floorNumber: $floorNumber, roomUser: $roomUser}';
    } catch (e) {
      return 'SearchResult{오류: $e}';
    }
  }

  @override
  bool operator ==(Object other) {
    try {
      if (identical(this, other)) return true;

      return other is SearchResult &&
          other.type == type &&
          other.building == building &&
          other.displayName == displayName &&
          other.roomNumber == roomNumber &&
          other.floorNumber == floorNumber &&
          listEquals(other.roomUser, roomUser);
    } catch (e) {
      debugPrint('❌ equality 비교 오류: $e');
      return false;
    }
  }

  @override
  int get hashCode {
    try {
      return type.hashCode ^
          building.hashCode ^
          displayName.hashCode ^
          (roomNumber?.hashCode ?? 0) ^
          (floorNumber?.hashCode ?? 0) ^
          (roomUser?.join('').hashCode ?? 0);
    } catch (e) {
      debugPrint('❌ hashCode 계산 오류: $e');
      return 0;
    }
  }
}

// 검색 결과 그룹화 확장
extension SearchResultGrouping on List<SearchResult> {

  Map<Building, List<SearchResult>> groupByBuilding() {
    final Map<Building, List<SearchResult>> grouped = {};

    try {
      for (final result in this) {
        if (result.building != null) {
          grouped.putIfAbsent(result.building, () => []).add(result);
        }
      }
    } catch (e) {
      debugPrint('❌ groupByBuilding 오류: $e');
    }
    return grouped;
  }

  Map<SearchResultType, List<SearchResult>> groupByType() {
    final Map<SearchResultType, List<SearchResult>> grouped = {};

    try {
      for (final result in this) {
        grouped.putIfAbsent(result.type, () => []).add(result);
      }
    } catch (e) {
      debugPrint('❌ groupByType 오류: $e');
    }
    return grouped;
  }

  List<SearchResult> get buildingsOnly {
    try {
      return where((result) => result.isBuilding).toList();
    } catch (e) {
      debugPrint('❌ buildingsOnly 필터링 오류: $e');
      return [];
    }
  }

  List<SearchResult> get roomsOnly {
    try {
      return where((result) => result.isRoom).toList();
    } catch (e) {
      debugPrint('❌ roomsOnly 필터링 오류: $e');
      return [];
    }
  }

  List<SearchResult> fromBuilding(Building building) {
    try {
      if (building == null) return [];
      return where((result) => result.building == building).toList();
    } catch (e) {
      debugPrint('❌ fromBuilding 필터링 오류: $e');
      return [];
    }
  }
}
