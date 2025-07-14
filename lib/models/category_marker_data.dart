// lib/models/category_marker_data.dart - 새로 생성
import 'package:flutter/material.dart';

/// 카테고리 마커 데이터를 담는 모델
class CategoryMarkerData {
  final String buildingName;
  final double lat;      // 위도
  final double lng;      // 경도
  final String category;
  final IconData icon;

  const CategoryMarkerData({
    required this.buildingName,
    required this.lat,
    required this.lng,
    required this.category,
    required this.icon,
  });

  @override
  String toString() {
    return 'CategoryMarkerData(buildingName: $buildingName, lat: $lat, lng: $lng, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryMarkerData &&
        other.buildingName == buildingName &&
        other.lat == lat &&
        other.lng == lng &&
        other.category == category &&
        other.icon == icon;
  }

  @override
  int get hashCode {
    return buildingName.hashCode ^
        lat.hashCode ^
        lng.hashCode ^
        category.hashCode ^
        icon.hashCode;
  }
}

/// 위치 정보를 담는 간단한 클래스 (기존 코드 호환성을 위해)
class Location {
  final double x;
  final double y;

  const Location({
    required this.x,
    required this.y,
  });

  @override
  String toString() => 'Location(x: $x, y: $y)';
}