// lib/controllers/map_controller.dart - MapScreenController 클래스 정의

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter_application_1/services/map_service.dart';
import 'package:flutter_application_1/services/route_service.dart';
import 'package:flutter_application_1/services/path_api_service.dart';
import 'package:flutter_application_1/managers/location_manager.dart';
import 'package:flutter_application_1/models/building.dart';
import 'dart:math' as math;

class MapScreenController extends ChangeNotifier {
  MapService? _mapService;
  RouteService? _routeService;
  LocationManager? _locationManager;
  
  // 선택된 건물
  Building? _selectedBuilding;
  
  // 경로 관련
  Building? _startBuilding;
  Building? _endBuilding;
  bool _isLoading = false;
  
  // 위치 권한 오류
  bool _hasLocationPermissionError = false;
  
  // 언어 변경 감지
  Locale? _currentLocale;

  // 경로 정보 추가
  String? _routeDistance;
  String? _routeTime;
  
  // 현재 위치에서 길찾기 관련 속성 추가
  Building? _targetBuilding; // 현재 위치에서 길찾기 시 목표 건물
  bool _isNavigatingFromCurrentLocation = false;

  // 오버레이 관리를 위한 변수들 추가
  final List<NOverlay> _routeOverlays = [];

  // Getters
  Building? get selectedBuilding => _selectedBuilding;
  Building? get startBuilding => _startBuilding;
  Building? get endBuilding => _endBuilding;
  bool get isLoading => _isLoading;
  bool get hasLocationPermissionError => _hasLocationPermissionError;
  bool get buildingMarkersVisible => _mapService?.buildingMarkersVisible ?? true;
  String? get routeDistance => _routeDistance;
  String? get routeTime => _routeTime;
  
  // 추가된 Getters
  Building? get targetBuilding => _targetBuilding;
  bool get isNavigatingFromCurrentLocation => _isNavigatingFromCurrentLocation;
  bool get hasActiveRoute => 
      (_startBuilding != null && _endBuilding != null) || 
      _isNavigatingFromCurrentLocation;

  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      debugPrint('🚀 MapController 초기화 시작...');
      _mapService = MapService();
      _routeService = RouteService();
      
      // 병렬로 초기화 작업 수행
      final futures = [
        // 서버 연결 테스트 (백그라운드)
        _testServerConnection(),
        
        // 마커 아이콘 로딩 (필수)
        _mapService!.loadMarkerIcons(),
      ];
      
      await Future.wait(futures, eagerError: false);
      
