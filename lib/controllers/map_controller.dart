// lib/controllers/map_controller.dart - 통합 API 연동 버전

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/controllers/location_controllers.dart';
import 'package:flutter_application_1/inside/building_map_page.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter_application_1/services/map_service.dart';
import 'package:flutter_application_1/services/route_service.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/models/category_marker_data.dart';
import 'package:flutter_application_1/repositories/building_repository.dart';
import 'dart:math' as math;
import 'package:flutter_application_1/core/result.dart';

// 🔥 통합 API 관련 imports
import 'package:flutter_application_1/services/unified_path_service.dart';
import 'package:flutter_application_1/controllers/unified_navigation_controller.dart';

class MapScreenController extends ChangeNotifier {
  MapService? _mapService;
  RouteService? _routeService;
  NMarker? _selectedMarker;
  final Map<String, NMarker> _buildingMarkers = {};

  final BuildingRepository _buildingRepository = BuildingRepository();
  BuildContext? _currentContext;

  // 🏫 우송대학교 중심 좌표
  static const NLatLng _schoolCenter = NLatLng(36.3370, 127.4450);
  static const double _schoolZoomLevel = 15.5;

  // 선택된 건물
  Building? _selectedBuilding;

  // 🔥 통합 네비게이션 관련 새로운 상태
  Building? _startBuilding;
  Building? _endBuilding;
  NLatLng? _startLocation; // 현재 위치 출발용
  bool _isLoading = false;
  
  // 🔥 통합 네비게이션 컨트롤러
  UnifiedNavigationController? _navigationController;
  bool _isUnifiedNavigationActive = false;

  LocationController? _locationController;
  bool _hasLocationPermissionError = false;
  Locale? _currentLocale;

  // 실외 경로 정보
  String? _routeDistance;
  String? _routeTime;
  List<NLatLng>? _outdoorPath;

  // 현재 위치에서 길찾기 관련 속성
  Building? _targetBuilding;
  bool _isNavigatingFromCurrentLocation = false;

  // 오버레이 관리
  final List<NOverlay> _routeOverlays = [];

  // 카테고리 관련 상태
  String? _selectedCategory;
  bool _isCategoryLoading = false;
  String? _categoryError;

  // Getters
  Building? get selectedBuilding => _selectedBuilding;
  Building? get startBuilding => _startBuilding;
  Building? get endBuilding => _endBuilding;
  NLatLng? get startLocation => _startLocation;
  bool get isLoading => _isLoading;
  bool get buildingMarkersVisible => _mapService?.buildingMarkersVisible ?? true;
  String? get routeDistance => _routeDistance;
  String? get routeTime => _routeTime;

  // 🔥 통합 네비게이션 관련 Getters
  bool get isUnifiedNavigationActive => _isUnifiedNavigationActive;
  UnifiedNavigationController? get navigationController => _navigationController;
  NavigationState? get navigationState => _navigationController?.state;

  bool get hasLocationPermissionError => _locationController?.hasLocationPermissionError ?? false;
  bool get hasMyLocationMarker => _locationController?.hasValidLocation ?? false;
  bool get isLocationRequesting => _locationController?.isRequesting ?? false;
  loc.LocationData? get myLocation => _locationController?.currentLocation;

  Building? get targetBuilding => _targetBuilding;
  bool get isNavigatingFromCurrentLocation => _isNavigatingFromCurrentLocation;
  bool get hasActiveRoute =>
      (_startBuilding != null && _endBuilding != null) ||
      _isNavigatingFromCurrentLocation ||
      _isUnifiedNavigationActive;

  String? get selectedCategory => _selectedCategory;
  bool get isCategoryLoading => _isCategoryLoading;
  String? get categoryError => _categoryError;

