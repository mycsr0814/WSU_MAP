// models/category.dart - 개선된 버전
class Category {
  final String categoryName;
  final String? buildingName;
  final CategoryLocation? location;

  Category({
    required this.categoryName,
    this.buildingName,
    this.location,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryName: json['Category_Name']?.toString() ?? '',
      buildingName: json['Building_Name']?.toString(),
      location: json['Location'] != null 
          ? CategoryLocation.fromJson(json['Location'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Category_Name': categoryName,
      'Building_Name': buildingName,
      'Location': location?.toJson(),
    };
  }
}

class CategoryLocation {
  final double x;
  final double y;

  CategoryLocation({
    required this.x,
    required this.y,
  });

  factory CategoryLocation.fromJson(Map<String, dynamic> json) {
    // 🔥 더 안전한 파싱
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return CategoryLocation(
      x: parseDouble(json['x']),
      y: parseDouble(json['y']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }

  @override
  String toString() {
    return 'CategoryLocation(x: $x, y: $y)';
  }
}

class CategoryBuilding {
  final String buildingName;
  final CategoryLocation location;
  final String? categoryName;

  CategoryBuilding({
    required this.buildingName,
    required this.location,
    this.categoryName,
  });

  factory CategoryBuilding.fromJson(Map<String, dynamic> json) {
    print('🔍 CategoryBuilding.fromJson 호출: $json');
    
    // Location 파싱 체크
    if (json['Location'] == null) {
      print('🚨 Location이 null입니다!');
      throw Exception('Location 데이터가 없습니다');
    }
    
    final building = CategoryBuilding(
      buildingName: json['Building_Name']?.toString() ?? '',
      location: CategoryLocation.fromJson(json['Location']),
      categoryName: json['Category_Name']?.toString(),
    );
    
    print('✅ CategoryBuilding 생성: ${building.buildingName}, 위치: ${building.location}');
    return building;
  }

  Map<String, dynamic> toJson() {
    return {
      'Building_Name': buildingName,
      'Location': location.toJson(),
      'Category_Name': categoryName,
    };
  }

  @override
  String toString() {
    return 'CategoryBuilding(buildingName: $buildingName, location: $location, categoryName: $categoryName)';
  }
}

// 카테고리 마커 정보를 위한 클래스
class CategoryMarker {
  final String buildingName;
  final String categoryName;
  final CategoryLocation location;

  CategoryMarker({
    required this.buildingName,
    required this.categoryName,
    required this.location,
  });

  factory CategoryMarker.fromCategoryBuilding(CategoryBuilding building, String category) {
    return CategoryMarker(
      buildingName: building.buildingName,
      categoryName: category,
      location: building.location,
    );
  }

  @override
  String toString() {
    return 'CategoryMarker(buildingName: $buildingName, categoryName: $categoryName, location: $location)';
  }
}