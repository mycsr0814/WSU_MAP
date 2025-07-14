// lib/services/category_api_service.dart - 안정화된 버전
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/data/category_fallback_data.dart';
import '../models/category.dart';

class CategoryApiService {
  static final String baseUrl = ApiConfig.categoryBase;
  
  // 🔥 연결 상태 캐시
  static bool? _lastConnectionStatus;
  static DateTime? _lastConnectionCheck;
  static const Duration _connectionCacheTime = Duration(minutes: 5);

  /// 🔥 개선된 카테고리 목록 조회 - fallback 지원
  static Future<List<Category>> getCategories() async {
    try {
      debugPrint('🔍 getCategories 시작');
      
      // 🔥 연결 상태 확인 (캐시된 결과 사용)
      final isConnected = await _checkConnection();
      if (!isConnected) {
        debugPrint('⚠️ 서버 연결 불가, fallback 데이터 사용');
        return _getFallbackCategories();
      }

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8));
      
      debugPrint('🔍 getCategories 응답: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('📄 응답 데이터 개수: ${data.length}');
        
        // 카테고리 이름들을 Set으로 수집해서 중복 제거
        Set<String> categoryNames = {};
        
        for (var item in data) {
          if (item is Map<String, dynamic> && item.containsKey('Category_Name')) {
            final categoryName = item['Category_Name']?.toString();
            if (categoryName != null && categoryName.isNotEmpty) {
              categoryNames.add(categoryName);
            }
          }
        }
        
        if (categoryNames.isNotEmpty) {
          // Set을 List<Category>로 변환
          final categories = categoryNames.map((name) => Category(categoryName: name)).toList();
          debugPrint('✅ 서버에서 카테고리 로딩 성공: ${categories.length}개');
          return categories;
        } else {
          debugPrint('⚠️ 서버 응답은 성공했지만 카테고리가 비어있음');
          return _getFallbackCategories();
        }
        
      } else {
        debugPrint('❌ 서버 응답 오류: ${response.statusCode}');
        return _getFallbackCategories();
      }
    } catch (e) {
      debugPrint('🚨 getCategories 에러: $e');
      return _getFallbackCategories();
    }
  }
  
  /// 🔥 개선된 카테고리별 건물 이름 조회 - fallback 지원
  static Future<List<String>> getCategoryBuildingNames(String category) async {
    try {
      debugPrint('🎯 getCategoryBuildingNames 호출: $category');
      
      // 🔥 연결 상태 확인
      final isConnected = await _checkConnection();
      if (!isConnected) {
        debugPrint('⚠️ 서버 연결 불가, fallback 데이터에서 건물 조회');
        return CategoryFallbackData.getBuildingsByCategory(category);
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/${Uri.encodeComponent(category)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8));
      
      debugPrint('📡 카테고리 응답: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<String> buildingNames = [];
        
        // {"Building_Name": "W5"} 형태 파싱
        for (var item in data) {
          if (item is Map<String, dynamic> && item.containsKey('Building_Name')) {
            final buildingName = item['Building_Name']?.toString();
            if (buildingName != null && buildingName.isNotEmpty) {
              buildingNames.add(buildingName);
            }
          }
        }
        
        if (buildingNames.isNotEmpty) {
          debugPrint('🏢 서버에서 건물 목록 조회 성공: $buildingNames');
          return buildingNames;
        } else {
          debugPrint('⚠️ 서버에서 해당 카테고리의 건물을 찾지 못함, fallback 사용');
          return CategoryFallbackData.getBuildingsByCategory(category);
        }
        
      } else if (response.statusCode == 404) {
        debugPrint('⚠️ 카테고리 "$category"를 서버에서 찾지 못함, fallback 사용');
        return CategoryFallbackData.getBuildingsByCategory(category);
      } else {
        debugPrint('❌ 서버 응답 오류: ${response.statusCode}, fallback 사용');
        return CategoryFallbackData.getBuildingsByCategory(category);
      }
      
    } catch (e) {
      debugPrint('🚨 getCategoryBuildingNames 에러: $e, fallback 사용');
      return CategoryFallbackData.getBuildingsByCategory(category);
    }
  }

  /// 🔥 연결 상태 확인 (캐시 지원)
  static Future<bool> _checkConnection() async {
    try {
      // 캐시된 결과 확인
      if (_lastConnectionStatus != null && _lastConnectionCheck != null) {
        final timeDiff = DateTime.now().difference(_lastConnectionCheck!);
        if (timeDiff < _connectionCacheTime) {
          debugPrint('🔄 연결 상태 캐시 사용: $_lastConnectionStatus');
          return _lastConnectionStatus!;
        }
      }

      debugPrint('🔍 서버 연결 상태 확인 중...');
      
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 3));
      
      final isConnected = response.statusCode == 200 || response.statusCode == 404;
      
      // 캐시 업데이트
      _lastConnectionStatus = isConnected;
      _lastConnectionCheck = DateTime.now();
      
      debugPrint('🌐 서버 연결 상태: $isConnected');
      return isConnected;
      
    } catch (e) {
      debugPrint('❌ 서버 연결 확인 실패: $e');
      
      // 캐시 업데이트
      _lastConnectionStatus = false;
      _lastConnectionCheck = DateTime.now();
      
      return false;
    }
  }

  /// 🔥 Fallback 카테고리 데이터 반환
  static List<Category> _getFallbackCategories() {
    final categoryNames = CategoryFallbackData.getCategories();
    final categories = categoryNames.map((name) => Category(categoryName: name)).toList();
    debugPrint('🔄 Fallback 카테고리 반환: ${categories.length}개');
    return categories;
  }

  /// 🔥 연결 상태 캐시 무효화
  static void invalidateConnectionCache() {
    _lastConnectionStatus = null;
    _lastConnectionCheck = null;
    debugPrint('🗑️ 연결 상태 캐시 무효화');
  }

  /// 🔥 수동 연결 테스트
  static Future<bool> testConnection() async {
    invalidateConnectionCache();
    return await _checkConnection();
  }

  // 🔥 기존 메서드들 유지 (호환성)
  static Future<List<CategoryBuilding>> getCategoryBuildings(String category) async {
    debugPrint('⚠️ getCategoryBuildings는 더 이상 사용되지 않습니다. getCategoryBuildingNames를 사용하세요.');
    return [];
  }
  
  // 기존 층별 카테고리 메서드들...
  static Future<List<CategoryLocation>> getBuildingFloorCategories(
    String building, 
    String floor
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/${Uri.encodeComponent(building)}/${Uri.encodeComponent(floor)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CategoryLocation.fromJson(json)).toList();
      } else {
        throw Exception('건물 층별 카테고리를 불러올 수 없습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('건물 층별 카테고리 조회 실패: $e');
    }
  }
  
  static Future<bool> addCategory(
    String building, 
    String floor, 
    String category, 
    double x, 
    double y
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/${Uri.encodeComponent(building)}/${Uri.encodeComponent(floor)}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'category': category,
          'x': x,
          'y': y,
        }),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 201;
    } catch (e) {
      throw Exception('카테고리 추가 중 오류: $e');
    }
  }
  
  static Future<bool> deleteCategory(String building, String floor) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/${Uri.encodeComponent(building)}/${Uri.encodeComponent(floor)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        throw Exception('존재하지 않는 건물/층입니다.');
      } else {
        throw Exception('카테고리 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('카테고리 삭제 중 오류: $e');
    }
  }

  /// 🔥 디버그 정보 출력
  static void printDebugInfo() {
    debugPrint('=== CategoryApiService Debug Info ===');
    debugPrint('Base URL: $baseUrl');
    debugPrint('Last Connection Status: $_lastConnectionStatus');
    debugPrint('Last Connection Check: $_lastConnectionCheck');
    debugPrint('Fallback Categories: ${CategoryFallbackData.getCategories().length}개');
    debugPrint('=====================================');
  }
}