// lib/services/integrated_search_service.dart - 강의실 검색 기능 추가 버전

import 'package:flutter_application_1/inside/api_service.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/models/search_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/repositories/building_repository.dart';

class IntegratedSearchService {
  
  /// 🔥 개선된 통합 검색 메서드 (강의실 검색 추가)
  static Future<List<SearchResult>> search(String query, BuildContext context) async {
    final lowercaseQuery = query.toLowerCase().trim();
    if (lowercaseQuery.isEmpty) return [];

    debugPrint('🔍 통합 검색 시작: "$query"');
    
    List<SearchResult> results = [];

    try {
      // ✅ 최신 건물 리스트 사용 (마커와 동일)
      final buildings = BuildingRepository().allBuildings;
      debugPrint('📊 사용 가능한 건물: ${buildings.length}개');

      // 🏢 1단계: 건물 검색
      final buildingResults = _searchBuildings(buildings, lowercaseQuery);
      results.addAll(buildingResults);
      debugPrint('🏢 건물 검색 결과: ${buildingResults.length}개');

      // 🏫 2단계: 강의실 검색 (건물명 검색 시 해당 건물의 모든 강의실 표시)
      if (_isBuildingNameQuery(lowercaseQuery, buildings)) {
        debugPrint('🏫 건물명 검색 모드 - 해당 건물의 모든 강의실 검색');
        await _searchClassroomsInBuilding(lowercaseQuery, buildings, results);
      }

      // 🏠 3단계: 호실 검색 
      if (_isRoomNumberQuery(lowercaseQuery)) {
        debugPrint('🔢 호실 번호 검색 모드');
        await _searchRoomsByNumber(lowercaseQuery, buildings, results);
      } else {
        debugPrint('🔤 일반 검색 모드 - 모든 건물의 호실 검색');
        // 검색어가 호실 번호가 아닌 경우에도 호실 이름/설명에서 검색
        await _searchRoomsInAllBuildings(lowercaseQuery, buildings, results);
      }

      // ✅ 중복 제거 및 정렬
      final finalResults = _sortResults(_removeDuplicates(results), lowercaseQuery);
      
      debugPrint('✅ 최종 검색 결과: ${finalResults.length}개');
      debugPrint('   - 건물: ${finalResults.where((r) => r.isBuilding).length}개');
      debugPrint('   - 호실: ${finalResults.where((r) => r.isRoom).length}개');
      
      return finalResults;
      
    } catch (e, stackTrace) {
      debugPrint('❌ 통합 검색 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      
      // 오류 발생 시에도 기본 건물 검색 결과는 반환
      final buildings = BuildingRepository().allBuildings;
      final buildingResults = _searchBuildings(buildings, lowercaseQuery);
      
      return buildingResults;
    }
  }

  /// 🏢 건물 검색 로직 (기존과 동일)
  static List<SearchResult> _searchBuildings(List<Building> buildings, String lowercaseQuery) {
    List<Building> exactMatches = [];
    List<Building> codeMatches = [];
    List<Building> startMatches = [];
    List<Building> containsMatches = [];

    for (final building in buildings) {
      final buildingName = building.name.toLowerCase();
      final buildingInfo = building.info.toLowerCase();
      final buildingCategory = building.category.toLowerCase();

      // 🔍 괄호 안의 건물 코드 추출 (예: "W17" from "W17-동관(W17)")
      String? buildingCode;
      final codeMatch = RegExp(r'\(([^)]+)\)').firstMatch(building.name);
      if (codeMatch != null) {
        buildingCode = codeMatch.group(1)?.toLowerCase();
      }

      // 🔎 검색 우선순위 분류
      if (buildingName == lowercaseQuery) {
        exactMatches.add(building);
      } else if (buildingCode != null && buildingCode == lowercaseQuery) {
        codeMatches.add(building);
      } else if (buildingName.startsWith(lowercaseQuery)) {
        startMatches.add(building);
      } else if (
        buildingName.contains(lowercaseQuery) ||
        buildingInfo.contains(lowercaseQuery) ||
        buildingCategory.contains(lowercaseQuery) ||
        (buildingCode != null && buildingCode.contains(lowercaseQuery))
      ) {
        containsMatches.add(building);
      }
    }

    // 🔠 정렬된 건물 리스트에서 SearchResult 생성
    final sortedBuildings = [
      ...exactMatches,
      ...codeMatches,
      ...startMatches,
      ...containsMatches,
    ];

    return sortedBuildings.map((building) => SearchResult.fromBuilding(building)).toList();
  }

  /// 🏫 새로 추가: 건물명 검색인지 판단하는 메서드
  static bool _isBuildingNameQuery(String query, List<Building> buildings) {
    for (final building in buildings) {
      final buildingName = building.name.toLowerCase();
      
      // 괄호 안의 건물 코드 추출
      String? buildingCode;
      final codeMatch = RegExp(r'\(([^)]+)\)').firstMatch(building.name);
      if (codeMatch != null) {
        buildingCode = codeMatch.group(1)?.toLowerCase();
      }
      
      // 정확히 일치하는 건물명이나 건물 코드가 있으면 true
      if (buildingName == query || 
          (buildingCode != null && buildingCode == query) ||
          buildingName.startsWith(query)) {
        debugPrint('🏫 "$query"가 건물명 검색으로 판단됨 (매칭 건물: ${building.name})');
        return true;
      }
    }
    return false;
  }

  /// 🏫 새로 추가: 특정 건물의 모든 강의실 검색
  static Future<void> _searchClassroomsInBuilding(
    String buildingQuery, 
    List<Building> buildings, 
    List<SearchResult> results
  ) async {
    try {
      debugPrint('🏫 건물 내 강의실 검색 시작: $buildingQuery');
      
      // 매칭되는 건물들 찾기
      final matchingBuildings = buildings.where((building) {
        final buildingName = building.name.toLowerCase();
        String? buildingCode;
        final codeMatch = RegExp(r'\(([^)]+)\)').firstMatch(building.name);
        if (codeMatch != null) {
          buildingCode = codeMatch.group(1)?.toLowerCase();
        }
        
        return buildingName == buildingQuery || 
               (buildingCode != null && buildingCode == buildingQuery) ||
               buildingName.startsWith(buildingQuery);
      }).toList();
      
      if (matchingBuildings.isEmpty) {
        debugPrint('⚠️ 매칭되는 건물이 없음: $buildingQuery');
        return;
      }
      
      final ApiService apiService = ApiService();
      final allRooms = await apiService.fetchAllRooms();
      
      debugPrint('📋 전체 호실 데이터: ${allRooms.length}개');
      
      if (allRooms.isEmpty) {
        debugPrint('⚠️ 호실 데이터가 없습니다');
        return;
      }
      
      // 매칭되는 건물들의 강의실 찾기
      for (final building in matchingBuildings) {
        final buildingApiName = _extractBuildingNameForAPI(building.name);
        
        final buildingRooms = allRooms.where((roomData) {
          final roomBuildingName = _safeGetString(roomData, 'Building_Name');
          return roomBuildingName != null && 
                 roomBuildingName.toLowerCase() == buildingApiName.toLowerCase();
        }).toList();
        
        debugPrint('🏫 ${building.name} 건물의 강의실: ${buildingRooms.length}개');
        
        // 강의실을 SearchResult로 변환
        for (final roomData in buildingRooms) {
          try {
            final searchResult = _createRoomSearchResult(roomData, [building]);
            if (searchResult != null) {
              results.add(searchResult);
              debugPrint('✅ 강의실 검색 결과 추가: ${searchResult.displayName}');
            }
          } catch (e) {
            debugPrint('❌ 개별 강의실 처리 오류: $e');
          }
        }
      }
      
    } catch (e) {
      debugPrint('❌ 건물 내 강의실 검색 오류: $e');
    }
  }

  /// 🔢 호실 번호인지 판단하는 메서드
  static bool _isRoomNumberQuery(String query) {
    final isRoom = RegExp(r'^\d+').hasMatch(query);
    debugPrint('🔢 "$query"가 호실 번호인가? $isRoom');
    return isRoom;
  }

  /// 🔥 개선된 호실 번호 검색 (안정성 향상)
  static Future<void> _searchRoomsByNumber(
    String roomQuery, 
    List<Building> buildings, 
    List<SearchResult> results
  ) async {
    try {
      debugPrint('🔍 호실 번호 검색 시작: $roomQuery');
      
      final ApiService apiService = ApiService();
      final allRooms = await apiService.fetchAllRooms();
      
      debugPrint('📋 전체 호실 데이터: ${allRooms.length}개');
      
      if (allRooms.isEmpty) {
        debugPrint('⚠️ 호실 데이터가 없습니다');
        return;
      }

      // 첫 번째 호실 구조 로깅
      if (allRooms.isNotEmpty) {
        final firstRoom = allRooms[0];
        debugPrint('🏠 호실 데이터 구조: ${firstRoom.keys.toList()}');
      }
      
      // 호실 번호가 일치하는 호실들 찾기
      final matchingRooms = allRooms.where((roomData) {
        final roomName = _safeGetString(roomData, 'Room_Name');
        return roomName != null && roomName.toLowerCase().contains(roomQuery);
      }).toList();
      
      debugPrint('🎯 일치하는 호실: ${matchingRooms.length}개');
      
      for (final roomData in matchingRooms) {
        try {
          final searchResult = _createRoomSearchResult(roomData, buildings);
          if (searchResult != null) {
            results.add(searchResult);
            debugPrint('✅ 호실 번호 검색 결과 추가: ${searchResult.displayName}');
          }
        } catch (e) {
          debugPrint('❌ 개별 호실 처리 오류: $e');
        }
      }
      
    } catch (e) {
      debugPrint('❌ 호실 번호 검색 오류: $e');
    }
  }

  /// 🔥 새로운 메서드: 모든 건물에서 호실 검색 (일반 검색어용)
  static Future<void> _searchRoomsInAllBuildings(
    String query, 
    List<Building> buildings, 
    List<SearchResult> results
  ) async {
    try {
      debugPrint('🏠 모든 건물 호실 검색 시작: $query');
      
      final ApiService apiService = ApiService();
      final allRooms = await apiService.fetchAllRooms();
      
      debugPrint('📋 전체 호실 데이터: ${allRooms.length}개');
      
      if (allRooms.isEmpty) {
        debugPrint('⚠️ 호실 데이터가 없습니다');
        return;
      }
      
      // 검색어와 일치하는 호실들 찾기 (호실명, 설명 포함)
final matchingRooms = allRooms.where((roomData) {
  final roomName = _safeGetString(roomData, 'Room_Name');
  final roomDescription = _safeGetString(roomData, 'Room_Description');
  final roomUsers = roomData['Room_User']; // room_user는 일반적으로 List나 String

  final roomNameMatch = roomName != null && roomName.toLowerCase().contains(query);
  final descriptionMatch = roomDescription != null && roomDescription.toLowerCase().contains(query);

  bool userMatch = false;
  if (roomUsers is List) {
    userMatch = roomUsers.any((user) =>
      user != null && user.toString().toLowerCase().contains(query)
    );
  } else if (roomUsers != null) {
    userMatch = roomUsers.toString().toLowerCase().contains(query);
  }

  return roomNameMatch || descriptionMatch || userMatch;
}).toList();

      
      debugPrint('🎯 일치하는 호실: ${matchingRooms.length}개');
      
      // 결과 수 제한 (성능을 위해)
      final limitedRooms = matchingRooms.take(50).toList();
      if (matchingRooms.length > 50) {
        debugPrint('⚠️ 검색 결과가 많아 50개로 제한');
      }
      
      for (final roomData in limitedRooms) {
        try {
          final searchResult = _createRoomSearchResult(roomData, buildings);
          if (searchResult != null) {
            results.add(searchResult);
          }
        } catch (e) {
          debugPrint('❌ 개별 호실 처리 오류: $e');
        }
      }
      
    } catch (e) {
      debugPrint('❌ 모든 건물 호실 검색 오류: $e');
    }
  }

  /// 🔥 안전한 호실 SearchResult 생성
// lib/services/integrated_search_service.dart

static SearchResult? _createRoomSearchResult(Map<String, dynamic> roomData, List<Building> buildings) {
  try {
    final buildingName = _safeGetString(roomData, 'Building_Name');
    final floorNumber = _safeGetString(roomData, 'Floor_Number');
    final roomName = _safeGetString(roomData, 'Room_Name');
    final roomDescription = _safeGetString(roomData, 'Room_Description');
    final usersRaw  = roomData['Room_User'];
    final phonesRaw = roomData['User_Phone'];
    final emailsRaw = roomData['User_Email'];

    List<String> parseList(dynamic raw) {
      if (raw is List) {
        return raw.where((e) => e != null && e.toString().trim().isNotEmpty).map((e) => e.toString()).toList();
      } else if (raw != null && raw.toString().trim().isNotEmpty) {
        return [raw.toString()];
      }
      return [];
    }

    final roomUserList = parseList(usersRaw);
    final roomPhoneList = parseList(phonesRaw);
    final roomEmailList = parseList(emailsRaw);

    if (buildingName == null || roomName == null) {
      debugPrint('❌ 필수 데이터 누락: buildingName=$buildingName, roomName=$roomName');
      return null;
    }

    // building, floorInt 파싱
    final building = buildings.firstWhere(
      (b) => _extractBuildingNameForAPI(b.name).toLowerCase() == buildingName.toLowerCase(),
      orElse: () => buildings.firstWhere(
        (b) => b.name.toLowerCase().contains(buildingName.toLowerCase()) ||
              buildingName.toLowerCase().contains(_extractBuildingNameForAPI(b.name).toLowerCase()),
        orElse: () => buildings.first,
      ),
    );
    int? floorInt;
    if (floorNumber != null) {
      floorInt = int.tryParse(floorNumber) ?? 1;
    }

    return SearchResult.fromRoom(
      building: building,
      roomNumber: roomName,
      floorNumber: floorInt ?? 1,
      roomDescription: roomDescription?.isNotEmpty == true ? roomDescription : null,
      roomUser: roomUserList,
      roomPhone: roomPhoneList,
      roomEmail: roomEmailList,
    );

  } catch (e) {
    debugPrint('❌ 호실 SearchResult 생성 오류: $e');
    return null;
  }
}

  /// 🔥 안전한 문자열 추출 헬퍼
  static String? _safeGetString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    
    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? null : stringValue;
  }

