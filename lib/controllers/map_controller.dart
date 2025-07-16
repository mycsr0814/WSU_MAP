// lib/controllers/map_controller.dart - BuildingRepository 사용하도록 완전 수정
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/controllers/location_controllers.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter_application_1/services/map_service.dart';
import 'package:flutter_application_1/services/route_service.dart';
import 'package:flutter_application_1/services/path_api_service.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/models/category_marker_data.dart';
import 'package:flutter_application_1/repositories/building_repository.dart';
import 'dart:math' as math;
import 'package:flutter_application_1/core/result.dart';

class MapScreenController extends ChangeNotifier {
  MapService? _mapService;
  RouteService? _routeService;
  NMarker? _selectedMarker;
  final Map<String, NMarker> _buildingMarkers = {};

  // 🔥 BuildingRepository 사용 - _allBuildings 제거
  final BuildingRepository _buildingRepository = BuildingRepository();

  // 🔥 추가: 현재 Context 저장
  BuildContext? _currentContext;

  // 🏫 우송대학교 중심 좌표
  static const NLatLng _schoolCenter = NLatLng(36.3370, 127.4450);
  static const double _schoolZoomLevel = 15.5;

  // 선택된 건물
  Building? _selectedBuilding;

  // 경로 관련
  Building? _startBuilding;
  Building? _endBuilding;
  bool _isLoading = false;

  // 🔥 내 위치 관련 상태 완전 개선
  LocationController? _locationController;

  // 위치 권한 오류
  bool _hasLocationPermissionError = false;

  // 언어 변경 감지
  Locale? _currentLocale;

  // 경로 정보
  String? _routeDistance;
  String? _routeTime;

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
  bool get isLoading => _isLoading;
  bool get buildingMarkersVisible => _mapService?.buildingMarkersVisible ?? true;
  String? get routeDistance => _routeDistance;
  String? get routeTime => _routeTime;

  // 🔥 내 위치 관련 새로운 Getters
  bool get hasLocationPermissionError => _locationController?.hasLocationPermissionError ?? false;
  bool get hasMyLocationMarker => _locationController?.hasValidLocation ?? false;
  bool get isLocationRequesting => _locationController?.isRequesting ?? false;
  loc.LocationData? get myLocation => _locationController?.currentLocation;

  Building? get targetBuilding => _targetBuilding;
  bool get isNavigatingFromCurrentLocation => _isNavigatingFromCurrentLocation;
  bool get hasActiveRoute =>
      (_startBuilding != null && _endBuilding != null) ||
      _isNavigatingFromCurrentLocation;

  // 카테고리 관련 Getters
  String? get selectedCategory => _selectedCategory;
  bool get isCategoryLoading => _isCategoryLoading;
  String? get categoryError => _categoryError;

