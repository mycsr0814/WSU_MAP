// lib/data/category_fallback_data.dart - 새로 생성
// 카테고리 API 실패 시 사용할 fallback 데이터

import 'package:flutter/material.dart';

class CategoryFallbackData {
  
  /// 🔥 카테고리별 건물 매핑 데이터
  static const Map<String, List<String>> categoryBuildingMap = {
    // 편의시설
    '라운지': [
      'W1', 'W10', 'W12', 'W13', 'W19', 'W3', 'W5', 'W6'
    ],
    '자판기': [
      'W1', 'W10', 'W2', 'W4', 'W5', 'W6'
    ],
    '정수기': [
      'W1', 'W10', 'W11', 'W12', 'W13', 'W14', 'W15', 'W16', 
      'W17-동관', 'W17-서관', 'W18', 'W19', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'W8', 'W9'
    ],
    '편의점': [
      'W16'
    ],
    
    // 음식/카페
    '카페': [
      'W12', 'W5'
    ],
    '식당': [
      'W16'
    ],
    
    // 시설/장비
    '프린터': [
      'W1', 'W10', 'W12', 'W13', 'W16', 'W19', 'W5', 'W7'
    ],
    '복사기': [
      'W1', 'W10', 'W12', 'W13', 'W16', 'W19', 'W5', 'W7'
    ],
    
    // 금융
    '은행(atm)': [
      'W1', 'W16'
    ],
    'ATM': [
      'W1', 'W16'
    ],
    
    // 안전시설
    '소화기': [
      'W1', 'W10', 'W11', 'W12', 'W13', 'W14', 'W15', 'W16', 
      'W17-동관', 'W17-서관', 'W18', 'W19', 'W2', 'W2-1', 'W3', 'W4', 'W5', 'W6', 'W7', 'W8', 'W9'
    ],
    
    // 학습/도서
    '서점': [
      'W16'
    ],
    '도서관': [
      'W1', 'W10'
    ],
    
    // 운동/건강
    '헬스장': [
      'W2-1', 'W5'
    ],
    '체육관': [
      'W2-1', 'W5'
    ],
    
    // 기타 서비스
    '우체국': [
      'W16'
    ],
  };

   /// 🔥 카테고리 목록 가져오기
  static List<String> getCategories() {
    return categoryBuildingMap.keys.toList()..sort();
  }

  static List<String> getBuildingsByCategory(String category) {
    return categoryBuildingMap[category] ?? [];
  }

  static bool hasCategory(String category) {
    return categoryBuildingMap.containsKey(category);
  }

  static List<String> getAllBuildings() {
    final allBuildings = <String>{};
    for (final buildings in categoryBuildingMap.values) {
      allBuildings.addAll(buildings);
    }
    return allBuildings.toList()..sort();
  }

  static List<String> getCategoriesForBuilding(String buildingName) {
    final categories = <String>[];
    for (final entry in categoryBuildingMap.entries) {
      if (entry.value.contains(buildingName)) {
        categories.add(entry.key);
      }
    }
    return categories;
  }

  static Map<String, int> getCategoryStats() {
    return categoryBuildingMap.map(
      (category, buildings) => MapEntry(category, buildings.length),
    );
  }

  /// 카테고리별 아이콘 반환 (이름 기반)
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case '카페':
        return Icons.local_cafe;
      case '식당':
        return Icons.restaurant;
      case '편의점':
        return Icons.store;
      case '자판기':
        return Icons.local_convenience_store;
      case '화장실':
        return Icons.wc;
      case '프린터':
        return Icons.print;
      case '복사기':
        return Icons.content_copy;
      case 'ATM':
      case '은행(atm)':
        return Icons.atm;
      case '의료':
      case '보건소':
        return Icons.local_hospital;
      case '도서관':
        return Icons.local_library;
      case '체육관':
      case '헬스장':
        return Icons.fitness_center;
      case '주차장':
        return Icons.local_parking;
      case '라운지':
        return Icons.weekend;
      case '소화기':
        return Icons.fire_extinguisher; // Material Icons Extended 필요
      case '정수기':
        return Icons.water_drop;
      case '서점':
        return Icons.menu_book;
      case '우체국':
        return Icons.local_post_office;
      default:
        return Icons.category;
    }
  }

  static void printDebugInfo() {
    print('=== Category Fallback Data Info ===');
    print('총 카테고리 수: ${categoryBuildingMap.length}');
    print('총 건물 수: ${getAllBuildings().length}');
    print('카테고리별 건물 수:');
    for (final entry in getCategoryStats().entries) {
      print('  ${entry.key}: ${entry.value}개');
    }
    print('=====================================');
  }
}

class CategoryUtils {
  static String normalizeCategory(String category) {
    return category.trim().toLowerCase();
  }

  static String normalizeBuilding(String building) {
    return building.trim().toUpperCase();
  }

  static int getCategoryColorValue(String category) {
    switch (category) {
      case '카페':
        return 0xFF8B4513; // 갈색
      case '식당':
        return 0xFFFF6B35; // 오렌지
      case '편의점':
        return 0xFF4CAF50; // 초록
      case '자판기':
        return 0xFF2196F3; // 파랑
      case '화장실':
        return 0xFF607D8B; // 회색
      case '프린터':
      case '복사기':
        return 0xFF9C27B0; // 보라
      case 'ATM':
      case '은행(atm)':
        return 0xFF4CAF50; // 초록
      case '의료':
      case '보건소':
        return 0xFFF44336; // 빨강
      case '도서관':
        return 0xFF3F51B5; // 남색
      case '체육관':
      case '헬스장':
        return 0xFFFF9800; // 주황
      case '주차장':
        return 0xFF795548; // 갈색
      case '라운지':
        return 0xFFE91E63; // 핑크
      case '소화기':
        return 0xFFF44336; // 빨강
      case '정수기':
        return 0xFF00BCD4; // 청록
      case '서점':
        return 0xFF673AB7; // 보라
      case '우체국':
        return 0xFF4CAF50; // 초록
      default:
        return 0xFF757575; // 기본 회색
    }
  }

  static bool isIndoorCategory(String category) {
    const indoorCategories = [
      '프린터', '복사기', 'ATM', '은행(atm)', '도서관', 
      '헬스장', '체육관', '라운지', '정수기', '서점'
    ];
    return indoorCategories.contains(category);
  }

  static bool is24HourCategory(String category) {
    const twentyFourHourCategories = [
      '자판기', '정수기', '소화기'
    ];
    return twentyFourHourCategories.contains(category);
  }
}