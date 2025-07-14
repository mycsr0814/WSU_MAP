// lib/services/integrated_search_service.dart - 성능 최적화된 버전
import 'package:flutter_application_1/inside/api_service.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/models/search_result.dart';
import 'package:flutter_application_1/repositories/building_repository.dart';
import 'package:flutter/material.dart';

class IntegratedSearchService {
  // 🔥 성능 최적화를 위한 인덱스 구조들
  static Map<String, Building> _buildingNameIndex = {};
  static Map<String, Building> _buildingCodeIndex = {};
  static Map<String, List<Building>> _categoryIndex = {};
  static Map<String, List<Building>> _keywordIndex = {};
  static bool _isIndexBuilt = false;
  static DateTime? _lastIndexUpdate;
  
  // 🔥 캐시된 API 결과
  static Map<String, List<Map<String, dynamic>>> _roomCache = {};
  static DateTime? _lastRoomCacheUpdate;
  static const Duration _cacheValidDuration = Duration(minutes: 10);

  /// 🔥 메인 검색 메서드 - 성능 최적화됨
  static Future<List<SearchResult>> search(String query, BuildContext context) async {
    final lowercaseQuery = query.toLowerCase().trim();
    
    debugPrint('🔍🔍🔍 === 최적화된 통합 검색 시작: "$query" ===');
    
    if (lowercaseQuery.isEmpty) {
      return [];
    }

    // 🔥 인덱스 구축 확인
    await _ensureIndexIsBuilt();

    List<SearchResult> results = [];

    try {
      // 🔥 1단계: 인덱스를 사용한 빠른 건물 검색
      final buildingResults = _searchBuildingsOptimized(lowercaseQuery);
      
      // 🔥 2단계: 우선순위별 건물 분류
      final prioritizedBuildings = _prioritizeBuildings(buildingResults, lowercaseQuery);
      
      // 🔥 3단계: 각 우선순위별로 결과 추가 및 호실 검색
      await _addBuildingResultsWithRooms(prioritizedBuildings, lowercaseQuery, results);
      
      // 🔥 4단계: 호실 번호 직접 검색 (숫자로 시작하는 경우)
      if (_isRoomNumberQuery(lowercaseQuery)) {
        await _searchRoomsByNumberOptimized(lowercaseQuery, results);
      }

    } catch (e) {
      debugPrint('❌ 최적화된 통합 검색 오류: $e');
    }

    // 🔥 5단계: 중복 제거 및 최종 정렬
    results = _removeDuplicatesOptimized(results);
    results = _sortResultsOptimized(results, lowercaseQuery);

    debugPrint('📊 최적화된 검색 결과 요약:');
    debugPrint('   총 결과: ${results.length}개');
    debugPrint('   건물 결과: ${results.where((r) => r.isBuilding).length}개');
    debugPrint('   호실 결과: ${results.where((r) => r.isRoom).length}개');
    
    debugPrint('🔍 최적화된 검색 완료: ${results.length}개 결과');
    
    return results;
  }

  /// 🔥 인덱스 구축 확인 및 업데이트
  static Future<void> _ensureIndexIsBuilt() async {
    final now = DateTime.now();
    
    // 인덱스가 없거나 1시간이 지났으면 재구축
    if (!_isIndexBuilt || 
        _lastIndexUpdate == null || 
        now.difference(_lastIndexUpdate!) > const Duration(hours: 1)) {
      
      debugPrint('🔧 검색 인덱스 구축 중...');
      await _buildSearchIndex();
      debugPrint('✅ 검색 인덱스 구축 완료');
    }
  }

