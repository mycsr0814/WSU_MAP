// lib/services/map/route_rendering_service.dart (새로 생성)
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'dart:math';

class RouteRenderingService {
  NaverMapController? _mapController;
  
  // 경로 관련 오버레이 관리
  final List<String> _pathOverlayIds = [];
  final List<String> _routeMarkerIds = [];

  // Getters
  List<String> get pathOverlayIds => _pathOverlayIds;
  List<String> get routeMarkerIds => _routeMarkerIds;

  /// 지도 컨트롤러 설정
  void setMapController(NaverMapController controller) {
    _mapController = controller;
    debugPrint('✅ RouteRenderingService 지도 컨트롤러 설정 완료');
  }

  /// 경로 그리기 (map_service.dart에서 이동)
  Future<void> drawPath(List<NLatLng> pathCoordinates) async {
    if (_mapController == null || pathCoordinates.isEmpty) return;
    
    try {
      await clearPath();
      
      final pathOverlayId = 'route_path_${DateTime.now().millisecondsSinceEpoch}';
      final pathOverlay = NPolylineOverlay(
        id: pathOverlayId,
        coords: pathCoordinates,
        color: const Color(0xFF1E3A8A),
        width: 6,
      );
      
      await _mapController!.addOverlay(pathOverlay);
      _pathOverlayIds.add(pathOverlayId);
      
      await _addSimpleRouteMarkers(pathCoordinates);
      
    } catch (e) {
      debugPrint('경로 그리기 오류: $e');
    }
  }