      debugPrint('✅ MapController 초기화 완료');
    } catch (e) {
      debugPrint('❌ MapController 초기화 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  

  /// 서버 연결 테스트 (백그라운드)
  Future<void> _testServerConnection() async {
    try {
      final isServerConnected = await PathApiService.testConnection();
      if (isServerConnected) {
        debugPrint('🌐 서버 연결 확인 완료');
      } else {
        debugPrint('⚠️ 서버 연결 실패 (정상 동작 가능)');
      }
    } catch (e) {
      debugPrint('⚠️ 서버 연결 테스트 오류: $e');
    }
  }

  /// Context 설정 (언어 변경 감지용)
  void setContext(BuildContext context) {
    _mapService?.setContext(context);
    
    // 언어 변경 감지
    final currentLocale = Localizations.localeOf(context);
    if (_currentLocale != null && _currentLocale != currentLocale) {
      debugPrint('언어 변경 감지: ${_currentLocale?.languageCode} -> ${currentLocale.languageCode}');
      _onLocaleChanged(currentLocale);
    }
    _currentLocale = currentLocale;
  }

  /// 언어 변경 감지 및 마커 재생성
  void _onLocaleChanged(Locale newLocale) {
    debugPrint('언어 변경으로 인한 마커 재생성 시작');
    
    // 마커 재생성을 위해 다음 프레임에서 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshBuildingMarkers();
    });
  }

  /// 건물 마커 재생성
  Future<void> _refreshBuildingMarkers() async {
    if (_mapService == null) return;
    
    try {
      debugPrint('언어 변경으로 인한 마커 재생성 시작');
      
      // 새로운 언어로 마커 재생성
      await _mapService!.addBuildingMarkers(_onBuildingMarkerTap);
      
      debugPrint('언어 변경으로 인한 마커 재생성 완료');
    } catch (e) {
      debugPrint('마커 재생성 오류: $e');
    }
  }

  void setLocationManager(LocationManager locationManager) {
    _locationManager = locationManager;
    
    // 위치 업데이트 리스너 등록
    _locationManager!.addListener(_onLocationUpdate);
    debugPrint('✅ LocationManager 설정 완료');
  }

  void _onLocationUpdate() {
    if (_locationManager?.hasValidLocation == true && _mapService != null) {
      final location = _locationManager!.currentLocation!;
      final nLocation = NLatLng(location.latitude!, location.longitude!);
      
      // 내 위치 마커 업데이트
      _mapService!.updateMyLocation(nLocation);
    }
    
    // 위치 권한 오류 상태 업데이트
    final hasError = _locationManager?.hasLocationPermissionError ?? false;
    if (_hasLocationPermissionError != hasError) {
      _hasLocationPermissionError = hasError;
      notifyListeners();
    }
  }

  Future<void> onMapReady(NaverMapController mapController) async {
    try {
      debugPrint('🗺️ 지도 준비 완료, 서비스 설정 시작');
      
      _mapService?.setController(mapController);
      
      // 건물 마커 추가 (백그라운드에서 진행)
      _addBuildingMarkersInBackground();
      
      debugPrint('✅ 지도 서비스 설정 완료');
    } catch (e) {
      debugPrint('❌ 지도 준비 오류: $e');
    }
  }

  /// 건물 마커를 백그라운드에서 추가
  void _addBuildingMarkersInBackground() {
    Future.microtask(() async {
      try {
        debugPrint('🏢 건물 마커 추가 시작...');
        await _mapService!.addBuildingMarkers(_onBuildingMarkerTap);
        debugPrint('✅ 건물 마커 추가 완료');
      } catch (e) {
        debugPrint('❌ 건물 마커 추가 오류: $e');
      }
    });
  }

  void _onBuildingMarkerTap(NMarker marker, Building building) {
    debugPrint('건물 마커 탭: ${building.name}');
    _selectedBuilding = building;
    notifyListeners();
  }

  void selectBuilding(Building building) {
    _selectedBuilding = building;
    notifyListeners();
  }

  // 선택된 건물 초기화 메서드 추가
  void clearSelectedBuilding() {
    if (_selectedBuilding != null) {
      _selectedBuilding = null;
      notifyListeners();
      debugPrint('🧹 선택된 건물 초기화 완료');
    }
  }

  void closeInfoWindow(OverlayPortalController controller) {
    if (controller.isShowing) {
      controller.hide();
    }
    clearSelectedBuilding(); // 선택된 건물도 함께 초기화
    debugPrint('🚪 InfoWindow 닫기 완료');
  }

  /// 모든 오버레이를 안전하게 제거하는 메서드
  Future<void> _clearAllOverlays() async {
    try {
      final controller = await _mapService?.getController();
      if (controller == null) return;
      
      // 기존 경로 오버레이들 제거
      if (_routeOverlays.isNotEmpty) {
        for (final overlay in List.from(_routeOverlays)) {
          try {
            controller.deleteOverlay(overlay.info);
            // 각 오버레이 제거 후 잠시 대기
            await Future.delayed(const Duration(milliseconds: 50));
          } catch (e) {
            debugPrint('개별 오버레이 제거 오류: $e');
          }
        }
        _routeOverlays.clear();
      }
      
      debugPrint('모든 오버레이 제거 완료');
    } catch (e) {
      debugPrint('오버레이 제거 중 오류: $e');
    }
  }
  
 /// 안전한 경로 그리기 메서드 - 수정됨
Future<void> _drawPathSafely(List<NLatLng> pathCoordinates) async {
  try {
    if (pathCoordinates.isEmpty) return;
    
    final controller = await _mapService?.getController();
    if (controller == null) return;
    
    // NPolylineOverlay 사용 (PathOverlay보다 안전함)
    final polyline = NPolylineOverlay(
      id: 'route_${DateTime.now().millisecondsSinceEpoch}',
      coords: pathCoordinates,
      color: const Color(0xFF1E3A8A),
      width: 5,
    );
    
    controller.addOverlay(polyline);
    _routeOverlays.add(polyline);
    
    // 시작점과 끝점 마커 추가 (기본 마커 사용)
    await _addRouteMarkersSimple(controller, pathCoordinates.first, pathCoordinates.last);
    
    debugPrint('경로 그리기 완료');
  } catch (e) {
    debugPrint('경로 그리기 오류: $e');
  }
}

