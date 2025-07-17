// LocationController 완전한 구현 - 실제 코드 기반

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/map_location_service.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:location/location.dart' as loc;
import '../services/location_service.dart';
import '../services/location_permission_manager.dart';

/// 위치 관련 UI 상태 관리 컨트롤러
class LocationController extends ChangeNotifier {
  final LocationService _locationService;
  final LocationPermissionManager _permissionManager;
  final MapLocationService _mapLocationService;
  
  // 🔥 Location 인스턴스 직접 생성
  final loc.Location _location = loc.Location();
  
  // 현재 상태
  bool _isRequesting = false;
  bool _hasValidLocation = false;
  bool _hasLocationPermissionError = false;
  loc.LocationData? _currentLocation;
  
  // 지도 관련
  NaverMapController? _mapController;
  NMarker? _myLocationMarker; // 🔥 변수명 변경
  NCircleOverlay? _myLocationCircle; // 🔥 원형 오버레이 추가
  
  // 🔥 모든 위치 관련 오버레이 ID 추적
  final Set<String> _locationOverlayIds = {};
  
  LocationController({
    LocationService? locationService,
    LocationPermissionManager? permissionManager,
    MapLocationService? mapLocationService,
  }) : _locationService = locationService ?? LocationService(),
       _permissionManager = permissionManager ?? LocationPermissionManager(),
       _mapLocationService = mapLocationService ?? MapLocationService() {
    _initialize();
  }

  // Getters
  bool get isRequesting => _isRequesting;
  bool get hasValidLocation => _hasValidLocation;
  bool get hasLocationPermissionError => _hasLocationPermissionError;
  loc.LocationData? get currentLocation => _currentLocation;
  loc.Location get location => _location; // 🔥 직접 생성된 Location 인스턴스 반환

  /// 초기화
  Future<void> _initialize() async {
    try {
      await _locationService.initialize();
      _permissionManager.addPermissionListener(_onPermissionChanged);
    } catch (e) {
      debugPrint('LocationController 초기화 실패: $e');
    }
  }

  /// 권한 상태 변경 콜백
  void _onPermissionChanged(PermissionResult result) {
    debugPrint('권한 상태 변경: $result');
    
    switch (result) {
      case PermissionResult.granted:
        _hasLocationPermissionError = false;
        break;
      case PermissionResult.denied:
      case PermissionResult.deniedForever:
      case PermissionResult.serviceDisabled:
        _hasLocationPermissionError = true;
        break;
      default:
        break;
    }
    notifyListeners();
  }

  /// 현재 위치 요청 (메인 API)
  Future<void> requestCurrentLocation({bool forceRefresh = false}) async {
    if (_isRequesting) return;
    
    try {
      _isRequesting = true;
      _hasLocationPermissionError = false;
      notifyListeners();
      
      // 1. 권한 확인
      final permissionResult = await _permissionManager.checkPermissionStatus(
        forceRefresh: forceRefresh
      );
      
      if (permissionResult != PermissionResult.granted) {
        // 권한 요청
        final requestResult = await _permissionManager.requestPermission();
        if (requestResult != PermissionResult.granted) {
          _hasLocationPermissionError = true;
          return;
        }
      }
      
      // 2. 위치 획득
      final locationResult = await _locationService.getCurrentLocation(
        forceRefresh: forceRefresh
      );
      
      if (locationResult.isSuccess && locationResult.hasValidLocation) {
        _currentLocation = locationResult.locationData;
        _hasValidLocation = true;
        
        // 3. 지도에 위치 표시
        await _mapLocationService.showMyLocation(
          locationResult.locationData!,
          shouldMoveCamera: true
        );
        
      } else {
        // fallback 위치 사용
        final fallbackResult = _locationService.getFallbackLocation();
        if (fallbackResult.isSuccess) {
          _currentLocation = fallbackResult.locationData;
          _hasValidLocation = true;
          
          await _mapLocationService.showMyLocation(
            fallbackResult.locationData!,
            shouldMoveCamera: true
          );
        }
      }
      
    } catch (e) {
      debugPrint('위치 요청 실패: $e');
      _hasLocationPermissionError = true;
    } finally {
      _isRequesting = false;
      notifyListeners();
    }
  }

