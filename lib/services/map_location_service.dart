// lib/services/map/map_location_service.dart
// 지도상 내 위치 마커 및 표시 전용 서비스

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:location/location.dart' as loc;
import 'dart:async';

/// 지도상 위치 표시 서비스
class MapLocationService {
  NaverMapController? _mapController;
  
  // 내 위치 관련 오버레이
  NMarker? _myLocationMarker;
  NCircleOverlay? _myLocationCircle;
  
  // 카메라 이동 관련
  bool _isCameraMoving = false;
  Timer? _cameraDelayTimer;
  
  // 현재 표시된 위치
  NLatLng? _currentDisplayLocation;
  
  /// 지도 컨트롤러 설정
  void setMapController(NaverMapController controller) {
    _mapController = controller;
    debugPrint('✅ MapLocationService 지도 컨트롤러 설정 완료');
  }
  
  /// 지도 컨트롤러 반환
  NaverMapController? get mapController => _mapController;

  /// 내 위치 표시 (메인 메서드)
  Future<void> showMyLocation(
    loc.LocationData locationData, {
    bool shouldMoveCamera = true,
    double zoom = 16.0,
    bool showAccuracyCircle = true,
  }) async {
    if (_mapController == null) {
      debugPrint('❌ 지도 컨트롤러가 설정되지 않음');
      return;
    }
    
    if (locationData.latitude == null || locationData.longitude == null) {
      debugPrint('❌ 유효하지 않은 위치 데이터');
      return;
    }
    
    final location = NLatLng(locationData.latitude!, locationData.longitude!);
    
    try {
      debugPrint('📍 내 위치 표시: ${location.latitude}, ${location.longitude}');
      
      // 🔥 기존 오버레이 완전 제거 후 새로 생성
      await _removeMyLocationOverlays();
      
      // 🔥 약간의 지연으로 지도 상태 안정화
      await Future.delayed(const Duration(milliseconds: 50));
      
      // 2. 새로운 위치 마커 추가
      if (showAccuracyCircle) {
        await _addLocationCircle(location, locationData.accuracy);
      } else {
        await _addLocationMarker(location);
      }
      
      // 3. 위치 저장
      _currentDisplayLocation = location;
      
      // 4. 카메라 이동 (필요한 경우)
      if (shouldMoveCamera) {
        await _moveCameraToLocation(location, zoom);
      }
      
      debugPrint('✅ 내 위치 표시 완료');
      
    } catch (e) {
      debugPrint('❌ 내 위치 표시 실패: $e');
    }
  }

  /// 내 위치 업데이트 (기존 마커 이동)
  Future<void> updateMyLocation(
    loc.LocationData locationData, {
    bool shouldMoveCamera = false,
    double zoom = 16.0,
  }) async {
    if (_mapController == null) return;
    if (locationData.latitude == null || locationData.longitude == null) return;
    final location = NLatLng(locationData.latitude!, locationData.longitude!);
    try {
      debugPrint('🔄 내 위치 업데이트:  ${location.latitude}, ${location.longitude}');
      
      // 🔥 안전한 위치 업데이트
      if (_myLocationCircle != null) {
        try {
          _myLocationCircle!.setCenter(location);
          debugPrint('📍 원형 마커 위치 이동');
        } catch (e) {
          debugPrint('⚠️ 원형 마커 이동 실패, 새로 생성: $e');
          await showMyLocation(locationData, shouldMoveCamera: shouldMoveCamera);
          return;
        }
      } else if (_myLocationMarker != null) {
        try {
          _myLocationMarker!.setPosition(location);
          debugPrint('📍 마커 위치 이동');
        } catch (e) {
          debugPrint('⚠️ 마커 이동 실패, 새로 생성: $e');
          await showMyLocation(locationData, shouldMoveCamera: shouldMoveCamera);
          return;
        }
      } else {
        // 마커가 없으면 새로 생성
        debugPrint('🔄 기존 마커가 없음, 새로 생성');
        await showMyLocation(locationData, shouldMoveCamera: shouldMoveCamera);
        return;
      }
      
      _currentDisplayLocation = location;
      if (shouldMoveCamera) {
        await _moveCameraToLocation(location, zoom);
      }
    } catch (e) {
      debugPrint('❌ 내 위치 업데이트 실패: $e');
      // 오류 발생 시 완전히 새로 생성
      await showMyLocation(locationData, shouldMoveCamera: shouldMoveCamera);
    }
  }

