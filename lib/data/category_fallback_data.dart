// lib/data/category_fallback_data.dart - 새로 생성
/// 카테고리 API 실패 시 사용할 fallback 데이터
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

  /// 🔥 특정 카테고리의 건물 목록 가져오기
  static List<String> getBuildingsByCategory(String category) {
    return categoryBuildingMap[category] ?? [];
  }

  /// 🔥 카테고리가 존재하는지 확인
  static bool hasCategory(String category) {
    return categoryBuildingMap.containsKey(category);
  }

  /// 🔥 전체 건물 목록 가져오기 (중복 제거)
  static List<String> getAllBuildings() {
    final allBuildings = <String>{};
    for (final buildings in categoryBuildingMap.values) {
      allBuildings.addAll(buildings);
    }
    return allBuildings.toList()..sort();
  }

  /// 🔥 특정 건물이 속한 카테고리들 찾기
  static List<String> getCategoriesForBuilding(String buildingName) {
    final categories = <String>[];
    for (final entry in categoryBuildingMap.entries) {
      if (entry.value.contains(buildingName)) {
        categories.add(entry.key);
      }
    }
    return categories;
  }

  /// 🔥 카테고리별 통계 정보
  static Map<String, int> getCategoryStats() {
    return categoryBuildingMap.map(
      (category, buildings) => MapEntry(category, buildings.length),
    );
  }

  /// 🔥 카테고리별 아이콘 매핑
  static const Map<String, int> categoryIconCodePoints = {
    '카페': 0xe156, // Icons.local_cafe
    '식당': 0xe56c, // Icons.restaurant
    '편의점': 0xe59c, // Icons.store
    '자판기': 0xe1f4, // Icons.local_drink
    '화장실': 0xf05a6, // Icons.wc
    '프린터': 0xe8ad, // Icons.print
    '복사기': 0xe14f, // Icons.content_copy
    'ATM': 0xe1cb, // Icons.atm
    '은행(atm)': 0xe1cb, // Icons.atm
    '의료': 0xe3f0, // Icons.local_hospital
    '보건소': 0xe3f0, // Icons.local_hospital
    '도서관': 0xe40f, // Icons.local_library
    '체육관': 0xe25c, // Icons.fitness_center
    '헬스장': 0xe25c, // Icons.fitness_center
    '주차장': 0xe410, // Icons.local_parking
    '라운지': 0xef51, // Icons.weekend
    '소화기': 0xe1d1, // Icons.fire_extinguisher (Material Icons Extended)
    '정수기': 0xe798, // Icons.water_drop
    '서점': 0xe3f7, // Icons.menu_book
    '우체국': 0xe0e0, // Icons.local_post_office
  };

  /// 🔥 디버그용 정보 출력
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

/// 🔥 카테고리 관련 유틸리티 함수들
class CategoryUtils {
  
  /// 카테고리 이름 정규화 (공백 제거, 소문자 변환)
  static String normalizeCategory(String category) {
    return category.trim().toLowerCase();
  }

  /// 건물 이름 정규화
  static String normalizeBuilding(String building) {
    return building.trim().toUpperCase();
  }

  /// 카테고리별 색상 코드 반환
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

  /// 카테고리가 실내 시설인지 확인
  static bool isIndoorCategory(String category) {
    const indoorCategories = [
      '프린터', '복사기', 'ATM', '은행(atm)', '도서관', 
      '헬스장', '체육관', '라운지', '정수기', '서점'
    ];
    return indoorCategories.contains(category);
  }

  /// 카테고리가 24시간 이용 가능한지 확인
  static bool is24HourCategory(String category) {
    const twentyFourHourCategories = [
      '자판기', '정수기', '소화기'
    ];
    return twentyFourHourCategories.contains(category);
  }
}