  /// 내 위치로 이동
  Future<void> moveToMyLocation() async {
    if (_currentLocation != null) {
      await _mapLocationService.showMyLocation(
        _currentLocation!,
        shouldMoveCamera: true
      );
    } else {
      await requestCurrentLocation();
    }
  }

  /// 위치 권한 재요청
  Future<void> retryLocationPermission() async {
    _permissionManager.invalidateCache();
    await requestCurrentLocation(forceRefresh: true);
  }

  /// 🔥 지도 컨트롤러 설정
  void setMapController(NaverMapController mapController) {
    _mapController = mapController;
    _mapLocationService.setMapController(mapController);
    debugPrint('✅ LocationController에 지도 컨트롤러 설정 완료');
  }

  /// 🔥 사용자 위치 마커 업데이트 - 가장 간단하고 확실한 방법
  void updateUserLocationMarker(NLatLng position) async {
    if (_mapController == null) {
      debugPrint('⚠️ MapController가 null입니다');
      return;
    }

    try {
      debugPrint('📍 위치 마커 업데이트 시작: ${position.latitude}, ${position.longitude}');
      
      // 🔥 방법 1: MapLocationService 사용 (가장 안전)
      final locationData = loc.LocationData.fromMap({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': _currentLocation?.accuracy ?? 10.0,
      });
      
      await _mapLocationService.updateMyLocation(
        locationData,
        shouldMoveCamera: false, // 카메라는 이동하지 않음
      );
      
      debugPrint('✅ MapLocationService를 통한 위치 마커 업데이트 완료');
      
    } catch (e) {
      debugPrint('❌ MapLocationService 실패, 직접 방식 시도: $e');
      
      try {
        // 🔥 방법 2: 직접 제거 후 추가
        await _forceRemoveAndRecreate(position);
        debugPrint('✅ 직접 방식 위치 마커 업데이트 완료');
        
      } catch (e2) {
        debugPrint('❌ 직접 방식도 실패: $e2');
        
        // 🔥 방법 3: 그냥 새로 추가 (중복 허용)
        try {
          final accuracy = _currentLocation?.accuracy ?? 10.0;
          await _addLocationCircle(position, accuracy);
          debugPrint('✅ 새 마커 추가 완료 (중복 가능)');
        } catch (e3) {
          debugPrint('❌ 모든 방법 실패: $e3');
        }
      }
    }
  }

  /// 🔥 강제 제거 후 재생성
  Future<void> _forceRemoveAndRecreate(NLatLng position) async {
    // 1. 기존 참조로 제거 시도
    if (_myLocationMarker != null) {
      try {
        await _mapController!.deleteOverlay(_myLocationMarker!.info);
        debugPrint('🗑️ 기존 마커 제거됨');
      } catch (e) {
        debugPrint('⚠️ 기존 마커 제거 실패: $e');
      }
      _myLocationMarker = null;
    }
    
    if (_myLocationCircle != null) {
      try {
        await _mapController!.deleteOverlay(_myLocationCircle!.info);
        debugPrint('🗑️ 기존 원형 제거됨');
      } catch (e) {
        debugPrint('⚠️ 기존 원형 제거 실패: $e');
      }
      _myLocationCircle = null;
    }
    
    // 2. ID 기반 제거 시도
    for (final overlayId in _locationOverlayIds.toList()) {
      try {
        final markerInfo = NOverlayInfo(type: NOverlayType.marker, id: overlayId);
        await _mapController!.deleteOverlay(markerInfo);
        debugPrint('🗑️ ID 마커 제거: $overlayId');
      } catch (e1) {
        try {
          final circleInfo = NOverlayInfo(type: NOverlayType.circleOverlay, id: overlayId);
          await _mapController!.deleteOverlay(circleInfo);
          debugPrint('🗑️ ID 원형 제거: $overlayId');
        } catch (e2) {
          debugPrint('⚠️ ID 제거 실패: $overlayId');
        }
      }
    }
    _locationOverlayIds.clear();
    
    // 3. 잠시 대기
    await Future.delayed(const Duration(milliseconds: 200));
    
    // 4. 새 마커 생성
    final accuracy = _currentLocation?.accuracy ?? 10.0;
    await _addLocationCircle(position, accuracy);
  }

