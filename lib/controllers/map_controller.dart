// lib/controllers/map_controller.dart - 카테고리 기능 수정 (최종)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter_application_1/services/map_service.dart';
import 'package:flutter_application_1/services/route_service.dart';
import 'package:flutter_application_1/services/path_api_service.dart';
import 'package:flutter_application_1/managers/location_manager.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/models/category_marker_data.dart'; // 🔥 새로 추가
import 'dart:math' as math;

class MapScreenController extends ChangeNotifier {
  MapService? _mapService;
  RouteService? _routeService;
  LocationManager? _locationManager;

  NMarker? _selectedMarker;
  final Map<String, NMarker> _buildingMarkers = {};

  // 🔥 전체 건물 목록 추가
  List<Building> _allBuildings = [];

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
  bool _hasMyLocationMarker = false;
  bool _isLocationRequesting = false;
  bool _isRealLocationFound = false;
  loc.LocationData? _myLocation;
  bool _hasRequestedLocationOnce = false;

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
  bool get hasLocationPermissionError => _hasLocationPermissionError;
  bool get buildingMarkersVisible => _mapService?.buildingMarkersVisible ?? true;
  String? get routeDistance => _routeDistance;
  String? get routeTime => _routeTime;

  // 🔥 내 위치 관련 새로운 Getters
  bool get hasMyLocationMarker => _hasMyLocationMarker;
  bool get isLocationRequesting => _isLocationRequesting;
  bool get isRealLocationFound => _isRealLocationFound;
  loc.LocationData? get myLocation => _myLocation;

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