  /// 중복 제거
  static List<SearchResult> _removeDuplicates(List<SearchResult> results) {
    final seen = <String>{};
    final filtered = results.where((result) {
      final key = '${result.type.name}_${result.displayName}_${result.building.name}_${result.floorNumber}';
      if (seen.contains(key)) {
        return false;
      }
      seen.add(key);
      return true;
    }).toList();
    
    debugPrint('🔄 중복 제거: ${results.length} → ${filtered.length}');
    return filtered;
  }

  /// 결과 정렬 (건물 먼저, 그 다음 호실, 관련도 순)
  static List<SearchResult> _sortResults(List<SearchResult> results, String query) {
    results.sort((a, b) {
      // 1. 타입별 정렬 (건물 먼저)
      if (a.type != b.type) {
        return a.type == SearchResultType.building ? -1 : 1;
      }
      
      // 2. 관련도 순 정렬
      final aRelevance = _calculateRelevance(a, query);
      final bRelevance = _calculateRelevance(b, query);
      
      if (aRelevance != bRelevance) {
        return bRelevance.compareTo(aRelevance); // 높은 관련도 먼저
      }
      
      // 3. 이름 순 정렬
      return a.displayName.compareTo(b.displayName);
    });
    
    debugPrint('🔄 결과 정렬 완료');
    return results;
  }

