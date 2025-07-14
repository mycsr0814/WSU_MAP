// lib/controllers/location_controller.dart (새로 생성)
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
  
  // 현재 상태
  bool _isRequesting = false;
  bool _hasValidLocation = false;
  bool _hasLocationPermissionError = false;
  loc.LocationData? _currentLocation;
  
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

  /// 지도 컨트롤러 설정
  void setMapController(NaverMapController controller) {
    _mapLocationService.setMapController(controller);
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