/// 경로 시작점과 끝점 마커 추가 (기본 마커 사용)
Future<void> _addRouteMarkersSimple(NaverMapController controller, NLatLng start, NLatLng end) async {
  try {
    // 시작점 마커 (기본 아이콘 사용)
    final startMarker = NMarker(
      id: 'route_start_${DateTime.now().millisecondsSinceEpoch}',
      position: start,
      // 기본 마커 사용 (녹색으로 구분하기 위해 caption 추가)
      caption: NOverlayCaption(text: '출발', color: Colors.green),
    );
    
    // 끝점 마커 (기본 아이콘 사용)
    final endMarker = NMarker(
      id: 'route_end_${DateTime.now().millisecondsSinceEpoch}',
      position: end,
      // 기본 마커 사용 (빨간색으로 구분하기 위해 caption 추가)
      caption: NOverlayCaption(text: '도착', color: Colors.red),
    );
    
    controller.addOverlay(startMarker);
    controller.addOverlay(endMarker);
    
    _routeOverlays.add(startMarker);
    _routeOverlays.add(endMarker);
    
  } catch (e) {
    debugPrint('경로 마커 추가 오류: $e');
  }
}

  // 경로 좌표 리스트를 받아 실제 경로 거리 계산
  double _calculatePathDistance(List<NLatLng> pathCoordinates) {
    if (pathCoordinates.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    
    for (int i = 0; i < pathCoordinates.length - 1; i++) {
      final current = pathCoordinates[i];
      final next = pathCoordinates[i + 1];
      
      totalDistance += _calculateDistance(
        current.latitude, 
        current.longitude,
        next.latitude, 
        next.longitude
      );
    }
    
    return totalDistance;
  }

  // 두 지점 간의 직선 거리 계산 (미터 단위)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // 지구 반지름 (미터)
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

/// 내 위치로 이동 - 대폭 간소화
Future<void> moveToMyLocation() async {
  try {
    if (_locationManager == null) {
      debugPrint('❌ LocationManager 없음');
      return;
    }

    debugPrint('📍 내 위치로 이동 시작...');
    
    // 로딩 상태 표시
    _setLoading(true);
    _hasLocationPermissionError = false;
    notifyListeners();

    // 1. 캐시된 위치가 있으면 바로 이동
    if (_locationManager!.hasValidLocation) {
      debugPrint('⚡ 캐시된 위치로 즉시 이동');
      await _moveToLocationAndShow(_locationManager!.currentLocation!);
      return;
    }

    // 2. 위치 요청 (백그라운드에서 계속 처리)
    debugPrint('🔄 새로운 위치 요청...');
    
    // 위치 획득 시 자동 이동하도록 콜백 설정
    _locationManager!.onLocationFound = (locationData) async {
      debugPrint('📍 위치 획득됨, 자동 이동 시작');
      await _moveToLocationAndShow(locationData);
    };
    
    // 위치 요청 시작
    await _locationManager!.requestLocation();
    
    // 위치 요청 후 상태 확인
    if (_locationManager!.hasValidLocation) {
      // 이미 위치가 있으면 이동
      await _moveToLocationAndShow(_locationManager!.currentLocation!);
    } else if (_locationManager!.hasLocationPermissionError) {
      // 권한 오류 처리
      debugPrint('❌ 위치 권한 오류');
      _hasLocationPermissionError = true;
    } else {
      // 여전히 위치 요청 중
      debugPrint('⏳ 위치 요청 진행 중...');
    }
    
  } catch (e) {
    debugPrint('❌ 내 위치 이동 오류: $e');
    _hasLocationPermissionError = true;
  } finally {
    _setLoading(false);
    notifyListeners();
  }
}

  /// 실시간 위치 추적 시작
  void _startLocationTracking() {
    _locationManager?.startLocationTracking(
      onLocationChanged: (locationData) async {
        if (locationData.latitude != null && locationData.longitude != null) {
          final latLng = NLatLng(locationData.latitude!, locationData.longitude!);
          
          // 내 위치 마커만 업데이트 (카메라는 이동하지 않음)
          await _mapService?.updateMyLocation(latLng);
        }
      },
    );
  }

  /// 위치 권한 재요청 (UI에서 버튼 클릭 시)
Future<void> retryLocationPermission() async {
  debugPrint('🔄 위치 권한 재요청...');
  
  _hasLocationPermissionError = false;
  notifyListeners();
  
  // 위치 새로고침 및 이동
  await _locationManager?.refreshLocation();
  
  // 위치 획득 성공 시 자동 이동
  if (_locationManager?.hasValidLocation == true) {
    await _moveToLocationAndShow(_locationManager!.currentLocation!);
  }
}

  /// 위치로 이동하고 표시하는 공통 메서드
Future<void> _moveToLocationAndShow(loc.LocationData locationData) async {
  try {
    final latLng = NLatLng(locationData.latitude!, locationData.longitude!);
    
    debugPrint('🎯 위치로 이동: ${latLng.latitude}, ${latLng.longitude}');
    
    // 순차적으로 실행하여 확실히 처리
    await _mapService?.moveCamera(latLng, zoom: 17);
    await Future.delayed(const Duration(milliseconds: 200)); // 잠깐 대기
    await _mapService?.showMyLocation(latLng);
    
    // 실시간 추적 시작
    _startLocationTracking();
    
    debugPrint('✅ 내 위치 이동 완료');
    
  } catch (e) {
    debugPrint('❌ 위치 이동 실패: $e');
  }
}

  // 현재 위치에서 건물까지 길찾기 - 실제 경로 거리 계산 적용
  Future<void> navigateFromCurrentLocation(Building targetBuilding) async {
    try {
      debugPrint('🧭 현재 위치에서 ${targetBuilding.name}까지 길찾기 시작');
      
      // 상태 설정
      _targetBuilding = targetBuilding;
      _isNavigatingFromCurrentLocation = true;
      _startBuilding = null; // 기존 출발지 초기화
      _endBuilding = null;   // 기존 도착지 초기화
      notifyListeners();
      
      if (_locationManager == null) {
        debugPrint('❌ LocationManager가 설정되지 않음');
        return;
      }

      _setLoading(true);

      // 현재 위치 확인 및 요청
      if (!_locationManager!.hasValidLocation) {
        debugPrint('📍 현재 위치 요청 중...');
        await _locationManager!.requestLocation();
      }

      if (!_locationManager!.hasValidLocation) {
        debugPrint('❌ 현재 위치를 가져올 수 없습니다');
        return;
      }

      final currentLocation = _locationManager!.currentLocation!;
      final fromLatLng = NLatLng(currentLocation.latitude!, currentLocation.longitude!);
      
      debugPrint('📍 현재 위치: ${fromLatLng.latitude}, ${fromLatLng.longitude}');
      debugPrint('🏢 목적지: ${targetBuilding.name} (${targetBuilding.lat}, ${targetBuilding.lng})');

      // PathApiService를 통해 실제 경로 요청
      final pathCoordinates = await PathApiService.getRouteFromLocation(fromLatLng, targetBuilding);

      double distance;
      if (pathCoordinates.isNotEmpty) {
        // 실제 경로 거리 계산
        distance = _calculatePathDistance(pathCoordinates);
        debugPrint('✅ 실제 보행 경로 거리: ${distance.toStringAsFixed(0)}m');
      } else {
        // 서버 실패 시 직선 거리로 대체
        distance = _calculateDistance(
          fromLatLng.latitude,
          fromLatLng.longitude,
          targetBuilding.lat,
          targetBuilding.lng,
        );
        debugPrint('⚠️ 직선 거리로 대체: ${distance.toStringAsFixed(0)}m');
      }

      _routeDistance = '${distance.toStringAsFixed(0)}m';
      _routeTime = '${(distance / 80).ceil()}분'; // 평균 보행속도 80m/분 가정
      
      debugPrint('📏 최종 거리: $_routeDistance');
      debugPrint('⏱️ 예상 시간: $_routeTime');

      if (pathCoordinates.isNotEmpty) {
        // 경로를 지도에 그리기
        await _mapService?.drawPath(pathCoordinates);
        
        // 카메라를 경로에 맞춰 이동
        await _mapService?.moveCameraToPath(pathCoordinates);
        
        // 내 위치 마커도 표시
        await _mapService?.showMyLocation(fromLatLng);
        
        debugPrint('🎯 현재 위치에서 ${targetBuilding.name}까지 경로 표시 완료');
        
      } else {
        debugPrint('⚠️ 서버에서 경로를 받지 못함, 직선 경로로 대체');
        
        // 경로를 찾을 수 없는 경우 직선 경로로 대체
        final fallbackPath = [
          fromLatLng,
          NLatLng(targetBuilding.lat, targetBuilding.lng),
        ];
        await _mapService?.drawPath(fallbackPath);
        await _mapService?.moveCameraToPath(fallbackPath);
        await _mapService?.showMyLocation(fromLatLng);
      }
      
    } catch (e) {
      debugPrint('❌ 현재 위치 길찾기 오류: $e');
      _routeDistance = '계산 실패';
      _routeTime = '계산 실패';
      
      // 오류 발생 시에도 내 위치는 표시하려고 시도
      try {
        if (_locationManager?.hasValidLocation == true) {
          final currentLocation = _locationManager!.currentLocation!;
          final fromLatLng = NLatLng(currentLocation.latitude!, currentLocation.longitude!);
          
          // 최소한 직선 경로라도 표시
          final fallbackPath = [
            fromLatLng,
            NLatLng(targetBuilding.lat, targetBuilding.lng),
          ];
          await _mapService?.drawPath(fallbackPath);
          await _mapService?.moveCameraToPath(fallbackPath);
          await _mapService?.showMyLocation(fromLatLng);
        }
      } catch (fallbackError) {
        debugPrint('❌ 직선 경로 표시도 실패: $fallbackError');
      }
      
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  void setStartBuilding(Building building) {
    _startBuilding = building;
    // 현재 위치에서 길찾기 상태 초기화
    _isNavigatingFromCurrentLocation = false;
    _targetBuilding = null;
    notifyListeners();
  }

  void setEndBuilding(Building building) {
    _endBuilding = building;
    // 현재 위치에서 길찾기 상태 초기화
    _isNavigatingFromCurrentLocation = false;
    _targetBuilding = null;
    notifyListeners();
  }

Future<void> calculateRoute() async {
  if (_startBuilding == null || _endBuilding == null) {
    return;
  }
  
  try {
    _setLoading(true);
    
    final pathCoordinates = await PathApiService.getRoute(_startBuilding!, _endBuilding!);
    
    // MapService의 drawPath 사용
    if (pathCoordinates.isNotEmpty) {
      await _mapService?.drawPath(pathCoordinates);
      await _mapService?.moveCameraToPath(pathCoordinates);
    }
    
    // 거리 계산 등...
    
  } catch (e) {
    debugPrint('경로 계산 실패: $e');
  } finally {
    _setLoading(false);
    notifyListeners();
  }
}


  // 경로 초기화 - 안전한 오버레이 제거 추가
  Future<void> clearNavigation() async {
    try {
      debugPrint('모든 경로 관련 오버레이 제거 시작');
      
      // 안전한 오버레이 제거
      await _clearAllOverlays();
      
      // 기존 MapService 경로 제거
      await _mapService?.clearPath();
      
      // 상태 초기화
      _startBuilding = null;
      _endBuilding = null;
      _targetBuilding = null;
      _isNavigatingFromCurrentLocation = false;
      _routeDistance = null;
      _routeTime = null;
      
      debugPrint('모든 경로 관련 오버레이 제거 완료');
      notifyListeners();
    } catch (e) {
      debugPrint('경로 초기화 오류: $e');
    }
  }

  /// 위치 권한 오류 수동 해제
  void clearLocationError() {
    _hasLocationPermissionError = false;
    notifyListeners();
  }

  /// 내 위치 숨기기
  Future<void> hideMyLocation() async {
    try {
      await _mapService?.hideMyLocation();
      debugPrint('내 위치 마커 숨김 완료');
    } catch (e) {
      debugPrint('내 위치 마커 숨김 오류: $e');
    }
  }

  Future<void> toggleBuildingMarkers() async {
    try {
      await _mapService?.toggleBuildingMarkers();
      notifyListeners();
    } catch (e) {
      debugPrint('건물 마커 토글 오류: $e');
    }
  }

  List<Building> searchBuildings(String query) {
    return _mapService?.searchBuildings(query) ?? [];
  }

  void searchByCategory(String category) {
    final buildings = _mapService?.getBuildingsByCategory(category) ?? [];
    debugPrint('카테고리 검색: $category, 결과: ${buildings.length}개');
    
    if (buildings.isNotEmpty) {
      selectBuilding(buildings.first);
      final location = NLatLng(buildings.first.lat, buildings.first.lng);
      _mapService?.moveCamera(location, zoom: 16);
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // 위치 추적 중지
    _locationManager?.stopLocationTracking();
    _locationManager?.removeListener(_onLocationUpdate);
    _mapService?.dispose();
    super.dispose();
  }
}