  /// 원형 위치 마커 추가 (정확도 표시)
  Future<void> _addLocationCircle(NLatLng location, double? accuracy) async {
    try {
      final circleRadius = 10.0;  // 20.0에서 10.0으로 절반 크기로 줄임
      
      // 🔥 고정 ID 사용으로 중복 방지
      const circleId = 'my_location_circle';
      _myLocationCircle = NCircleOverlay(
        id: circleId,
        center: location,
        radius: circleRadius,
        color: const Color(0xFF1E3A8A).withOpacity(0.3), // 파란색 투명
        outlineColor: const Color(0xFF1E3A8A),
        outlineWidth: 2,
      );
      
      await _mapController!.addOverlay(_myLocationCircle!);
      
      debugPrint('✅ 위치 원형 마커 추가 (반지름: ${circleRadius}m)');
      
    } catch (e) {
      debugPrint('❌ 위치 원형 마커 추가 실패: $e');
    }
  }

  /// 내 위치 마커 추가
  Future<void> _addLocationMarker(NLatLng location) async {
    try {
      _myLocationMarker = NMarker(
        id: 'my_location_marker_${DateTime.now().millisecondsSinceEpoch}',
        position: location,
        icon: NOverlayImage.fromAssetImage('assets/images/my_location_marker.png'),
        caption: NOverlayCaption(
          text: '내 위치',
          color: const Color(0xFF1E3A8A),
          textSize: 12,
          haloColor: Colors.white,
        ),
        size: const Size(32, 32),
      );
      await _mapController!.addOverlay(_myLocationMarker!);
      debugPrint('✅ 내 위치 마커 추가 완료');
    } catch (e) {
      debugPrint('❌ 내 위치 마커 추가 실패: $e');
    }
  }

