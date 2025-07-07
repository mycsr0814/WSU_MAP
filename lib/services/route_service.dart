// lib/services/route_service.dart - 수정된 버전

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'dart:math';

class RouteService {
  /// 두 지점 사이의 경로 계산
  Future<List<NLatLng>> calculateRoute(NLatLng start, NLatLng end) async {
    try {
      debugPrint('경로 계산 시작: ${start.latitude}, ${start.longitude} -> ${end.latitude}, ${end.longitude}');
      
      // 실제 서버 API 호출 대신 간단한 직선 경로 생성
      // TODO: 실제 경로 API (네이버 Direction API 등) 연동
      
      final routePoints = _generateSimpleRoute(start, end);
      
      debugPrint('경로 계산 완료: ${routePoints.length}개 포인트');
      return routePoints;
      
    } catch (e) {
      debugPrint('경로 계산 오류: $e');
      return [];
    }
  }

  /// 간단한 직선 경로 생성 (임시)
  List<NLatLng> _generateSimpleRoute(NLatLng start, NLatLng end) {
    final points = <NLatLng>[];
    
    // 시작점
    points.add(start);
    
    // 중간점들 생성 (직선을 여러 구간으로 나눔)
    const segments = 10;
    for (int i = 1; i < segments; i++) {
      final ratio = i / segments;
      final lat = start.latitude + (end.latitude - start.latitude) * ratio;
      final lng = start.longitude + (end.longitude - start.longitude) * ratio;
      points.add(NLatLng(lat, lng));
    }
    
    // 끝점
    points.add(end);
    
    return points;
  }

  /// 두 지점 사이의 거리 계산 (미터)
  double calculateDistance(NLatLng start, NLatLng end) {
    const double earthRadius = 6371000; // 지구 반지름 (미터)
    
    final double lat1Rad = start.latitude * pi / 180;
    final double lat2Rad = end.latitude * pi / 180;
    final double deltaLatRad = (end.latitude - start.latitude) * pi / 180;
    final double deltaLngRad = (end.longitude - start.longitude) * pi / 180;

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// 예상 도보 시간 계산 (분)
  int calculateWalkingTime(double distanceInMeters) {
    // 평균 도보 속도: 4km/h = 67m/min
    const double walkingSpeedMeterPerMin = 67;
    return (distanceInMeters / walkingSpeedMeterPerMin).ceil();
  }
}
