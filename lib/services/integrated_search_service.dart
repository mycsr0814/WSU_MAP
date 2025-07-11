// lib/services/integrated_search_service.dart - 올바른 API를 사용하는 수정된 버전

import 'package:flutter_application_1/inside/api_service.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/models/search_result.dart';
import 'package:flutter_application_1/map/building_data.dart';
import 'package:flutter/material.dart';

class IntegratedSearchService {
  
 /// 건물과 호실을 통합 검색하는 메서드 (개선된 매칭 로직)
static Future<List<SearchResult>> search(String query, BuildContext context) async {
  final lowercaseQuery = query.toLowerCase().trim();
  
  print('🔍🔍🔍 === 통합 검색 시작: "$query" ===');
  
  if (lowercaseQuery.isEmpty) {
    return [];
  }

  List<SearchResult> results = [];

  try {
    // 1. 기존 건물 데이터에서 검색
    final buildings = BuildingDataProvider.getBuildingData(context);
    print('🏢 사용 가능한 건물 수: ${buildings.length}');
    
    // 🔥 개선된 검색 우선순위 적용
    List<Building> exactMatches = []; // 정확히 일치
    List<Building> startMatches = []; // 시작 부분 일치
    List<Building> codeMatches = []; // 🔥 새로 추가: 건물 코드 일치 (W19, W17 등)
    List<Building> containsMatches = []; // 포함 일치

    for (final building in buildings) {
      final buildingName = building.name.toLowerCase();
      final buildingInfo = building.info.toLowerCase();
      final buildingCategory = building.category.toLowerCase();
      
      // 🔥 건물 코드 추출 (괄호 안의 코드)
      String? buildingCode;
      final codeMatch = RegExp(r'\(([^)]+)\)').firstMatch(building.name);
      if (codeMatch != null) {
        buildingCode = codeMatch.group(1)?.toLowerCase();
      }
      
      print('🏢 ${building.name} → 코드: $buildingCode');
      
      if (buildingName == lowercaseQuery) {
        exactMatches.add(building);
        print('✅ 정확 일치: ${building.name}');
      } else if (buildingCode != null && buildingCode == lowercaseQuery) {
        // 🔥 건물 코드가 정확히 일치하는 경우 (W19 = W19)
        codeMatches.add(building);
        print('🎯 코드 일치: ${building.name} (코드: $buildingCode)');
      } else if (buildingName.startsWith(lowercaseQuery)) {
        startMatches.add(building);
        print('🎯 시작 일치: ${building.name}');
      } else if (buildingName.contains(lowercaseQuery) || 
                 buildingInfo.contains(lowercaseQuery) || 
                 buildingCategory.contains(lowercaseQuery) ||
                 (buildingCode != null && buildingCode.contains(lowercaseQuery))) {
        containsMatches.add(building);
        print('📝 포함 일치: ${building.name}');
      }
    }

    // 🔥 우선순위에 따라 건물들을 정렬 (코드 일치를 높은 순위로)
    List<Building> sortedBuildings = [
      ...exactMatches,
      ...codeMatches,  // 🔥 코드 일치를 정확 일치 다음 순위로
      ...startMatches,
      ...containsMatches,
    ];

    print('📊 매칭된 건물들:');
    print('   정확 일치: ${exactMatches.length}개');
    print('   코드 일치: ${codeMatches.length}개'); // 🔥 추가
    print('   시작 일치: ${startMatches.length}개');
    print('   포함 일치: ${containsMatches.length}개');

    // 2. 건물 결과 추가 및 호실 검색
    int buildingCount = 0;
    for (final building in sortedBuildings) {
      buildingCount++;
      print('🏠 [$buildingCount/${sortedBuildings.length}] 처리 중: ${building.name}');
      
      // 건물 자체를 결과에 추가
      results.add(SearchResult.fromBuilding(building));
      print('   ✅ 건물 추가: ${building.name}');
      
      // 🔥 정확일치, 코드일치, 시작일치의 경우 모든 호실 추가
      if (exactMatches.contains(building) || 
          codeMatches.contains(building) ||  // 🔥 코드 일치도 포함
          startMatches.contains(building)) {
        print('   🔍 ${building.name}의 모든 호실 검색 시작');
        final roomsBefore = results.length;
        await _addAllRoomsForBuilding(building, results);
        final roomsAfter = results.length;
        print('   📊 ${building.name}: ${roomsAfter - roomsBefore}개 호실 추가됨');
      } else {
        print('   ⏭️ ${building.name}: 포함 일치이므로 호실 검색 생략');
      }
    }

    // 3. 호실 번호로 직접 검색 (예: "401", "101" 등)
    if (_isRoomNumberQuery(lowercaseQuery)) {
      print('🔍 호실 번호 직접 검색: $lowercaseQuery');
      await _searchRoomsByNumber(lowercaseQuery, buildings, results);
    }

  } catch (e) {
    print('❌ 통합 검색 오류: $e');
  }

  // 4. 중복 제거 및 정렬
  final originalCount = results.length;
  results = _removeDuplicates(results);
  results = _sortResults(results, lowercaseQuery);

  print('📊 검색 결과 요약:');
  print('   원본 결과: ${originalCount}개');
  print('   중복 제거 후: ${results.length}개');
  print('   건물 결과: ${results.where((r) => r.isBuilding).length}개');
  print('   호실 결과: ${results.where((r) => r.isRoom).length}개');
  
  // 처음 몇 개 결과 출력
  for (int i = 0; i < results.length && i < 5; i++) {
    final result = results[i];
    print('   [$i] ${result.type.name}: ${result.displayName}');
  }
  
  print('🔍 검색 완료: ${results.length}개 결과');
  
  return results;
}