  /// 안전한 카메라 이동
  Future<void> _moveCameraToLocation(NLatLng location, double zoom) async {
    // 카메라 이동 중복 방지
    if (_isCameraMoving) {
      debugPrint('⏳ 카메라 이동 중, 요청 무시');
      return;
    }
    
    _isCameraMoving = true;
    
    try {
      debugPrint('🎥 카메라 이동: ${location.latitude}, ${location.longitude}, zoom: $zoom');
      
      // 메인 스레드 보호를 위한 지연
      await Future.delayed(const Duration(milliseconds: 200));
      
      final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
        target: location,
        zoom: zoom,
      );
      
      await _mapController!.updateCamera(cameraUpdate).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏰ 카메라 이동 타임아웃');
          throw TimeoutException('카메라 이동 타임아웃', const Duration(seconds: 5));
        },
      );
      
      debugPrint('✅ 카메라 이동 완료');
      
    } catch (e) {
      debugPrint('❌ 카메라 이동 실패: $e');
      
      // 재시도 (한 번만)
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        final retryUpdate = NCameraUpdate.scrollAndZoomTo(
          target: location,
          zoom: zoom,
        );
        await _mapController!.updateCamera(retryUpdate).timeout(
          const Duration(seconds: 3),
        );
        debugPrint('✅ 카메라 이동 재시도 성공');
      } catch (retryError) {
        debugPrint('❌ 카메라 이동 재시도 실패: $retryError');
      }
    } finally {
      _isCameraMoving = false;
    }
  }

  /// 지연된 카메라 이동 (메인 스레드 블로킹 방지)
  void scheduleCameraMove(NLatLng location, double zoom, {Duration delay = const Duration(milliseconds: 500)}) {
    _cameraDelayTimer?.cancel();
    _cameraDelayTimer = Timer(delay, () async {
      try {
        await _moveCameraToLocation(location, zoom);
      } catch (e) {
        debugPrint('❌ 지연된 카메라 이동 실패: $e');
      }
    });
  }

  /// 내 위치 오버레이 제거
  Future<void> _removeMyLocationOverlays() async {
    try {
      // 🔥 강제로 null로 설정하여 중복 방지
      NCircleOverlay? circleToRemove = _myLocationCircle;
      NMarker? markerToRemove = _myLocationMarker;
      
      // 먼저 참조를 null로 설정
      _myLocationCircle = null;
      _myLocationMarker = null;
      
      // 그 다음 오버레이 제거
      if (circleToRemove != null) {
        try {
          await _mapController!.deleteOverlay(circleToRemove.info);
          debugPrint('🗑️ 기존 위치 원형 마커 제거');
        } catch (e) {
          debugPrint('⚠️ 원형 마커 제거 실패 (이미 제거됨): $e');
        }
      }
      
      if (markerToRemove != null) {
        try {
          await _mapController!.deleteOverlay(markerToRemove.info);
          debugPrint('🗑️ 기존 위치 마커 제거');
        } catch (e) {
          debugPrint('⚠️ 마커 제거 실패 (이미 제거됨): $e');
        }
      }
      
    } catch (e) {
      debugPrint('❌ 내 위치 오버레이 제거 중 오류: $e');
      // 오류가 발생해도 참조는 null로 유지
      _myLocationCircle = null;
      _myLocationMarker = null;
    }
  }

  /// 내 위치 숨기기
  Future<void> hideMyLocation() async {
    debugPrint('👻 내 위치 숨기기');
    await _removeMyLocationOverlays();
    _currentDisplayLocation = null;
  }

  /// 지도 영역을 특정 좌표들에 맞춰 조정
  Future<void> fitMapToBounds(List<NLatLng> coordinates, {EdgeInsets padding = const EdgeInsets.all(50)}) async {
    if (_mapController == null || coordinates.isEmpty) return;
    
    try {
      if (coordinates.length == 1) {
        // 단일 좌표면 해당 위치로 이동
        await _moveCameraToLocation(coordinates.first, 16.0);
        return;
      }
      
      // 여러 좌표의 경계 계산
      double minLat = coordinates.first.latitude;
      double maxLat = coordinates.first.latitude;
      double minLng = coordinates.first.longitude;
      double maxLng = coordinates.first.longitude;
      
      for (final coord in coordinates) {
        if (coord.latitude < minLat) minLat = coord.latitude;
        if (coord.latitude > maxLat) maxLat = coord.latitude;
        if (coord.longitude < minLng) minLng = coord.longitude;
        if (coord.longitude > maxLng) maxLng = coord.longitude;
      }
      
      // 여백 추가
      const margin = 0.001;
      minLat -= margin;
      maxLat += margin;
      minLng -= margin;
      maxLng += margin;
      
      final bounds = NLatLngBounds(
        southWest: NLatLng(minLat, minLng),
        northEast: NLatLng(maxLat, maxLng),
      );
      
      await _mapController!.updateCamera(
        NCameraUpdate.fitBounds(bounds, padding: padding),
      );
      
      debugPrint('✅ 지도 영역 조정 완료');
      
    } catch (e) {
      debugPrint('❌ 지도 영역 조정 실패: $e');
    }
  }

  /// 현재 표시된 위치
  NLatLng? get currentDisplayLocation => _currentDisplayLocation;
  
  /// 내 위치가 표시되어 있는지 확인
  bool get hasMyLocationShown => _myLocationMarker != null || _myLocationCircle != null;
  
  /// 현재 카메라 이동 중인지
  bool get isCameraMoving => _isCameraMoving;

  /// 위치 마커 스타일 변경
  Future<void> updateLocationMarkerStyle({
    Color? circleColor,
    Color? outlineColor,
    String? markerText,
    Color? textColor,
  }) async {
    try {
      if (_myLocationCircle != null) {
        // 원형 마커 스타일 변경은 제한적 (새로 생성해야 함)
        debugPrint('ℹ️ 원형 마커 스타일 변경은 재생성이 필요합니다');
      }
      
      if (_myLocationMarker != null && markerText != null) {
        _myLocationMarker!.setCaption(NOverlayCaption(
          text: markerText,
          color: textColor ?? Colors.white,
          haloColor: outlineColor ?? const Color(0xFF1E3A8A),
          textSize: 12,
        ));
        debugPrint('✅ 위치 마커 텍스트 업데이트');
      }
      
    } catch (e) {
      debugPrint('❌ 위치 마커 스타일 변경 실패: $e');
    }
  }

  /// 서비스 정리
  void dispose() {
    debugPrint('🧹 MapLocationService 정리');
    
    // 타이머 취소
    _cameraDelayTimer?.cancel();
    _cameraDelayTimer = null;
    
    // 상태 초기화
    _isCameraMoving = false;
    _currentDisplayLocation = null;
    _myLocationMarker = null;
    _myLocationCircle = null;
    _mapController = null;
  }
}