  /// Context 설정
   void setContext(BuildContext context) {
    _currentContext = context; // 🔥 Context 저장
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

  /// 🔥 LocationManager 설정 - 중복 방지 및 최적화
  void setLocationManager(LocationManager locationManager) {
    _locationManager = locationManager;
    
    // 위치 업데이트 리스너 등록
    _locationManager!.addListener(_onLocationUpdate);
    
    // 🔥 백그라운드에서 한 번만 내 위치 요청
    if (!_hasRequestedLocationOnce) {
      _startBackgroundLocationRequestOnce();
    }
    
    debugPrint('✅ LocationManager 설정 완료 (백그라운드 위치 요청)');
  }

  /// 🔥 백그라운드에서 한 번만 내 위치 요청
  void _startBackgroundLocationRequestOnce() {
    _hasRequestedLocationOnce = true;
    
    Future.microtask(() async {
      try {
        debugPrint('🔄 백그라운드에서 내 위치 요청 시작 (한 번만)...');
        _isLocationRequesting = true;
        notifyListeners();

        // 2초 지연 후 위치 요청 (UI 로딩 완료 후)
        await Future.delayed(const Duration(seconds: 2));
        
        // 실제 위치만 요청
        await _requestRealLocationOnlyOnce();
        
      } catch (e) {
        debugPrint('❌ 백그라운드 위치 요청 실패: $e');
        _hasLocationPermissionError = true;
      } finally {
        _isLocationRequesting = false;
        notifyListeners();
      }
    });
  }

  /// 🔥 실제 위치만 요청 (한 번만)
  Future<void> _requestRealLocationOnlyOnce() async {
    try {
      debugPrint('📍 실제 위치 한 번만 요청...');
      
      // 권한 조용히 확인
      final hasPermission = await _locationManager!.checkPermissionQuietly();
      if (!hasPermission) {
        debugPrint('⚠️ 위치 권한 없음 - 조용히 대기');
        _hasLocationPermissionError = true;
        return;
      }

      // 실제 위치 요청
      await _locationManager!.requestLocation();
      
    } catch (e) {
      debugPrint('❌ 실제 위치 요청 실패: $e');
      _hasLocationPermissionError = true;
    }
  }

  /// 🔥 건물 이름 목록으로 카테고리 아이콘 마커 표시 (단일 메서드)
  /// 🔥 건물 이름 목록으로 카테고리 아이콘 마커 표시 (개선된 버전)
 void selectCategoryByNames(String category, List<String> buildingNames) {
  debugPrint('=== 카테고리 선택 요청: $category ===');
  debugPrint('🔍 받은 건물 이름들: $buildingNames');
  
  // 빈 배열이거나 빈 카테고리면 해제
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

  // 이전 카테고리 정리
  if (_selectedCategory != null) {
    debugPrint('이전 카테고리($_selectedCategory) 정리');
    _clearCategoryMarkers();
  }

  _selectedCategory = category;
  _isCategoryLoading = true;
  notifyListeners();

  // 🔥 MapService에 마지막 카테고리 선택 정보 저장
  _mapService?.saveLastCategorySelection(category, buildingNames);

  try {
    debugPrint('기존 건물 마커들 숨기기...');
    _hideAllBuildingMarkers();

    // 🔥 Context가 없으면 잠시 대기 후 재시도
    if (_currentContext == null) {
      debugPrint('⏳ Context 대기 중... 잠시 후 재시도');
      Timer(const Duration(milliseconds: 500), () {
        if (_selectedCategory == category) { // 여전히 같은 카테고리가 선택되어 있으면
          debugPrint('🔄 Context 대기 후 재시도');
          _showCategoryIconMarkers(buildingNames, category);
        }
      });
    } else {
      debugPrint('카테고리 아이콘 마커들 표시...');
      _showCategoryIconMarkers(buildingNames, category);
    }
    
    debugPrint('🔍 전체 건물 데이터 개수: ${_allBuildings.length}');
    debugPrint('✅ 카테고리 선택 완료: $category');
  } catch (e) {
    debugPrint('🚨 카테고리 선택 오류: $e');
    clearCategorySelection();
  } finally {
    _isCategoryLoading = false;
    notifyListeners();
  }
}

  /// 🔥 카테고리 아이콘 마커들 표시 (디버깅 강화)
// 🔥 카테고리 아이콘 마커들 표시 (빈 배열 체크 제거)
void _showCategoryIconMarkers(List<String> buildingNames, String category) {
    debugPrint('🔍 === 카테고리 매칭 디버깅 시작 ===');
    debugPrint('🔍 선택된 카테고리: $category');
    debugPrint('🔍 API에서 받은 건물 이름들: $buildingNames');
    debugPrint('🔍 전체 건물 데이터 개수: ${_allBuildings.length}');
    
    // 🔥 Context 확인
    if (_currentContext == null) {
      debugPrint('❌ Context가 없어서 카테고리 마커 표시 불가');
      return;
    }
    
    // 🔥 MapService에 Context가 설정되어 있는지 확인
    if (_mapService?.context == null) {
      debugPrint('🔄 MapService에 Context 재설정...');
      _mapService?.setContext(_currentContext!);
    }
    
    // 서버 데이터가 아직 도착하지 않았으면 대기
    if (_allBuildings.length <= 1) {
      debugPrint('⏳ 서버 데이터 대기 중... 잠시 후 재시도');
      Timer(const Duration(seconds: 1), () {
        if (_selectedCategory == category) {
          _allBuildings = _mapService!.getAllBuildings();
          debugPrint('🔄 재시도 - 건물 데이터: ${_allBuildings.length}개');
          if (_allBuildings.length > 1) {
            _showCategoryIconMarkers(buildingNames, category);
          }
        }
      });
      return;
    }
    
    debugPrint('🔍 카테고리 아이콘 마커 표시 시작: ${buildingNames.length}개');

    // 전체 건물 목록에서 해당 건물들 찾기
    final categoryMarkerLocations = <CategoryMarkerData>[];
    
    for (String buildingName in buildingNames) {
      debugPrint('🔍 건물 검색 중: "$buildingName"');
      
      Building? building;
      try {
        building = _allBuildings.firstWhere(
          (b) => b.name.trim().toUpperCase() == buildingName.trim().toUpperCase(),
        );
        debugPrint('✅ 정확한 매칭 성공: ${building.name}');
      } catch (e) {
        try {
          building = _allBuildings.firstWhere(
            (b) => b.name.contains(buildingName) || buildingName.contains(b.name),
          );
          debugPrint('✅ 부분 매칭 성공: ${building.name} (검색어: $buildingName)');
        } catch (e2) {
          debugPrint('❌ 매칭 실패: "$buildingName"');
          building = null;
        }
      }
      
      if (building != null) {
        categoryMarkerLocations.add(CategoryMarkerData(
          buildingName: building.name,
          location: Location(x: building.lat, y: building.lng),
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
      Future.microtask(() => clearCategorySelection());
      return;
    }

    // 🔥 Context 재확인 후 MapService에 카테고리 아이콘 마커들 표시 요청
    debugPrint('📍 Context 확인 완료, 카테고리 마커 표시 시작...');
    _mapService?.showCategoryIconMarkers(categoryMarkerLocations);
    
    debugPrint('✅ 카테고리 아이콘 마커 표시 완료: ${categoryMarkerLocations.length}개');
    debugPrint('🔍 === 카테고리 매칭 디버깅 끝 ===');
  }

  // 🔥 기존 _getCategoryIcon 메서드는 그대로 유지 (기존 코드와 동일)
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
  void _clearCategoryMarkers() {
    debugPrint('카테고리 마커들 제거 중...');
    _mapService?.clearCategoryMarkers();
  }

  /// 🔥 카테고리 선택 해제 (기존 건물 마커들 다시 표시)
  void clearCategorySelection() {
    debugPrint('=== 카테고리 선택 해제 ===');
    
    if (_selectedCategory != null) {
      debugPrint('선택 해제할 카테고리: $_selectedCategory');
      _clearCategoryMarkers();
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
    _mapService?.showAllBuildingMarkers(_allBuildings);
    debugPrint('📋 전체 건물 데이터 로드: ${_allBuildings.length}개');
  }

  /// 🔥 모든 건물 마커 숨기기
  void _hideAllBuildingMarkers() {
    _mapService?.hideAllBuildingMarkers();
  }

  /// 🔥 위치 업데이트 리스너
  void _onLocationUpdate() {
    if (_locationManager?.hasValidLocation == true && _mapService != null) {
      final location = _locationManager!.currentLocation!;
      
      // 🔥 실제 위치인지 확인
      if (_locationManager!.isActualGPSLocation(location)) {
        debugPrint('✅ 실제 GPS 위치 획득: ${location.latitude}, ${location.longitude}');
        
        final nLocation = NLatLng(location.latitude!, location.longitude!);
        
        // 🔥 내 위치 저장
        _myLocation = location;
        _isRealLocationFound = true;
        
        // 🔥 마커가 없을 때만 추가 (중복 방지)
        if (!_hasMyLocationMarker) {
          _mapService!.updateMyLocation(nLocation, shouldMoveCamera: false);
          _hasMyLocationMarker = true;
          debugPrint('✅ 내 위치 마커 최초 생성');
        } else {
          // 기존 마커 위치만 업데이트
          _mapService!.updateMyLocation(nLocation, shouldMoveCamera: false);
          debugPrint('📍 내 위치 마커 위치 업데이트');
        }
        
        _hasLocationPermissionError = false;
        notifyListeners();
      } else {
        debugPrint('⚠️ Fallback 위치 감지됨, 마커 표시하지 않음');
      }
    }

    // 위치 권한 오류 상태 업데이트
    final hasError = _locationManager?.hasLocationPermissionError ?? false;
    if (_hasLocationPermissionError != hasError) {
      _hasLocationPermissionError = hasError;
      notifyListeners();
    }
  }

  /// 🚀 지도 준비 완료 - 즉시 학교 중심으로 이동
  Future<void> onMapReady(NaverMapController mapController) async {
    try {
      debugPrint('🗺️ 지도 준비 완료, 즉시 학교 중심으로 설정');
      _mapService?.setController(mapController);

      // 🔥 즉시 학교 중심으로 이동 (GPS 대기 없음)
      await _moveToSchoolCenterImmediately();

      // 🔥 건물 마커 추가 (백그라운드)
      _addBuildingMarkersInBackground();

      debugPrint('✅ 지도 서비스 설정 완료 (학교 중심)');
    } catch (e) {
      debugPrint('❌ 지도 준비 오류: $e');
    }
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

  /// 🔥 건물 마커를 백그라운드에서 추가 (동기 버전으로 수정)
  // 🔥 건물 마커를 백그라운드에서 추가 (동기화 문제 해결)
void _addBuildingMarkersInBackground() {
    Future.microtask(() async {
      try {
        debugPrint('🏢 건물 마커 추가 시작...');
        
        // 🔥 첫 번째: 현재 데이터로 _allBuildings 초기화
        _allBuildings = _mapService!.getAllBuildings();
        debugPrint('📋 전체 건물 데이터 로드: ${_allBuildings.length}개');
        
        // 🔥 MapService에 콜백 등록 (서버 데이터 도착 시 자동 재실행)
        _mapService!.setCategorySelectedCallback(_handleServerDataUpdate);
        
        await _mapService!.addBuildingMarkers(_onBuildingMarkerTap);
        debugPrint('✅ 건물 마커 추가 완료');
      } catch (e) {
        debugPrint('❌ 건물 마커 추가 오류: $e');
      }
    });
  }

  // 🔥 서버 데이터 도착 시 _allBuildings 업데이트 및 카테고리 재매칭
void _handleServerDataUpdate(String category, List<String> buildingNames) {
  debugPrint('🔄 서버 데이터 도착 - _allBuildings 업데이트 중...');
  
  // 🔥 최신 서버 데이터로 _allBuildings 업데이트
  _allBuildings = _mapService!.getAllBuildings();
  debugPrint('📋 _allBuildings 업데이트 완료: ${_allBuildings.length}개');
  
  // 🔥 현재 선택된 카테고리가 있으면 재매칭
  if (_selectedCategory != null && _selectedCategory == category) {
    debugPrint('🔁 서버 데이터 도착 후 카테고리 재매칭: $_selectedCategory');
    
    // 🔥 Context가 없으면 잠시 대기
    if (_currentContext == null) {
      debugPrint('⏳ Context 대기 중... 잠시 후 카테고리 재매칭');
      Timer(const Duration(milliseconds: 500), () {
        if (_selectedCategory == category && _currentContext != null) {
          _showCategoryIconMarkers(buildingNames, category);
        }
      });
    } else {
      _showCategoryIconMarkers(buildingNames, category);
    }
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

  /// 🔥 내 위치로 이동 - 스마트 처리 및 권한 요청 방지
  Future<void> moveToMyLocation() async {
    try {
      debugPrint('📍 내 위치 버튼 클릭');
      
      // 🔥 1. 이미 실제 위치가 있으면 권한 요청 없이 즉시 이동
      if (_isRealLocationFound && _myLocation != null) {
        debugPrint('⚡ 실제 위치로 즉시 이동 (권한 요청 없음)');
        await _moveToLocationAndShow(_myLocation!);
        return;
      }

      // 🔥 2. 위치 요청 중이면 대기하지 않고 즉시 리턴
      if (_isLocationRequesting) {
        debugPrint('⏳ 위치 요청 중이므로 대기');
        return;
      }

      // 🔥 3. 위치가 없으면 사용자에게 알림만 (권한 요청 없음)
      debugPrint('❌ 실제 위치가 아직 없음 - 위치 서비스 확인 필요');
      _hasLocationPermissionError = true;
      notifyListeners();

    } catch (e) {
      debugPrint('❌ 내 위치 이동 오류: $e');
      _hasLocationPermissionError = true;
      notifyListeners();
    }
  }

  /// 🔥 위치 권한 재요청 - 수동으로만 실행
  Future<void> retryLocationPermission() async {
    try {
      debugPrint('🔄 위치 권한 수동 재요청...');
      _hasLocationPermissionError = false;
      _isLocationRequesting = true;
      notifyListeners();

      // 새로운 위치 요청
      await _locationManager?.refreshLocation();

      // 결과 확인
      if (_locationManager?.hasValidLocation == true) {
        final location = _locationManager!.currentLocation!;
        if (_locationManager!.isActualGPSLocation(location)) {
          _isRealLocationFound = true;
          _myLocation = location;
          await _moveToLocationAndShow(location);
        } else {
          debugPrint('⚠️ 여전히 fallback 위치만 획득됨');
          _hasLocationPermissionError = true;
        }
      } else {
        debugPrint('❌ 위치 권한 재요청 실패');
        _hasLocationPermissionError = true;
      }

    } catch (e) {
      debugPrint('❌ 위치 권한 재요청 오류: $e');
      _hasLocationPermissionError = true;
    } finally {
      _isLocationRequesting = false;
      notifyListeners();
    }
  }

  /// 실시간 위치 추적 시작
  void _startLocationTracking() {
    _locationManager?.startLocationTracking(
      onLocationChanged: (locationData) async {
        if (locationData.latitude != null && locationData.longitude != null && 
            _locationManager!.isActualGPSLocation(locationData)) {
          final latLng = NLatLng(locationData.latitude!, locationData.longitude!);
          
          // 내 위치 마커만 업데이트 (카메라는 이동하지 않음)
          await _mapService?.updateMyLocation(latLng, shouldMoveCamera: false);
          
          _hasMyLocationMarker = true;
          _isRealLocationFound = true;
          _myLocation = locationData;
          notifyListeners();
          
          debugPrint('📍 실시간 위치 업데이트: ${locationData.latitude}, ${locationData.longitude}');
        }
      },
    );
  }

  /// 위치로 이동하고 표시하는 공통 메서드
  Future<void> _moveToLocationAndShow(loc.LocationData locationData) async {
    try {
      final latLng = NLatLng(locationData.latitude!, locationData.longitude!);
      debugPrint('🎯 위치로 이동: ${latLng.latitude}, ${latLng.longitude}');

      // 부드러운 카메라 이동
      await _mapService?.moveCamera(latLng, zoom: 17);
      await Future.delayed(const Duration(milliseconds: 300));
      await _mapService?.showMyLocation(latLng, shouldMoveCamera: false);

      // 실시간 추적 시작
      _startLocationTracking();

      _hasMyLocationMarker = true;
      debugPrint('✅ 내 위치 이동 완료');
    } catch (e) {
      debugPrint('❌ 위치 이동 실패: $e');
    }
  }

  // 나머지 메서드들은 기존과 동일...
  Future<void> navigateFromCurrentLocation(Building targetBuilding) async {
    // 기존 코드와 동일
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

  Future<void> hideMyLocation() async {
    try {
      await _mapService?.hideMyLocation();
      _hasMyLocationMarker = false;
      debugPrint('내 위치 마커 숨김 완료');
      notifyListeners();
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
    clearCategorySelection();
    _locationManager?.stopLocationTracking();
    _locationManager?.removeListener(_onLocationUpdate);
    _mapService?.dispose();
    super.dispose();
  }
}