  /// 🔥 모든 위치 관련 오버레이 강력 제거 - 타입별 정확한 제거
  Future<void> _removeAllLocationOverlays() async {
    if (_mapController == null) return;
    
    try {
      debugPrint('🗑️ 모든 위치 오버레이 제거 시작...');
      
      // 1. 마커 제거 (NMarker)
      if (_myLocationMarker != null) {
        try {
          await _mapController!.deleteOverlay(_myLocationMarker!.info);
          debugPrint('🗑️ 마커 객체 제거됨: ${_myLocationMarker!.info.id}');
        } catch (e) {
          debugPrint('⚠️ 마커 객체 제거 실패: $e');
        }
        _myLocationMarker = null;
      }
      
      // 2. 원형 오버레이 제거 (NCircleOverlay)
      if (_myLocationCircle != null) {
        try {
          await _mapController!.deleteOverlay(_myLocationCircle!.info);
          debugPrint('🗑️ 원형 객체 제거됨: ${_myLocationCircle!.info.id}');
        } catch (e) {
          debugPrint('⚠️ 원형 객체 제거 실패: $e');
        }
        _myLocationCircle = null;
      }
      
      // 3. ID로 추적된 모든 오버레이 제거 시도 (백업)
      for (final overlayId in _locationOverlayIds.toList()) {
        try {
          // 마커 타입으로 시도
          final markerInfo = NOverlayInfo(type: NOverlayType.marker, id: overlayId);
          await _mapController!.deleteOverlay(markerInfo);
          debugPrint('🗑️ 마커 ID 제거됨: $overlayId');
        } catch (e1) {
          try {
            // 원형 타입으로 시도
            final circleInfo = NOverlayInfo(type: NOverlayType.circleOverlay, id: overlayId);
            await _mapController!.deleteOverlay(circleInfo);
            debugPrint('🗑️ 원형 ID 제거됨: $overlayId');
          } catch (e2) {
            debugPrint('⚠️ 오버레이 제거 실패: $overlayId - $e2');
          }
        }
      }
      _locationOverlayIds.clear();
      
      // 4. 잠시 대기 (네이버맵 처리 시간)
      await Future.delayed(const Duration(milliseconds: 150));
      
      debugPrint('✅ 모든 위치 오버레이 제거 완료');
      
    } catch (e) {
      debugPrint('❌ 위치 오버레이 제거 중 오류: $e');
    }
  }

  /// 원형 위치 마커 추가 (정확도 표시) - ID 추적 (fallback용) - 작은 크기
  Future<void> _addLocationCircle(NLatLng location, double? accuracy) async {
    try {
      // 🔥 원 크기 줄이기: 기존 5.0~100.0 → 3.0~15.0
      final circleRadius = accuracy != null && accuracy > 0 
          ? accuracy.clamp(3.0, 10.0)  // 최대 15미터로 제한
          : 5.0;  // 기본값도 8미터로 축소
      
      final circleId = 'my_location_circle_${DateTime.now().millisecondsSinceEpoch}';
      _myLocationCircle = NCircleOverlay(
        id: circleId,
        center: location,
        radius: circleRadius,
        color: const Color(0xFF1E3A8A).withOpacity(0.2), // 🔥 투명도도 줄임 (0.3 → 0.2)
        outlineColor: const Color(0xFF1E3A8A),
        outlineWidth: 1.5, // 🔥 테두리도 얇게 (2 → 1.5)
      );
      
      await _mapController!.addOverlay(_myLocationCircle!);
      _locationOverlayIds.add(circleId); // 🔥 ID 추적
      
      debugPrint('✅ 작은 위치 원형 마커 추가 (반지름: ${circleRadius}m, ID: $circleId)');
      
    } catch (e) {
      debugPrint('❌ 위치 원형 마커 추가 실패: $e');
    }
  }

  @override
  void dispose() {
    // 🔥 dispose 시에도 위치 오버레이 정리
    try {
      _forceRemoveAndRecreate(NLatLng(0, 0)); // 더미 위치로 제거만 수행
    } catch (e) {
      debugPrint('❌ dispose 중 오버레이 제거 실패: $e');
    }
    
    _permissionManager.removePermissionListener(_onPermissionChanged);
    _permissionManager.dispose();
    _locationService.dispose();
    _mapLocationService.dispose();
    super.dispose();
  }
}