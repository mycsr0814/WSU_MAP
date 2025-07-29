// lib/utils/category_name_mapper.dart

class CategoryNameMapper {
  static final Map<String, String> _koreanToIdMap = {
    '카페': 'cafe',
    '식당': 'restaurant',
    '프린터': 'printer',
    '복사기': 'copier',
    'ATM': 'atm', // ATM 매핑
    '은행(atm)': 'atm', // 은행(atm) 매핑
    'bank': 'atm', // SVG의 bank ID 매핑
    '보건소': 'health_center',
    '의료': 'medical',
    '라운지': 'lounge',
    '정수기': 'water',
    '소화기': 'extinguisher',
    '서점': 'bookstore',
    '도서관': 'library',
    '헬스장': 'gym',
    '체육관': 'fitness_center',
    '편의점': 'convenience',
    '자판기': 'vending',
    '우체국': 'post_office',
  };

  /// 한국어 → ID
  static String toCategoryId(String koreanName) {
    return _koreanToIdMap[koreanName.trim()] ?? koreanName.trim().toLowerCase();
  }

  /// ID → 한국어 (예: 서버에 요청할 때)
  static String toKoreanName(String categoryId) {
    return _koreanToIdMap.entries
        .firstWhere(
          (entry) => entry.value == categoryId,
          orElse: () => const MapEntry('', ''),
        )
        .key;
  }

  /// 외부에서 한글 ↔️ ID 전체 Map 접근이 필요할 경우 사용
  static Map<String, String> get koreanToId => _koreanToIdMap;
}