  /// 호실 번호인지 판단하는 메서드
  static bool _isRoomNumberQuery(String query) {
    final isRoom = RegExp(r'^\d+').hasMatch(query);
    print('🔢 "$query"가 호실 번호인가? $isRoom');
    return isRoom;
  }

  /// 🔥 수정된 특정 건물의 모든 호실 추가 - API 호출시 올바른 건물명 사용
static Future<void> _addAllRoomsForBuilding(
  Building building, 
  List<SearchResult> results
) async {
  try {
    print('🔥🔥🔥 === ${building.name} 호실 검색 시작 ===');
    
    final ApiService apiService = ApiService();
    
    // 🔥 API 호출용 건물명 추출 (괄호 안의 코드)
    final apiBuildingName = _extractBuildingNameForAPI(building.name);
    
    print('📞 API 호출: fetchRoomsByBuilding("$apiBuildingName")');
    final roomList = await apiService.fetchRoomsByBuilding(apiBuildingName);
    
    print('✅ API 응답 받음: ${roomList.length}개 호실');
    
    if (roomList.isEmpty) {
      print('⚠️ $apiBuildingName에 호실이 없습니다');
      return;
    }
    
    // 첫 번째 호실 구조 확인
    if (roomList.isNotEmpty) {
      final firstRoom = roomList[0];
      print('🏠 첫 번째 호실 구조: $firstRoom');
      print('🗝️ 사용 가능한 키들: ${firstRoom.keys.toList()}');
    }
    
    int totalRoomsAdded = 0;
    
    for (int i = 0; i < roomList.length; i++) {
      final roomData = roomList[i];
      
      try {
        // 올바른 키 이름 사용
        final buildingName = roomData['Building_Name'] as String?;
        final floorNumber = roomData['Floor_Number'] as String?;
        final roomName = roomData['Room_Name'] as String?;
        final roomDescription = roomData['Room_Description'] as String?;
        
        if (roomName != null && roomName.isNotEmpty) {
          // 층 번호를 정수로 변환
          int? floorInt;
          if (floorNumber != null) {
            floorInt = int.tryParse(floorNumber);
          }
          
          final searchResult = SearchResult.fromRoom(
            building: building,
            roomNumber: roomName,
            floorNumber: floorInt ?? 1,
            roomDescription: roomDescription?.isNotEmpty == true ? roomDescription : null,
          );
          
          results.add(searchResult);
          totalRoomsAdded++;
          
          if (i < 5) { // 처음 5개만 로그 출력
            print('✅ 호실 추가 [$i]: ${searchResult.displayName}');
          }
        } else {
          if (i < 3) {
            print('❌ [$i] Room_Name이 없거나 비어있음: $roomData');
          }
        }
      } catch (roomError) {
        if (i < 3) {
          print('❌ [$i] 개별 호실 처리 오류: $roomError');
        }
      }
    }
    
    print('🎉 ${building.name}: 총 ${totalRoomsAdded}개 호실 추가 완료');
    
  } catch (e, stackTrace) {
    print('❌❌❌ ${building.name} 전체 호실 로드 실패: $e');
    print('❌ 스택 트레이스 일부: ${stackTrace.toString().split('\n').take(3).join('\n')}');
  }
}