  /// 예쁜 경로 마커 추가
  Future<void> _addSimpleRouteMarkers(List<NLatLng> path) async {
    if (path.length < 2) return;
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // 🔥 출발점 마커 (파란색 원형)
      final startMarkerId = 'route_start_$timestamp';
      final startMarker = NMarker(
        id: startMarkerId,
        position: path.first,
        icon: NOverlayImage.fromAssetImage('lib/asset/building_marker_blue.png'),
        size: const Size(56, 56),
        caption: NOverlayCaption(
          text: '출발',
          color: Colors.white,
          haloColor: const Color(0xFF3B82F6), // 파란색으로 변경
          textSize: 13,
        ),
      );
      
      // 🔥 도착점 마커 (빨간색 원형)
      final endMarkerId = 'route_end_$timestamp';
      final endMarker = NMarker(
        id: endMarkerId,
        position: path.last,
        icon: NOverlayImage.fromAssetImage('lib/asset/building_marker_blue.png'),
        size: const Size(56, 56),
        caption: NOverlayCaption(
          text: '도착',
          color: Colors.white,
          haloColor: const Color(0xFFEF4444), // 빨간색 유지
          textSize: 13,
        ),
      );
      
      await _mapController!.addOverlay(startMarker);
      await _mapController!.addOverlay(endMarker);
      
      _routeMarkerIds.add(startMarkerId);
      _routeMarkerIds.add(endMarkerId);
      
      debugPrint('✅ 경로 마커 추가 완료 (색상으로 구분)');
      
    } catch (e) {
      debugPrint('❌ 경로 마커 추가 오류: $e');
      // 🔥 폴백: 기본 마커로 대체
      await _addFallbackRouteMarkers(path);
    }
  }
  
  /// 🔥 폴백: 기본 마커 (아이콘 로드 실패 시)
  Future<void> _addFallbackRouteMarkers(List<NLatLng> path) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // 출발점 마커 (초록색 원)
      final startMarkerId = 'route_start_$timestamp';
      final startMarker = NMarker(
        id: startMarkerId,
        position: path.first,
        icon: NOverlayImage.fromAssetImage('lib/asset/building_marker_blue.png'),
        size: const Size(48, 48),
        caption: NOverlayCaption(
          text: '출발',
          color: Colors.white,
          haloColor: const Color(0xFF10B981),
          textSize: 12,
        ),
      );
      
      // 도착점 마커 (빨간색 원)
      final endMarkerId = 'route_end_$timestamp';
      final endMarker = NMarker(
        id: endMarkerId,
        position: path.last,
        icon: NOverlayImage.fromAssetImage('lib/asset/building_marker_blue.png'),
        size: const Size(48, 48),
        caption: NOverlayCaption(
          text: '도착',
          color: Colors.white,
          haloColor: const Color(0xFFEF4444),
          textSize: 12,
        ),
      );
      
      await _mapController!.addOverlay(startMarker);
      await _mapController!.addOverlay(endMarker);
      
      _routeMarkerIds.add(startMarkerId);
      _routeMarkerIds.add(endMarkerId);
      
      debugPrint('✅ 폴백 경로 마커 추가 완료 (색상으로 구분)');
      
    } catch (e) {
      debugPrint('❌ 폴백 마커 추가도 실패: $e');
    }
  }

  /// 경로에 맞춰 카메라 이동
  Future<void> moveCameraToPath(List<NLatLng> pathCoordinates) async {
    debugPrint('[RouteRenderingService] moveCameraToPath 호출 - 좌표 개수: ${pathCoordinates.length}');
    if (_mapController == null || pathCoordinates.isEmpty) return;

    try {
      if (pathCoordinates.length == 1) {
        // 단일 좌표면 해당 위치로 이동
        await _moveCamera(pathCoordinates.first, zoom: 16);
      } else {
        // 여러 좌표의 경계 계산
        double minLat = pathCoordinates.first.latitude;
        double maxLat = pathCoordinates.first.latitude;
        double minLng = pathCoordinates.first.longitude;
        double maxLng = pathCoordinates.first.longitude;

        for (final coord in pathCoordinates) {
          minLat = min(minLat, coord.latitude);
          maxLat = max(maxLat, coord.latitude);
          minLng = min(minLng, coord.longitude);
          maxLng = max(maxLng, coord.longitude);
        }

        final latPadding = (maxLat - minLat) * 0.1;
        final lngPadding = (maxLng - minLng) * 0.1;

        final bounds = NLatLngBounds(
          southWest: NLatLng(minLat - latPadding, minLng - lngPadding),
          northEast: NLatLng(maxLat + latPadding, maxLng + lngPadding),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          await _mapController!.updateCamera(
            NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(50)),
          ).timeout(const Duration(seconds: 5));
          debugPrint('[RouteRenderingService] moveCameraToPath 완료');
        } catch (e) {
          debugPrint('[RouteRenderingService] moveCameraToPath 오류: $e');
        }
      }
    } catch (e) {
      debugPrint('[RouteRenderingService] moveCameraToPath 전체 오류: $e');
    }
  }

  /// 카메라 이동 헬퍼 메서드
  Future<void> _moveCamera(NLatLng location, {double zoom = 15}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      
      final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
        target: location,
        zoom: zoom,
      );
      
      await _mapController!.updateCamera(cameraUpdate).timeout(
        const Duration(seconds: 5),
      );
      
    } catch (e) {
      debugPrint('[RouteRenderingService] 카메라 이동 오류: $e');
    }
  }

  /// 경로 제거
  Future<void> clearPath() async {
    if (_mapController == null) return;
    
    try {
      // 폴리라인 제거
      for (final overlayId in _pathOverlayIds) {
        try {
          await _mapController!.deleteOverlay(NOverlayInfo(
            type: NOverlayType.polylineOverlay,
            id: overlayId,
          ));
        } catch (e) {
          debugPrint('폴리라인 제거 오류 (무시): $overlayId - $e');
        }
      }
      _pathOverlayIds.clear();
      
      // 경로 마커 제거
      for (final markerId in _routeMarkerIds) {
        try {
          await _mapController!.deleteOverlay(NOverlayInfo(
            type: NOverlayType.marker,
            id: markerId,
          ));
        } catch (e) {
          debugPrint('경로 마커 제거 오류 (무시): $markerId - $e');
        }
      }
      _routeMarkerIds.clear();
      
    } catch (e) {
      debugPrint('경로 제거 중 오류: $e');
    }
  }

  /// 서비스 정리
  void dispose() {
    debugPrint('🧹 RouteRenderingService 정리');
    _pathOverlayIds.clear();
    _routeMarkerIds.clear();
    _mapController = null;
  }
}