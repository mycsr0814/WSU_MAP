// services/category_api_service.dart - 간단하게 건물 이름만 반환하도록 수정
import 'dart:convert';
import 'package:flutter_application_1/config/api_config.dart';
import 'package:http/http.dart' as http;
import '../models/category.dart';

class CategoryApiService {
  static final String baseUrl = ApiConfig.categoryBase;
  
  // 카테고리 목록 조회
  static Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('🔍 getCategories 응답: ${response.statusCode}');
      print('📄 응답 본문: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
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
        
        // Set을 List<Category>로 변환
        return categoryNames.map((name) => Category(categoryName: name)).toList();
        
      } else {
        throw Exception('카테고리 목록을 불러올 수 없습니다: ${response.statusCode}');
      }
    } catch (e) {
      print('🚨 getCategories 에러: $e');
      throw Exception('카테고리 목록 조회 실패: $e');
    }
  }
  
  // 🔥 카테고리별 건물 이름 목록만 반환 (지도에서 필터링 용도)
  static Future<List<String>> getCategoryBuildingNames(String category) async {
    try {
      print('🎯 getCategoryBuildingNames 호출: $category');
      
      final response = await http.get(
        Uri.parse('$baseUrl/${Uri.encodeComponent(category)}'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('📡 카테고리 응답: ${response.statusCode}');
      print('📄 응답 본문: ${response.body}');
      
      if (response.statusCode != 200) {
        throw Exception('카테고리 건물을 불러올 수 없습니다: ${response.statusCode}');
      }
      
      final List<dynamic> data = json.decode(response.body);
      List<String> buildingNames = [];
      
      // 🔥 {"Building_Name": "W5"} 형태 파싱
      for (var item in data) {
        if (item is Map<String, dynamic> && item.containsKey('Building_Name')) {
          final buildingName = item['Building_Name']?.toString();
          if (buildingName != null && buildingName.isNotEmpty) {
            buildingNames.add(buildingName);
          }
        }
      }
      
      print('🏢 건물 이름 목록: $buildingNames');
      return buildingNames;
      
    } catch (e) {
      print('🚨 getCategoryBuildingNames 에러: $e');
      throw Exception('카테고리 건물 이름 조회 실패: $e');
    }
  }
  
  // 🔥 기존 메서드는 호환성을 위해 유지 (빈 리스트 반환)
  static Future<List<CategoryBuilding>> getCategoryBuildings(String category) async {
    print('⚠️ getCategoryBuildings는 더 이상 사용되지 않습니다. getCategoryBuildingNames를 사용하세요.');
    return [];
  }
  
  // 기존 메서드들...
  static Future<List<CategoryLocation>> getBuildingFloorCategories(
    String building, 
    String floor
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/${Uri.encodeComponent(building)}/${Uri.encodeComponent(floor)}'),
        headers: {'Content-Type': 'application/json'},
      );
      
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
      );
      
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
      );
      
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
}