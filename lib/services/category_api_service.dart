// services/category_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';

class CategoryApiService {
  static const String baseUrl = 'http://3.106.229.163:3000/category';
  
  // 카테고리 목록 조회
  static Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('카테고리 목록을 불러올 수 없습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('카테고리 목록 조회 실패: $e');
    }
  }
  
  // 카테고리별 건물 위치 검색
  static Future<List<CategoryBuilding>> getCategoryBuildings(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/${Uri.encodeComponent(category)}'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CategoryBuilding.fromJson(json)).toList();
      } else {
        throw Exception('카테고리 건물을 불러올 수 없습니다: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('카테고리 건물 조회 실패: $e');
    }
  }
  
  // 건물별 층별 카테고리 위치 조회
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
  
  // 카테고리 추가
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
      
      if (response.statusCode == 201) {
        return true;
      } else {
        throw Exception('카테고리 추가 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('카테고리 추가 중 오류: $e');
    }
  }
  
  // 카테고리 삭제
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