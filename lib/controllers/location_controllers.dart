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

  /// 🔥 사용자 위치 마커 업데이트 - 기존 스타일 적용
  void updateUserLocationMarker(NLatLng position) {
    if (_mapController == null) {
      debugPrint('⚠️ MapController가 null입니다');
      return;
    }

    try {
      // 정확도 정보 (기본값 사용)
      final accuracy = _currentLocation?.accuracy;
      
      // 원형 마커와 일반 마커 모두 추가
      _addLocationCircle(position, accuracy);
      _addLocationMarker(position);
      
      debugPrint('✅ 사용자 위치 마커 업데이트 완료: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('❌ 사용자 위치 마커 업데이트 실패: $e');
    }
  }

  /// 원형 위치 마커 추가 (정확도 표시)
  Future<void> _addLocationCircle(NLatLng location, double? accuracy) async {
    try {
      // 기존 원형 마커 제거
      if (_myLocationCircle != null) {
        _mapController!.deleteOverlay(_myLocationCircle!.info);
        _myLocationCircle = null;
      }
      
      final circleRadius = accuracy != null && accuracy > 0 ? accuracy.clamp(5.0, 100.0) : 10.0;
      
      final circleId = 'my_location_circle_${DateTime.now().millisecondsSinceEpoch}';
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

  /// 일반 위치 마커 추가
  Future<void> _addLocationMarker(NLatLng location) async {
    try {
      // 기존 마커 제거
      if (_myLocationMarker != null) {
        _mapController!.deleteOverlay(_myLocationMarker!.info);
        _myLocationMarker = null;
      }
      
      final markerId = 'my_location_marker_${DateTime.now().millisecondsSinceEpoch}';
      _myLocationMarker = NMarker(
        id: markerId,
        position: location,
        caption: NOverlayCaption(
          text: '내 위치',
          color: Colors.white,
          haloColor: const Color(0xFF1E3A8A),
          textSize: 12,
        ),
        // 기본 마커 사용 (커스텀 아이콘 원하면 수정 가능)
      );
      
      await _mapController!.addOverlay(_myLocationMarker!);
      
      debugPrint('✅ 위치 마커 추가');
      
    } catch (e) {
      debugPrint('❌ 위치 마커 추가 실패: $e');
    }
  }

  @override
  void dispose() {
    _permissionManager.removePermissionListener(_onPermissionChanged);
    _permissionManager.dispose();
    _locationService.dispose();
    _mapLocationService.dispose();
    super.dispose();
  }
}