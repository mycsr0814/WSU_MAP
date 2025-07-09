// models/category.dart
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
      categoryName: json['Category_Name'] ?? '',
      buildingName: json['Building_Name'],
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
    return CategoryLocation(
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }
}

class CategoryBuilding {
  final String buildingName;
  final CategoryLocation location;
  final String? categoryName; // 카테고리 정보 추가

  CategoryBuilding({
    required this.buildingName,
    required this.location,
    this.categoryName,
  });

  factory CategoryBuilding.fromJson(Map<String, dynamic> json) {
    return CategoryBuilding(
      buildingName: json['Building_Name'] ?? '',
      location: CategoryLocation.fromJson(json['Location']),
      categoryName: json['Category_Name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Building_Name': buildingName,
      'Location': location.toJson(),
      'Category_Name': categoryName,
    };
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
}