  /// 🔥 검색 인덱스 구축 - O(n) 시간으로 모든 인덱스 생성
static Future<void> _buildSearchIndex() async {
  try {
    final buildingRepo = BuildingRepository();
    final result = await buildingRepo.getAllBuildings();

    if (result.isSuccess && result.data != null) {
      final buildings = result.data!;
      debugPrint('🔧 ${buildings.length}개 건물로 인덱스 구축 중...');

      // 인덱스 초기화
      _buildingNameIndex.clear();
      _buildingCodeIndex.clear();
      _categoryIndex.clear();
      _keywordIndex.clear();

      // 각 건물에 대해 인덱스 구축
      for (final building in buildings) {
        // 1. 이름 인덱스 (완전한 이름)
        _buildingNameIndex[building.name.toLowerCase()] = building;

        // 2. 코드 인덱스 (괄호 안의 코드 추출)
        final code = _extractBuildingCode(building.name);
        if (code.isNotEmpty) {
          _buildingCodeIndex[code.toLowerCase()] = building;
        }

        // 3. 카테고리 인덱스
        final category = building.category.toLowerCase();
        _categoryIndex[category] = (_categoryIndex[category] ?? [])..add(building);

        // 4. 키워드 인덱스 (이름과 정보를 단어별로 분할)
        final keywords = _extractKeywords(building);
        for (final keyword in keywords) {
          _keywordIndex[keyword] = (_keywordIndex[keyword] ?? [])..add(building);
        }
      }

      _isIndexBuilt = true;
      _lastIndexUpdate = DateTime.now();

      debugPrint('✅ 인덱스 구축 완료:');
      debugPrint('   이름 인덱스: ${_buildingNameIndex.length}개');
      debugPrint('   코드 인덱스: ${_buildingCodeIndex.length}개');
      debugPrint('   카테고리 인덱스: ${_categoryIndex.length}개');
      debugPrint('   키워드 인덱스: ${_keywordIndex.length}개');
    } else {
      debugPrint('❌ 인덱스 구축 실패: ${result.error}');
      _isIndexBuilt = false;
    }
  } catch (e) {
    debugPrint('❌ 인덱스 구축 실패: $e');
    _isIndexBuilt = false;
  }
}


  /// 🔥 최적화된 건물 검색 - O(1) 인덱스 검색
  static List<Building> _searchBuildingsOptimized(String query) {
    final results = <Building>{};  // Set으로 중복 자동 제거
    
    // 1. 정확한 이름 매칭 (O(1))
    final exactMatch = _buildingNameIndex[query];
    if (exactMatch != null) {
      results.add(exactMatch);
      debugPrint('✅ 정확 이름 매칭: ${exactMatch.name}');
    }
    
    // 2. 정확한 코드 매칭 (O(1))
    final codeMatch = _buildingCodeIndex[query];
    if (codeMatch != null) {
      results.add(codeMatch);
      debugPrint('✅ 정확 코드 매칭: ${codeMatch.name}');
    }
    
    // 3. 카테고리 매칭 (O(1))
    final categoryMatches = _categoryIndex[query];
    if (categoryMatches != null) {
      results.addAll(categoryMatches);
      debugPrint('✅ 카테고리 매칭: ${categoryMatches.length}개');
    }
    
    // 4. 키워드 매칭 (O(1))
    final keywordMatches = _keywordIndex[query];
    if (keywordMatches != null) {
      results.addAll(keywordMatches);
      debugPrint('✅ 키워드 매칭: ${keywordMatches.length}개');
    }
    
    // 5. 부분 매칭 (이름에 쿼리가 포함된 경우)
    for (final entry in _buildingNameIndex.entries) {
      if (entry.key.contains(query)) {
        results.add(entry.value);
      }
    }
    
    debugPrint('🔍 인덱스 검색 결과: ${results.length}개 건물');
    return results.toList();
  }

  /// 🔥 건물 우선순위 분류 - 검색 관련도에 따라 정렬
  static Map<String, List<Building>> _prioritizeBuildings(List<Building> buildings, String query) {
    final exactMatches = <Building>[];
    final codeMatches = <Building>[];
    final startMatches = <Building>[];
    final containsMatches = <Building>[];
    
    for (final building in buildings) {
      final buildingName = building.name.toLowerCase();
      final buildingCode = _extractBuildingCode(building.name).toLowerCase();
      
      if (buildingName == query) {
        exactMatches.add(building);
      } else if (buildingCode == query) {
        codeMatches.add(building);
      } else if (buildingName.startsWith(query)) {
        startMatches.add(building);
      } else {
        containsMatches.add(building);
      }
    }
    
    debugPrint('📊 우선순위 분류:');
    debugPrint('   정확 매칭: ${exactMatches.length}개');
    debugPrint('   코드 매칭: ${codeMatches.length}개');
    debugPrint('   시작 매칭: ${startMatches.length}개');
    debugPrint('   포함 매칭: ${containsMatches.length}개');
    
    return {
      'exact': exactMatches,
      'code': codeMatches,
      'start': startMatches,
      'contains': containsMatches,
    };
  }

  /// 🔥 건물 결과 추가 및 호실 검색 최적화
  static Future<void> _addBuildingResultsWithRooms(
    Map<String, List<Building>> prioritizedBuildings, 
    String query, 
    List<SearchResult> results
  ) async {
    
    // 우선순위 순서대로 처리
    final priorities = ['exact', 'code', 'start', 'contains'];
    
    for (final priority in priorities) {
      final buildings = prioritizedBuildings[priority] ?? [];
      
      for (final building in buildings) {
        // 건물 자체를 결과에 추가
        results.add(SearchResult.fromBuilding(building));
        
        // 🔥 높은 우선순위는 호실도 검색
        if (priority == 'exact' || priority == 'code' || priority == 'start') {
          await _addRoomsForBuildingOptimized(building, results);
        }
      }
    }
  }

