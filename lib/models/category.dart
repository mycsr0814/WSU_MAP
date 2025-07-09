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

  CategoryBuilding({
    required this.buildingName,
    required this.location,
  });

  factory CategoryBuilding.fromJson(Map<String, dynamic> json) {
    return CategoryBuilding(
      buildingName: json['Building_Name'] ?? '',
      location: CategoryLocation.fromJson(json['Location']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Building_Name': buildingName,
      'Location': location.toJson(),
    };
  }
}