  /// 🚀 초기화
  Future<void> initialize() async {
    try {
      debugPrint('🚀 MapController 초기화 시작 (통합 API 버전)...');
      _isLoading = true;
      notifyListeners();

      // 🔥 통합 네비게이션 컨트롤러 초기화
      _navigationController = UnifiedNavigationController();

      _mapService = MapService();
      _routeService = RouteService();

      _buildingRepository.addDataChangeListener(_onBuildingDataChanged);

      await Future.wait([
        _mapService!.loadMarkerIcons(),
        _testServerConnectionAsync(),
      ], eagerError: false);

      debugPrint('✅ MapController 초기화 완료 (통합 API)');
    } catch (e) {
      debugPrint('❌ MapController 초기화 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _testServerConnectionAsync() async {
    Future.microtask(() async {
      try {
        final isServerConnected = await UnifiedPathService.testConnection();
        if (isServerConnected) {
          debugPrint('🌐 통합 API 서버 연결 확인 완료');
        } else {
          debugPrint('⚠️ 통합 API 서버 연결 실패 (정상 동작 가능)');
        }
      } catch (e) {
        debugPrint('⚠️ 통합 API 서버 연결 테스트 오류: $e');
      }
    });
  }

void setContext(BuildContext context) {
  _currentContext = context;
  _mapService?.setContext(context);

  // 🔥 통합 네비게이션 컨트롤러에도 컨텍스트 설정
  _navigationController?.setContext(context);

  debugPrint('✅ MapController에 Context 설정 완료');

  final currentLocale = Localizations.localeOf(context);
  if (_currentLocale != null && _currentLocale != currentLocale) {
    debugPrint('언어 변경 감지: ${_currentLocale?.languageCode} -> ${currentLocale.languageCode}');
    _onLocaleChanged(currentLocale);
  }
  _currentLocale = currentLocale;
}


  void _onLocaleChanged(Locale newLocale) {
    debugPrint('언어 변경으로 인한 마커 재생성 시작');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshBuildingMarkers();
    });
  }

  Future<void> _refreshBuildingMarkers() async {
    if (_mapService == null) return;

    try {
      debugPrint('언어 변경으로 인한 마커 재생성 시작');
      await _mapService!.addBuildingMarkers(_onBuildingMarkerTap);
      debugPrint('언어 변경으로 인한 마커 재생성 완료');
    } catch (e) {
      debugPrint('마커 재생성 오류: $e');
    }
  }

  // 🔥 통합 네비게이션 시작 메서드들