  /// 🔥 최적화된 호실 추가 - 캐시 사용
  static Future<void> _addRoomsForBuildingOptimized(Building building, List<SearchResult> results) async {
    try {
      final apiBuildingName = _extractBuildingCode(building.name);
      
      // 🔥 캐시 확인
      List<Map<String, dynamic>>? roomList = _getCachedRooms(apiBuildingName);
      
      if (roomList == null) {
        // 캐시에 없으면 API 호출
        debugPrint('📞 API 호출: fetchRoomsByBuilding("$apiBuildingName")');
        final apiService = ApiService();
        roomList = await apiService.fetchRoomsByBuilding(apiBuildingName);
        
        // 🔥 결과를 캐시에 저장
        _cacheRooms(apiBuildingName, roomList);
      } else {
        debugPrint('⚡ 캐시된 호실 데이터 사용: ${roomList.length}개');
      }
      
      // 호실 결과 추가 (최대 10개로 제한)
      int addedRooms = 0;
      for (final roomData in roomList.take(10)) {
        try {
          final roomName = roomData['Room_Name'] as String?;
          final floorNumber = roomData['Floor_Number'] as String?;
          final roomDescription = roomData['Room_Description'] as String?;
          
          if (roomName != null && roomName.isNotEmpty) {
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
            addedRooms++;
          }
        } catch (e) {
          debugPrint('❌ 개별 호실 처리 오류: $e');
        }
      }
      
      debugPrint('✅ ${building.name}: ${addedRooms}개 호실 추가');
      
    } catch (e) {
      debugPrint('❌ ${building.name} 호실 로드 실패: $e');
    }
  }

  /// 🔥 최적화된 호실 번호 검색 - 캐시 사용
  static Future<void> _searchRoomsByNumberOptimized(String roomQuery, List<SearchResult> results) async {
    try {
      debugPrint('🔍 최적화된 호실 번호 검색: $roomQuery');
      
      // 🔥 전체 호실 캐시 확인
      List<Map<String, dynamic>>? allRooms = _getCachedRooms('ALL_ROOMS');
      
      if (allRooms == null) {
        final apiService = ApiService();
        allRooms = await apiService.fetchAllRooms();
        _cacheRooms('ALL_ROOMS', allRooms);
        debugPrint('📋 전체 호실 데이터 로딩: ${allRooms.length}개');
      } else {
        debugPrint('⚡ 캐시된 전체 호실 데이터 사용: ${allRooms.length}개');
      }
      
      // 🔥 빠른 필터링
      final matchingRooms = allRooms.where((roomData) {
        final roomName = roomData['Room_Name'] as String?;
        return roomName != null && roomName.toLowerCase().contains(roomQuery);
      }).take(20).toList(); // 최대 20개로 제한
      
      debugPrint('🎯 일치하는 호실: ${matchingRooms.length}개');
      
      // BuildingRepository에서 건물 인덱스 가져오기
      for (final roomData in matchingRooms) {
        try {
          final buildingName = roomData['Building_Name'] as String?;
          final building = _buildingNameIndex[buildingName?.toLowerCase()];
          
          if (building != null) {
            final roomName = roomData['Room_Name'] as String?;
            final floorNumber = roomData['Floor_Number'] as String?;
            final roomDescription = roomData['Room_Description'] as String?;
            
            if (roomName != null) {
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
            }
          }
        } catch (e) {
          debugPrint('❌ 호실 번호 검색 - 개별 처리 오류: $e');
        }
      }
      
    } catch (e) {
      debugPrint('❌ 호실 번호 검색 오류: $e');
    }
  }

  /// 🔥 캐시 관련 메서드들
  static List<Map<String, dynamic>>? _getCachedRooms(String key) {
    if (_roomCache.containsKey(key) && _lastRoomCacheUpdate != null) {
      final timeDiff = DateTime.now().difference(_lastRoomCacheUpdate!);
      if (timeDiff < _cacheValidDuration) {
        return _roomCache[key];
      }
    }
    return null;
  }

  static void _cacheRooms(String key, List<Map<String, dynamic>> rooms) {
    _roomCache[key] = rooms;
    _lastRoomCacheUpdate = DateTime.now();
  }

  /// 🔥 최적화된 중복 제거 - Set 사용
  static List<SearchResult> _removeDuplicatesOptimized(List<SearchResult> results) {
    final seen = <String>{};
    final filtered = <SearchResult>[];
    
    for (final result in results) {
      final key = '${result.type.name}_${result.displayName}_${result.building.name}';
      if (!seen.contains(key)) {
        seen.add(key);
        filtered.add(result);
      }
    }
    
    debugPrint('🔄 최적화된 중복 제거: ${results.length} → ${filtered.length}');
    return filtered;
  }