  /// 🚀 초기화 - 학교 중심으로 즉시 시작
  Future<void> initialize() async {
    try {
      debugPrint('🚀 MapController 초기화 시작 (학교 중심 방식)...');
      _isLoading = true;
      notifyListeners();

      // 서비스 초기화
      _mapService = MapService();
      _routeService = RouteService();

      // 🔥 BuildingRepository 데이터 변경 리스너 등록
      _buildingRepository.addDataChangeListener(_onBuildingDataChanged);

      // 병렬 초기화
      await Future.wait([
        _mapService!.loadMarkerIcons(),
        _testServerConnectionAsync(),
      ], eagerError: false);

      debugPrint('✅ MapController 초기화 완료 (학교 중심)');
    } catch (e) {
      debugPrint('❌ MapController 초기화 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 백그라운드 서버 연결 테스트
  Future<void> _testServerConnectionAsync() async {
    Future.microtask(() async {
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
    });
  }

  /// Context 설정 - 카테고리 아이콘 사전 생성 포함
  void setContext(BuildContext context) {
    _currentContext = context;
    _mapService?.setContext(context);
    
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

  /// 🔥 건물 이름 목록으로 카테고리 아이콘 마커 표시 - BuildingRepository 사용
Future<void> selectCategoryByNames(String category, List<String> buildingNames) async {
  debugPrint('=== 카테고리 선택 요청: $category ===');
  debugPrint('🔍 받은 건물 이름들: $buildingNames');

  // 빈 배열이거나 빈 카테고리면 해제
  if (category.isEmpty || buildingNames.isEmpty) {
    debugPrint('⚠️ 카테고리가 비어있음 - 해제 처리');
    await clearCategorySelection();
    return;
  }

  if (_selectedCategory == category) {
    debugPrint('같은 카테고리 재선택 → 해제');
    await clearCategorySelection();
    return;
  }

  // 이전 카테고리 정리 (마커 완전 제거)
  if (_selectedCategory != null) {
    debugPrint('이전 카테고리($_selectedCategory) 정리');
    await _clearCategoryMarkers();
  }

  _selectedCategory = category;
  _isCategoryLoading = true;
  notifyListeners();

  // MapService에 마지막 카테고리 선택 정보 저장
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


  /// 🔥 카테고리 아이콘 마커들 표시 - BuildingRepository 사용
  /// 카테고리 마커가 항상 정상적으로 갱신/표시되도록 비동기(await)로 완전히 개선된 버전입니다.
/// 
/// 
  Future<void> _showCategoryIconMarkers(List<String> buildingNames, String category) async {
    debugPrint('🔍 === 카테고리 매칭 디버깅 시작 ===');
    debugPrint('🔍 선택된 카테고리: $category');
    debugPrint('🔍 API에서 받은 건물 이름들: $buildingNames');
  
    final allBuildings = _buildingRepository.allBuildings;
    debugPrint('🔍 전체 건물 데이터 개수: ${allBuildings.length}');
  
    // BuildingRepository가 로딩되지 않았으면 대기 (재귀적 재시도)
    if (!_buildingRepository.isLoaded || allBuildings.length <= 1) {
      debugPrint('⏳ BuildingRepository 데이터 대기 중... 잠시 후 재시도');
      await Future.delayed(const Duration(seconds: 1));
      if (_selectedCategory == category) {
        await _buildingRepository.getAllBuildings();
        if (_buildingRepository.isLoaded && _buildingRepository.allBuildings.length > 1) {
          await _showCategoryIconMarkers(buildingNames, category);
        }
      }
      return;
    }
  
    debugPrint('🔍 카테고리 아이콘 마커 표시 시작: ${buildingNames.length}개');
  
    final categoryMarkerLocations = <CategoryMarkerData>[];
  
    for (final buildingName in buildingNames) {
      debugPrint('🔍 건물 검색 중: "$buildingName"');
      final building = _findBuildingByName(buildingName, allBuildings);
      if (building != null) {
        categoryMarkerLocations.add(CategoryMarkerData(
          buildingName: building.name,
          lat: building.lat,
          lng: building.lng,
          category: category,
          icon: _getCategoryIcon(category),
        ));
        debugPrint('✅ 카테고리 마커 추가: ${building.name} - $category 아이콘');
      }
    }
  
    debugPrint('🔍 === 매칭 결과 ===');
    debugPrint('🔍 총 매칭된 건물 수: ${categoryMarkerLocations.length}/${buildingNames.length}');
  
    if (categoryMarkerLocations.isEmpty) {
      debugPrint('❌ 매칭되는 건물이 없습니다 - 카테고리 해제');
      await clearCategorySelection();
      return;
    }
  
    debugPrint('📍 카테고리 마커 표시 시작...');
    await _mapService?.showCategoryIconMarkers(categoryMarkerLocations);
  
    debugPrint('✅ 카테고리 아이콘 마커 표시 완료: ${categoryMarkerLocations.length}개');
    debugPrint('🔍 === 카테고리 매칭 디버깅 끝 ===');
  }

  /// 🔥 향상된 건물 찾기 메서드 - BuildingRepository 사용
  Building? _findBuildingByName(String buildingName, List<Building> allBuildings) {
    try {
      // 1. 정확한 매칭 시도
      return allBuildings.firstWhere(
        (b) => b.name.trim().toUpperCase() == buildingName.trim().toUpperCase(),
      );
    } catch (e) {
      try {
        // 2. 부분 매칭 시도
        return allBuildings.firstWhere(
          (b) => b.name.contains(buildingName) || buildingName.contains(b.name),
        );
      } catch (e2) {
        try {
          // 3. 건물 코드 매칭 시도 (W1, W2 등)
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

  /// 🔥 BuildingRepository 데이터 변경 리스너
  void _onBuildingDataChanged(List<Building> buildings) {
    debugPrint('🔄 BuildingRepository 데이터 변경 감지: ${buildings.length}개');
    
    // 현재 선택된 카테고리가 있으면 재매칭
    if (_selectedCategory != null) {
      debugPrint('🔁 데이터 변경 후 카테고리 재매칭: $_selectedCategory');
      
      // 저장된 건물 이름들로 재매칭 시도
      final savedBuildingNames = _mapService?.getAllBuildings()
          .where((b) => b.category.toLowerCase() == _selectedCategory!.toLowerCase())
          .map((b) => b.name)
          .toList() ?? [];
      
      if (savedBuildingNames.isNotEmpty) {
        Future.microtask(() => _showCategoryIconMarkers(savedBuildingNames, _selectedCategory!));
      }
    }
  }

  /// 기존 _getCategoryIcon 메서드는 그대로 유지
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '카페':
        return Icons.local_cafe;
      case '식당':
        return Icons.restaurant;
      case '편의점':
        return Icons.store;
      case '자판기':
        return Icons.local_drink;
      case '화장실':
        return Icons.wc;
      case '프린터':
        return Icons.print;
      case '복사기':
        return Icons.content_copy;
      case 'ATM':
      case '은행(atm)':
        return Icons.atm;
      case '의료':
      case '보건소':
        return Icons.local_hospital;
      case '도서관':
        return Icons.local_library;
      case '체육관':
      case '헬스장':
        return Icons.fitness_center;
      case '주차장':
        return Icons.local_parking;
      case '라운지':
        return Icons.weekend;
      case '소화기':
        return Icons.fire_extinguisher;
      case '정수기':
        return Icons.water_drop;
      case '서점':
        return Icons.menu_book;
      case '우체국':
        return Icons.local_post_office;
      default:
        return Icons.category;
    }
  }

  /// 🔥 카테고리 마커들 제거
  Future<void> _clearCategoryMarkers() async {
  debugPrint('카테고리 마커들 제거 중...');
  await _mapService?.clearCategoryMarkers();
}

  /// 🔥 카테고리 선택 해제 (기존 건물 마커들 다시 표시)
  Future<void> clearCategorySelection() async {
  debugPrint('=== 카테고리 선택 해제 ===');
  if (_selectedCategory != null) {
    debugPrint('선택 해제할 카테고리: $_selectedCategory');
    await _clearCategoryMarkers();
  }
  _selectedCategory = null;
  _isCategoryLoading = false;
  debugPrint('모든 건물 마커 다시 표시 시작...');
  _showAllBuildingMarkers();
  debugPrint('✅ 카테고리 선택 해제 완료');
  notifyListeners();
}


  /// 🔥 모든 건물 마커 다시 표시
  void _showAllBuildingMarkers() {
    _mapService?.showAllBuildingMarkers();
  }

  /// 🔥 모든 건물 마커 숨기기
  void _hideAllBuildingMarkers() {
    _mapService?.hideAllBuildingMarkers();
  }

  /// 위치 업데이트 리스너 (단순화됨)
  void _onLocationUpdate() {
    notifyListeners();
  }

  /// 🚀 지도 준비 완료 - 즉시 학교 중심으로 이동
  Future<void> onMapReady(NaverMapController mapController) async {
    try {
      debugPrint('🗺️ 지도 준비 완료');
      _mapService?.setController(mapController);
      
      // 🔥 LocationController에 지도 컨트롤러 설정
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

  /// 내 위치로 이동 (단순화됨)
  Future<void> moveToMyLocation() async {
    await _locationController?.moveToMyLocation();
  }

  /// 위치 권한 재요청 (단순화됨)
  Future<void> retryLocationPermission() async {
    await _locationController?.retryLocationPermission();
  }

  /// 🏫 즉시 학교 중심으로 이동
  Future<void> _moveToSchoolCenterImmediately() async {
    try {
      debugPrint('🏫 즉시 학교 중심으로 이동');
      await _mapService?.moveCamera(_schoolCenter, zoom: _schoolZoomLevel);
      debugPrint('✅ 학교 중심 이동 완료');
    } catch (e) {
      debugPrint('❌ 학교 중심 이동 실패: $e');
    }
  }

  /// 🔥 건물 마커를 백그라운드에서 추가 - BuildingRepository 사용
  void _addBuildingMarkersInBackground() {
    Future.microtask(() async {
      try {
        debugPrint('🏢 건물 마커 추가 시작...');
        
        // 🔥 MapService에 콜백 등록 (BuildingRepository 데이터 변경 시 자동 재실행)
        _mapService!.setCategorySelectedCallback(_handleServerDataUpdate);
        
        await _mapService!.addBuildingMarkers(_onBuildingMarkerTap);
        debugPrint('✅ 건물 마커 추가 완료');
      } catch (e) {
        debugPrint('❌ 건물 마커 추가 오류: $e');
      }
    });
  }

  /// 🔥 서버 데이터 도착 시 카테고리 재매칭
  void _handleServerDataUpdate(String category, List<String> buildingNames) {
    debugPrint('🔄 서버 데이터 도착 - 카테고리 재매칭 중...');
    
    // 🔥 현재 선택된 카테고리가 있으면 재매칭
    if (_selectedCategory != null && _selectedCategory == category) {
      debugPrint('🔁 서버 데이터 도착 후 카테고리 재매칭: $_selectedCategory');
      _showCategoryIconMarkers(buildingNames, category);
    }
  }
  
  void _onBuildingMarkerTap(NMarker marker, Building building) async {
    await _mapService?.highlightBuildingMarker(marker);
    _selectedBuilding = building;
    notifyListeners();

    // 선택된 마커로 부드럽게 이동
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

Future<void> navigateFromCurrentLocation(Building targetBuilding) async {
  if (_locationController == null || _locationController!.currentLocation == null) {
    debugPrint('내 위치 정보가 없습니다.');
    return;
  }

  try {
    _setLoading(true);

    final myLoc = _locationController!.currentLocation!;
    final myLatLng = NLatLng(myLoc.latitude!, myLoc.longitude!);

    final pathCoordinates = await PathApiService.getRouteFromLocation(myLatLng, targetBuilding);

    if (pathCoordinates.isNotEmpty) {
      await _mapService?.drawPath(pathCoordinates);
      await _mapService?.moveCameraToPath(pathCoordinates);
    }
  } catch (e) {
    debugPrint('내 위치 경로 계산 실패: $e');
  } finally {
    _setLoading(false);
    notifyListeners();
  }
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

  Future<void> calculateRoute() async {
    if (_startBuilding == null || _endBuilding == null) return;

    try {
      _setLoading(true);
      final pathCoordinates = await PathApiService.getRoute(_startBuilding!, _endBuilding!);

      if (pathCoordinates.isNotEmpty) {
        await _mapService?.drawPath(pathCoordinates);
        await _mapService?.moveCameraToPath(pathCoordinates);
      }
    } catch (e) {
      debugPrint('경로 계산 실패: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<void> clearNavigation() async {
    try {
      debugPrint('모든 경로 관련 오버레이 제거 시작');

      await _clearAllOverlays();
      await _mapService?.clearPath();

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
  // ❌ 이렇게 되어 있을 것:
  // final buildings = _buildingRepository.getBuildingsByCategory(category);
  
  // ✅ 이렇게 수정:
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
    super.dispose();
  }
}