// lib/models/category_marker_data.dart
import 'package:flutter/material.dart';

/// 🔥 카테고리 마커 데이터 클래스
class CategoryMarkerData {
  final String buildingName;
  final Location location;
  final String category;
  final IconData icon;

  CategoryMarkerData({
    required this.buildingName,
    required this.location,
    required this.category,
    required this.icon,
  });

  @override
  String toString() {
    return 'CategoryMarkerData(buildingName: $buildingName, category: $category, location: (${location.x}, ${location.y}))';
  }
}

/// 🔥 간단한 위치 정보 클래스 (Building과 독립적)
class Location {
  final double x; // latitude
  final double y; // longitude

  Location({
    required this.x,
    required this.y,
  });

  @override
  String toString() {
    return 'Location(x: $x, y: $y)';
  }
}