  /// 🔥 최적화된 정렬
  static List<SearchResult> _sortResultsOptimized(List<SearchResult> results, String query) {
    // 사전 계산된 관련도로 정렬
    final scoredResults = results.map((result) {
      final score = _calculateRelevanceOptimized(result, query);
      return {'result': result, 'score': score};
    }).toList();
    
    scoredResults.sort((a, b) {
      final scoreComparison = (b['score'] as int).compareTo(a['score'] as int);
      if (scoreComparison != 0) return scoreComparison;
      
      // 점수가 같으면 타입별 정렬 (건물 먼저)
      final aResult = a['result'] as SearchResult;
      final bResult = b['result'] as SearchResult;
      
      if (aResult.type != bResult.type) {
        return aResult.type == SearchResultType.building ? -1 : 1;
      }
      
      return aResult.displayName.compareTo(bResult.displayName);
    });
    
    return scoredResults.map((item) => item['result'] as SearchResult).toList();
  }

  /// 🔥 최적화된 관련도 계산
  static int _calculateRelevanceOptimized(SearchResult result, String query) {
    final displayName = result.displayName.toLowerCase();
    final query_lower = query.toLowerCase();
    
    // 기본 점수들 (한 번만 계산)
    if (displayName == query_lower) return 100;
    if (displayName.startsWith(query_lower)) return 90;
    if (displayName.contains(query_lower)) return 80;
    
    // 호실의 경우 추가 점수
    if (result.isRoom && result.roomNumber != null) {
      final roomNumber = result.roomNumber!.toLowerCase();
      if (roomNumber == query_lower) return 95;
      if (roomNumber.startsWith(query_lower)) return 85;
      if (roomNumber.contains(query_lower)) return 75;
    }
    
    return 0;
  }

  /// 🔥 유틸리티 메서드들
  static bool _isRoomNumberQuery(String query) {
    return RegExp(r'^\d+').hasMatch(query);
  }

  static String _extractBuildingCode(String buildingName) {
    final regex = RegExp(r'\(([^)]+)\)');
    final match = regex.firstMatch(buildingName);
    return match?.group(1) ?? buildingName;
  }

  static Set<String> _extractKeywords(Building building) {
    final keywords = <String>{};
    
    // 이름을 단어별로 분할
    final nameWords = building.name.toLowerCase().split(RegExp(r'[^\w가-힣]'));
    keywords.addAll(nameWords.where((word) => word.length > 1));
    
    // 정보를 단어별로 분할
    final infoWords = building.info.toLowerCase().split(RegExp(r'[^\w가-힣]'));
    keywords.addAll(infoWords.where((word) => word.length > 1));
    
    // 카테고리 추가
    keywords.add(building.category.toLowerCase());
    
    return keywords;
  }

  /// 🔥 캐시 무효화
  static void invalidateCache() {
    _roomCache.clear();
    _lastRoomCacheUpdate = null;
    debugPrint('🗑️ 호실 캐시 무효화');
  }

  /// 🔥 인덱스 무효화
  static void invalidateIndex() {
    _buildingNameIndex.clear();
    _buildingCodeIndex.clear();
    _categoryIndex.clear();
    _keywordIndex.clear();
    _isIndexBuilt = false;
    _lastIndexUpdate = null;
    debugPrint('🗑️ 검색 인덱스 무효화');
  }

  /// 🔥 전체 캐시 및 인덱스 초기화
  static void clearAll() {
    invalidateCache();
    invalidateIndex();
    debugPrint('🗑️ 통합 검색 서비스 전체 초기화');
  }

  /// 🔥 성능 통계 출력
  static void printPerformanceStats() {
    debugPrint('=== IntegratedSearchService Performance Stats ===');
    debugPrint('인덱스 구축 여부: $_isIndexBuilt');
    debugPrint('마지막 인덱스 업데이트: $_lastIndexUpdate');
    debugPrint('이름 인덱스 크기: ${_buildingNameIndex.length}');
    debugPrint('코드 인덱스 크기: ${_buildingCodeIndex.length}');
    debugPrint('카테고리 인덱스 크기: ${_categoryIndex.length}');
    debugPrint('키워드 인덱스 크기: ${_keywordIndex.length}');
    debugPrint('호실 캐시 크기: ${_roomCache.length}');
    debugPrint('마지막 캐시 업데이트: $_lastRoomCacheUpdate');
    debugPrint('===============================================');
  }
}