  /// 관련도 계산 (높을수록 더 관련있음)
  static int _calculateRelevance(SearchResult result, String query) {
    final displayName = result.displayName.toLowerCase();
    final query_lower = query.toLowerCase();
    
    if (displayName == query_lower) return 100; // 정확히 일치
    if (displayName.startsWith(query_lower)) return 90; // 시작 부분 일치
    if (displayName.contains(query_lower)) return 80; // 포함
    
    // 호실의 경우 호실 번호 확인
    if (result.isRoom && result.roomNumber != null) {
      final roomNumber = result.roomNumber!.toLowerCase();
      if (roomNumber == query_lower) return 95;
      if (roomNumber.startsWith(query_lower)) return 85;
      if (roomNumber.contains(query_lower)) return 75;
    }
    
    // 호실 설명에서 검색
    if (result.isRoom && result.roomDescription != null) {
      final description = result.roomDescription!.toLowerCase();
      if (description.contains(query_lower)) return 70;
    }
    
    // 건물명에서 검색
    final buildingName = result.building.name.toLowerCase();
    if (buildingName.contains(query_lower)) return 60;
    
    return 0;
  }

  /// 🔥 건물명에서 API 호출용 이름 추출하는 헬퍼 함수
  static String _extractBuildingNameForAPI(String fullBuildingName) {
    // 괄호 안의 코드만 추출 (예: "서캠퍼스앤디컷빌딩(W19)" → "W19")
    final codeMatch = RegExp(r'\(([^)]+)\)').firstMatch(fullBuildingName);
    if (codeMatch != null) {
      final code = codeMatch.group(1);
      if (code != null && code.isNotEmpty) {
        debugPrint('🔧 API 호출용 건물명: $fullBuildingName → $code');
        return code;
      }
    }
    
    // 괄호가 없으면 전체 이름 사용
    debugPrint('🔧 API 호출용 건물명: $fullBuildingName (변경 없음)');
    return fullBuildingName;
  }
}