  /// 건물 간 통합 네비게이션 시작
  Future<bool> startUnifiedNavigationBetweenBuildings({
    required Building fromBuilding,
    required Building toBuilding,
  }) async {
    try {
      debugPrint('🚀 건물 간 통합 네비게이션 시작: ${fromBuilding.name} → ${toBuilding.name}');
      
      _setLoading(true);
      _startBuilding = fromBuilding;
      _endBuilding = toBuilding;
      _startLocation = null;
      
      final success = await _navigationController!.startNavigationBetweenBuildings(
        fromBuilding: fromBuilding,
        toBuilding: toBuilding,
      );
      
      if (success) {
        _isUnifiedNavigationActive = true;
        await _handleNavigationStateChange();
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ 건물 간 통합 네비게이션 시작 오류: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 현재 위치에서 건물로 통합 네비게이션 시작
  Future<bool> startUnifiedNavigationFromCurrentLocation({
    required Building toBuilding,
  }) async {
    try {
      if (_locationController?.currentLocation == null) {
        debugPrint('❌ 현재 위치 정보가 없습니다');
        return false;
      }

      final currentLocation = _locationController!.currentLocation!;
      final startLatLng = NLatLng(currentLocation.latitude!, currentLocation.longitude!);

      debugPrint('🚀 현재 위치에서 통합 네비게이션 시작: 내 위치 → ${toBuilding.name}');
      
      _setLoading(true);
      _startBuilding = null;
      _endBuilding = toBuilding;
      _startLocation = startLatLng;
      
      final success = await _navigationController!.startNavigationFromCurrentLocation(
        currentLocation: startLatLng,
        toBuilding: toBuilding,
      );
      
      if (success) {
        _isUnifiedNavigationActive = true;
        await _handleNavigationStateChange();
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ 현재 위치 통합 네비게이션 시작 오류: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 호실 간 통합 네비게이션 시작
  Future<bool> startUnifiedNavigationBetweenRooms({
    required String fromBuilding,
    required int fromFloor,
    required String fromRoom,
    required String toBuilding,
    required int toFloor,
    required String toRoom,
  }) async {
    try {
      debugPrint('🚀 호실 간 통합 네비게이션 시작');
      
      _setLoading(true);
      
      final success = await _navigationController!.startNavigationBetweenRooms(
        fromBuilding: fromBuilding,
        fromFloor: fromFloor,
        fromRoom: fromRoom,
        toBuilding: toBuilding,
        toFloor: toFloor,
        toRoom: toRoom,
      );
      
      if (success) {
        _isUnifiedNavigationActive = true;
        await _handleNavigationStateChange();
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ 호실 간 통합 네비게이션 시작 오류: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 🔥 네비게이션 상태 변경 처리
  Future<void> _handleNavigationStateChange() async {
    if (_navigationController == null) return;

    final state = _navigationController!.state;
    debugPrint('📍 네비게이션 상태 변경: ${state.currentStep}');

    switch (state.currentStep) {
      case NavigationStep.departureIndoor:
        await _handleDepartureIndoorStep();
        break;
        
      case NavigationStep.outdoor:
        await _handleOutdoorStep();
        break;
        
      case NavigationStep.arrivalIndoor:
        await _handleArrivalIndoorStep();
        break;
        
      case NavigationStep.completed:
        await _handleNavigationCompleted();
        break;
    }
  }

  /// 출발지 실내 단계 처리
  Future<void> _handleDepartureIndoorStep() async {
    if (_startBuilding == null || _currentContext == null) return;

    debugPrint('🏢 출발지 실내 네비게이션 시작');

    // BuildingMapPage로 이동하여 출발지 실내 안내
    final result = await Navigator.of(_currentContext!).push(
      MaterialPageRoute(
        builder: (context) => BuildingMapPage(
          buildingName: _startBuilding!.name,
          navigationController: _navigationController,
          isArrivalNavigation: false,
        ),
      ),
    );

    if (result == 'completed') {
      _navigationController?.proceedToNextStep();
    }
  }

  /// 실외 단계 처리  
  Future<void> _handleOutdoorStep() async {
    debugPrint('🌍 실외 네비게이션 시작');

    // 실외 경로 표시 (기존 MapService 사용)
    if (_navigationController?.currentPathResponse?.result.outdoor != null) {
      final outdoorData = _navigationController!.currentPathResponse!.result.outdoor!;
      final coordinates = UnifiedPathService.extractOutdoorCoordinates(outdoorData);
      
      if (coordinates.isNotEmpty) {
        _outdoorPath = coordinates;
        await _mapService?.drawPath(coordinates);
        await _mapService?.moveCameraToPath(coordinates);
        
        // 거리와 시간 정보 업데이트
        _routeDistance = '${outdoorData.path.distance.toStringAsFixed(0)}m';
        _routeTime = _calculateWalkingTime(outdoorData.path.distance);
        
        notifyListeners();
      }
    }
  }

  /// 도착지 실내 단계 처리
  Future<void> _handleArrivalIndoorStep() async {
    if (_endBuilding == null || _currentContext == null) return;

    debugPrint('🏢 도착지 실내 네비게이션 시작');

    // BuildingMapPage로 이동하여 도착지 실내 안내
    final result = await Navigator.of(_currentContext!).push(
      MaterialPageRoute(
        builder: (context) => BuildingMapPage(
          buildingName: _endBuilding!.name,
          navigationController: _navigationController,
          isArrivalNavigation: true,
        ),
      ),
    );

    if (result == 'completed') {
      _navigationController?.proceedToNextStep();
    }
  }

  /// 네비게이션 완료 처리
  Future<void> _handleNavigationCompleted() async {
    debugPrint('✅ 통합 네비게이션 완료');
    
    _isUnifiedNavigationActive = false;
    
    // 완료 메시지 표시
    if (_currentContext != null) {
      ScaffoldMessenger.of(_currentContext!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('목적지에 도착했습니다!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    notifyListeners();
  }

  /// 🔥 통합 네비게이션 중단
  Future<void> stopUnifiedNavigation() async {
    debugPrint('🛑 통합 네비게이션 중단');
    
    _navigationController?.stopNavigation();
    _isUnifiedNavigationActive = false;
    
    await clearNavigation();
    notifyListeners();
  }

  /// 걷기 시간 계산 (4km/h 기준)
  String _calculateWalkingTime(double distanceInMeters) {
    final timeInMinutes = (distanceInMeters / 1000 / 4 * 60).round();
    if (timeInMinutes < 60) {
      return '도보 ${timeInMinutes}분';
    } else {
      final hours = timeInMinutes ~/ 60;
      final minutes = timeInMinutes % 60;
      return '도보 ${hours}시간 ${minutes}분';
    }
  }

  // 🔥 기존 메서드들 (통합 API 호환성을 위해 유지)

  /// 레거시 건물 간 경로 계산 (이제 통합 API 사용)
  Future<void> calculateRoute() async {
    if (_startBuilding == null || _endBuilding == null) return;

    debugPrint('🔄 레거시 calculateRoute → 통합 네비게이션으로 변환');
    
    await startUnifiedNavigationBetweenBuildings(
      fromBuilding: _startBuilding!,
      toBuilding: _endBuilding!,
    );
  }

  /// 레거시 현재 위치 네비게이션 (이제 통합 API 사용) 
  Future<void> navigateFromCurrentLocation(Building targetBuilding) async {
    debugPrint('🔄 레거시 navigateFromCurrentLocation → 통합 네비게이션으로 변환');
    
    await startUnifiedNavigationFromCurrentLocation(toBuilding: targetBuilding);
  }

  // 카테고리 관련 메서드들 (기존과 동일)
  void selectCategoryByNames(String category, List<String> buildingNames) {
    debugPrint('=== 카테고리 선택 요청: $category ===');
    debugPrint('🔍 받은 건물 이름들: $buildingNames');
    
    if (category.isEmpty || buildingNames.isEmpty) {
      debugPrint('⚠️ 카테고리가 비어있음 - 해제 처리');
      clearCategorySelection();
      return;
    }
    
    if (_selectedCategory == category) {
      debugPrint('같은 카테고리 재선택 → 해제');
      clearCategorySelection();
      return;
    }

    if (_selectedCategory != null) {
      debugPrint('이전 카테고리($_selectedCategory) 정리');
      _clearCategoryMarkers();
    }

  _selectedCategory = category;
  _isCategoryLoading = true;
  notifyListeners();

    _mapService?.saveLastCategorySelection(category, buildingNames);

  try {
    debugPrint('기존 건물 마커들 숨기기...');
    _hideAllBuildingMarkers();

    debugPrint('카테고리 아이콘 마커들 표시...');
    await _showCategoryIconMarkers(buildingNames, category);

    debugPrint('✅ 카테고리 선택 완료: $category');
  } catch (e) {
    debugPrint('🚨 카테고리 선택 오류: $e');
    await clearCategorySelection();
  } finally {
    _isCategoryLoading = false;
    notifyListeners();
  }
}


  void _showCategoryIconMarkers(List<String> buildingNames, String category) {
    final allBuildings = _buildingRepository.allBuildings;
    
    if (!_buildingRepository.isLoaded || allBuildings.length <= 1) {
      Timer(const Duration(seconds: 1), () {
        if (_selectedCategory == category) {
          _buildingRepository.getAllBuildings().then((_) {
            if (_buildingRepository.isLoaded && _buildingRepository.allBuildings.length > 1) {
              _showCategoryIconMarkers(buildingNames, category);
            }
          });
        }
      }
      return;
    }
    
    final categoryMarkerLocations = <CategoryMarkerData>[];
    
    for (String buildingName in buildingNames) {
      Building? building = _findBuildingByName(buildingName, allBuildings);
      
      if (building != null) {
        categoryMarkerLocations.add(CategoryMarkerData(
          buildingName: building.name,
          lat: building.lat,
          lng: building.lng,
          category: category,
          icon: _getCategoryIcon(category),
        ));
      }
    }

    if (categoryMarkerLocations.isEmpty) {
      Future.microtask(() => clearCategorySelection());
      return;
    }

    _mapService?.showCategoryIconMarkers(categoryMarkerLocations);
  }

  Building? _findBuildingByName(String buildingName, List<Building> allBuildings) {
    try {
      return allBuildings.firstWhere(
        (b) => b.name.trim().toUpperCase() == buildingName.trim().toUpperCase(),
      );
    } catch (e) {
      try {
        return allBuildings.firstWhere(
          (b) => b.name.contains(buildingName) || buildingName.contains(b.name),
        );
      } catch (e2) {
        try {
          return allBuildings.firstWhere(
            (b) => b.name.toLowerCase().contains(buildingName.toLowerCase()),
          );
        } catch (e3) {
          debugPrint('❌ 매칭 실패: "$buildingName"');
          return null;
        }
      }
    }
  }

  void _onBuildingDataChanged(List<Building> buildings) {
    debugPrint('🔄 BuildingRepository 데이터 변경 감지: ${buildings.length}개');
    
    if (_selectedCategory != null) {
      final savedBuildingNames = _mapService?.getAllBuildings()
          .where((b) => b.category.toLowerCase() == _selectedCategory!.toLowerCase())
          .map((b) => b.name)
          .toList() ?? [];
      
      if (savedBuildingNames.isNotEmpty) {
        Future.microtask(() => _showCategoryIconMarkers(savedBuildingNames, _selectedCategory!));
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '카페': return Icons.local_cafe;
      case '식당': return Icons.restaurant;
      case '편의점': return Icons.store;
      case '자판기': return Icons.local_drink;
      case '화장실': return Icons.wc;
      case '프린터': return Icons.print;
      case '복사기': return Icons.content_copy;
      case 'ATM':
      case '은행(atm)': return Icons.atm;
      case '의료':
      case '보건소': return Icons.local_hospital;
      case '도서관': return Icons.local_library;
      case '체육관':
      case '헬스장': return Icons.fitness_center;
      case '주차장': return Icons.local_parking;
      case '라운지': return Icons.weekend;
      case '소화기': return Icons.fire_extinguisher;
      case '정수기': return Icons.water_drop;
      case '서점': return Icons.menu_book;
      case '우체국': return Icons.local_post_office;
      default: return Icons.category;
    }
  }

  void _clearCategoryMarkers() {
    _mapService?.clearCategoryMarkers();
  }

  void clearCategorySelection() {
    if (_selectedCategory != null) {
      _clearCategoryMarkers();
    }
    
    _selectedCategory = null;
    _isCategoryLoading = false;
    _showAllBuildingMarkers();
    notifyListeners();
  }

  void _showAllBuildingMarkers() {
    _mapService?.showAllBuildingMarkers();
  }

  void _hideAllBuildingMarkers() {
    _mapService?.hideAllBuildingMarkers();
  }

  // 기본 메서드들
  void _onLocationUpdate() {
    notifyListeners();
  }

  Future<void> onMapReady(NaverMapController mapController) async {
    try {
      debugPrint('🗺️ 지도 준비 완료');
      _mapService?.setController(mapController);
      _locationController?.setMapController(mapController);

      await _moveToSchoolCenterImmediately();
      _addBuildingMarkersInBackground();
      
      debugPrint('✅ 지도 서비스 설정 완료');
    } catch (e) {
      debugPrint('❌ 지도 준비 오류: $e');
    }
  }

  void setLocationController(LocationController locationController) {
    _locationController = locationController;
    _locationController!.addListener(_onLocationUpdate);
    debugPrint('✅ LocationController 설정 완료');
  }

  Future<void> moveToMyLocation() async {
    await _locationController?.moveToMyLocation();
  }

  Future<void> retryLocationPermission() async {
    await _locationController?.retryLocationPermission();
  }

  Future<void> _moveToSchoolCenterImmediately() async {
    try {
      debugPrint('🏫 즉시 학교 중심으로 이동');
      await _mapService?.moveCamera(_schoolCenter, zoom: _schoolZoomLevel);
      debugPrint('✅ 학교 중심 이동 완료');
    } catch (e) {
      debugPrint('❌ 학교 중심 이동 실패: $e');
    }
  }

  void _addBuildingMarkersInBackground() {
    Future.microtask(() async {
      try {
        debugPrint('🏢 건물 마커 추가 시작...');
        _mapService!.setCategorySelectedCallback(_handleServerDataUpdate);
        await _mapService!.addBuildingMarkers(_onBuildingMarkerTap);
        debugPrint('✅ 건물 마커 추가 완료');
      } catch (e) {
        debugPrint('❌ 건물 마커 추가 오류: $e');
      }
    });
  }

  void _handleServerDataUpdate(String category, List<String> buildingNames) {
    if (_selectedCategory != null && _selectedCategory == category) {
      _showCategoryIconMarkers(buildingNames, category);
    }
  }
  
  void _onBuildingMarkerTap(NMarker marker, Building building) async {
    await _mapService?.highlightBuildingMarker(marker);
    _selectedBuilding = building;
    notifyListeners();
    await _mapService?.moveCamera(marker.position, zoom: 17);
  }

  void selectBuilding(Building building) {
    _selectedBuilding = building;
    notifyListeners();
  }

  void clearSelectedBuilding() {
    if (_selectedBuilding != null) {
      _mapService?.resetAllBuildingMarkers();
      _selectedBuilding = null;
      notifyListeners();
    }
  }

  void closeInfoWindow(OverlayPortalController controller) {
    if (controller.isShowing) {
      controller.hide();
    }
    clearSelectedBuilding();
    debugPrint('🚪 InfoWindow 닫기 완료');
  }

  void setStartBuilding(Building building) {
    _startBuilding = building;
    _isNavigatingFromCurrentLocation = false;
    _targetBuilding = null;
    notifyListeners();
  }

  void setEndBuilding(Building building) {
    _endBuilding = building;
    _isNavigatingFromCurrentLocation = false;
    _targetBuilding = null;
    notifyListeners();
  }

  Future<void> clearNavigation() async {
    try {
      debugPrint('모든 경로 관련 오버레이 제거 시작');

      await _clearAllOverlays();
      await _mapService?.clearPath();

      _startBuilding = null;
      _endBuilding = null;
      _startLocation = null;
      _targetBuilding = null;
      _isNavigatingFromCurrentLocation = false;
      _routeDistance = null;
      _routeTime = null;
      _outdoorPath = null;

      // 🔥 통합 네비게이션도 중단
      if (_isUnifiedNavigationActive) {
        await stopUnifiedNavigation();
      }

      debugPrint('모든 경로 관련 오버레이 제거 완료');
      notifyListeners();
    } catch (e) {
      debugPrint('경로 초기화 오류: $e');
    }
  }

  Future<void> _clearAllOverlays() async {
    try {
      final controller = await _mapService?.getController();
      if (controller == null) return;

      if (_routeOverlays.isNotEmpty) {
        for (final overlay in List.from(_routeOverlays)) {
          try {
            controller.deleteOverlay(overlay.info);
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

  void clearLocationError() {
    _hasLocationPermissionError = false;
    notifyListeners();
  }

  Future<void> toggleBuildingMarkers() async {
    try {
      await _mapService?.toggleBuildingMarkers();
      notifyListeners();
    } catch (e) {
      debugPrint('건물 마커 토글 오류: $e');
    }
  }

  Result<List<Building>> searchBuildings(String query) {
    return _buildingRepository.searchBuildings(query);
  }

  void searchByCategory(String category) {
    final result = _buildingRepository.getBuildingsByCategory(category);
    final buildings = result.isSuccess ? result.data! : [];
    
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
    clearCategorySelection();
    _locationController?.removeListener(_onLocationUpdate);
    _buildingRepository.removeDataChangeListener(_onBuildingDataChanged);
    _buildingRepository.dispose();
    _mapService?.dispose();
    _navigationController?.dispose();
    super.dispose();
  }
}