  /// 🔥 수정된 호실 번호로 모든 건물에서 검색
  static Future<void> _searchRoomsByNumber(
    String roomQuery, 
    List<Building> buildings, 
    List<SearchResult> results
  ) async {
    try {
      print('🔍 호실 번호 검색 시작: $roomQuery');
      
      final ApiService apiService = ApiService();
      final allRooms = await apiService.fetchAllRooms();
      
      print('📋 전체 호실 데이터: ${allRooms.length}개');
      
      // 호실 번호가 일치하는 호실들 찾기
      final matchingRooms = allRooms.where((roomData) {
        final roomName = roomData['Room_Name'] as String?;
        return roomName != null && roomName.toLowerCase().contains(roomQuery);
      }).toList();
      
      print('🎯 일치하는 호실: ${matchingRooms.length}개');
      
      for (final roomData in matchingRooms) {
        try {
          final buildingName = roomData['Building_Name'] as String?;
          final floorNumber = roomData['Floor_Number'] as String?;
          final roomName = roomData['Room_Name'] as String?;
          final roomDescription = roomData['Room_Description'] as String?;
          
          // 해당 건물 찾기
          final building = buildings.where((b) => 
            b.name.toLowerCase() == buildingName?.toLowerCase()).firstOrNull;
          
          if (building != null && roomName != null) {
            int? floorInt;
            if (floorNumber != null) {
              floorInt = int.tryParse(floorNumber);
            }
            
            final searchResult = SearchResult.fromRoom(
              building: building,
              roomNumber: roomName,
              floorNumber: floorInt ?? 1,
              roomDescription: roomDescription?.isNotEmpty == true ? roomDescription : null,
            );
            
            results.add(searchResult);
            print('✅ 호실 번호 검색 결과 추가: ${searchResult.displayName}');
          }
        } catch (e) {
          print('❌ 개별 호실 처리 오류: $e');
        }
      }
      
    } catch (e) {
      print('❌ 호실 번호 검색 오류: $e');
    }
  }

  /// 중복 제거
  static List<SearchResult> _removeDuplicates(List<SearchResult> results) {
    final seen = <String>{};
    final filtered = results.where((result) {
      final key = '${result.type.name}_${result.displayName}_${result.building.name}';
      if (seen.contains(key)) {
        return false;
      }
      seen.add(key);
      return true;
    }).toList();
    
    print('🔄 중복 제거: ${results.length} → ${filtered.length}');
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
    
    print('🔄 결과 정렬 완료');
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
    
    return 0;
  }

  /// 🔥 추가: 건물명에서 API 호출용 이름 추출하는 헬퍼 함수
static String _extractBuildingNameForAPI(String fullBuildingName) {
  // 괄호 안의 코드만 추출 (예: "서캠퍼스앤디컷빌딩(W19)" → "W19")
  final codeMatch = RegExp(r'\(([^)]+)\)').firstMatch(fullBuildingName);
  if (codeMatch != null) {
    final code = codeMatch.group(1);
    if (code != null && code.isNotEmpty) {
      print('🔧 API 호출용 건물명: $fullBuildingName → $code');
      return code;
    }
  }
  
  // 괄호가 없으면 전체 이름 사용
  print('🔧 API 호출용 건물명: $fullBuildingName (변경 없음)');
  return fullBuildingName;
}
}