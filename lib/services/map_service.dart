// lib/services/map_service.dart - 오타 수정 및 context 문제 해결
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/map/building_data.dart';
import 'package:flutter_application_1/services/building_api_service.dart';
import 'package:flutter_application_1/services/building_data_service.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/models/category_marker_data.dart';

class MapService {
  NaverMapController? _mapController; // 🔥 오타 수정
  NOverlayImage? _blueBuildingIcon;
  NMarker? _selectedMarker;

  // 🔥 중복 실행 방지용 플래그 추가
  bool _isUpdatingMyLocation = false;

  BuildContext? _currentContext; // 🔥 현재 Context 저장

  // 🔥 카테고리 아이콘 마커들을 저장할 리스트
  final List<NMarker> _categoryMarkers = [];
  
  // 건물 마커만 관리
  final List<NMarker> _buildingMarkers = [];
  bool _buildingMarkersVisible = true;

  // 경로 관련 오버레이 관리
  final List<String> _pathOverlayIds = [];
  final List<String> _routeMarkerIds = [];

  // 🔥 내 위치 마커 관리 개선 - 중복 방지
  NCircleOverlay? _myLocationCircle;
  bool _hasMyLocationMarker = false;

  // BuildingDataService 인스턴스
  final BuildingDataService _buildingDataService = BuildingDataService();

  // Context 저장 (다국어 지원을 위해)
  BuildContext? _context;

  // 카메라 이동 관련 상태 관리
  bool _isCameraMoving = false;
  Timer? _cameraDelayTimer;

  // 건물 마커 ID들을 저장할 Set
  final Set<String> _buildingMarkerIds = {};

  // 마커 클릭 콜백 저장
  Function(NMarker, Building)? _onBuildingMarkerTap;

  // 🔥 건물 데이터 저장을 위한 변수 추가
  List<Building> _buildingData = [];
  bool _isBuildingDataLoaded = false;

  // Getters
  bool get buildingMarkersVisible => _buildingMarkersVisible;
  BuildContext? get context => _context;

  void setController(NaverMapController controller) {
    _mapController = controller;
    debugPrint('MapController 설정 완료');
  }

  /// 컨트롤러 반환 메서드 추가
  Future<NaverMapController?> getController() async {
    return _mapController;
  }

  void setContext(BuildContext context) {
    _context = context;
    debugPrint('MapService Context 설정 완료');
  }

  Future<void> loadMarkerIcons() async {
    try {
      _blueBuildingIcon = const NOverlayImage.fromAssetImage(
        'lib/asset/building_marker_blue.png'
      );
      
      debugPrint('마커 아이콘 로딩 완료');
    } catch (e) {
      debugPrint('마커 아이콘 로딩 실패 (기본 마커 사용): $e');
      _blueBuildingIcon = null;
    }
  }

  /// 🔥 전체 건물 데이터 가져오기 (동기 버전으로 수정)
  List<Building> getAllBuildings() {
    // 🔥 현재 로딩된 건물 데이터 반환
    return _getCurrentBuildingData();
  }

  /// 현재 시간 기준으로 운영상태 자동 결정
  String _getAutoOperatingStatus(String baseStatus) {
    // 특별 상태는 자동 변경하지 않음
    if (baseStatus == '24시간' || baseStatus == '임시휴무' || baseStatus == '휴무') {
      return baseStatus;
    }
    
    // 현재 시간 가져오기
    final now = DateTime.now();
    final currentHour = now.hour;
    
    // 09:00 ~ 18:00 (9시부터 18시까지) 운영중, 나머지는 운영종료
    if (currentHour >= 9 && currentHour < 18) {
      return '운영중';
    } else {
      return '운영종료';
    }
  }

  // 1. _getCurrentBuildingData 메서드를 완전히 수정
 List<Building> _getCurrentBuildingData() {
  // 1. 서버에서 로딩된 데이터가 있으면 그걸 우선 사용
  if (_isBuildingDataLoaded && _buildingData.isNotEmpty) {
    debugPrint('✅ 서버 건물 데이터 사용: ${_buildingData.length}개');
    return _buildingData.map((building) {
      final autoStatus = _getAutoOperatingStatus(building.baseStatus);
      return building.copyWith(baseStatus: autoStatus);
    }).toList();
  }

  // 2. BuildingDataService의 서버 데이터 사용
  if (_buildingDataService.hasData) {
    debugPrint('✅ BuildingDataService 서버 데이터 사용: ${_buildingDataService.buildings.length}개');
    return _buildingDataService.buildings.map((building) {
      final autoStatus = _getAutoOperatingStatus(building.baseStatus);
      return building.copyWith(baseStatus: autoStatus);
    }).toList();
  }

  // 3. 정말 서버 데이터가 없을 때만 fallback 사용
  debugPrint('⚠️ 정적 건물 데이터 사용 (fallback)');
  return _getStaticBuildingData().map((building) {
    final autoStatus = _getAutoOperatingStatus(building.baseStatus);
    return building.copyWith(baseStatus: autoStatus);
  }).toList();
}

  // 2. 서버 데이터 로딩을 더 적극적으로 수정
  Future<void> _loadBuildingDataFromServer() async {
  try {
    debugPrint('🔄 서버에서 건물 데이터 로딩 시작...');
    List<Building> buildings = [];
    try {
      buildings = await BuildingApiService.getAllBuildings();
      debugPrint('✅ BuildingApiService에서 데이터 로딩 성공: ${buildings.length}개');
    } catch (e) {
      debugPrint('❌ BuildingApiService 실패: $e');
      try {
        await _buildingDataService.refresh();
        if (_buildingDataService.hasData) {
          buildings = _buildingDataService.buildings;
          debugPrint('✅ BuildingDataService에서 데이터 로딩 성공: ${buildings.length}개');
        }
      } catch (e2) {
        debugPrint('❌ BuildingDataService도 실패: $e2');
      }
    }

    if (buildings.isNotEmpty) {
      _buildingData = buildings;
      _isBuildingDataLoaded = true;
      debugPrint('✅ 서버 건물 데이터 로딩 완료: ${buildings.length}개');
      
      // 🔥 마커 즉시 업데이트
      if (_onBuildingMarkerTap != null) {
        debugPrint('🔄 서버 데이터 도착 후 마커 즉시 업데이트...');
        Future.microtask(() => addBuildingMarkers(_onBuildingMarkerTap!));
      }
      
      // 🔥 서버 데이터 도착 후 카테고리 매칭 재실행 (조건 완화)
      if (_onCategorySelected != null && _lastSelectedCategory != null) {
        debugPrint('🔁 서버 데이터 도착 후 카테고리 매칭 재실행!');
        debugPrint('🔁 저장된 카테고리: $_lastSelectedCategory');
        debugPrint('🔁 저장된 건물 이름들: $_lastCategoryBuildingNames');
        
        // 🔥 buildingNames가 null이어도 빈 배열로 처리
        final buildingNames = _lastCategoryBuildingNames ?? [];
        Future.microtask(() => _onCategorySelected!(_lastSelectedCategory!, buildingNames));
      } else {
        debugPrint('⚠️ 콜백 실행 조건 미충족:');
        debugPrint('  - _onCategorySelected: ${_onCategorySelected != null}');
        debugPrint('  - _lastSelectedCategory: $_lastSelectedCategory');
        debugPrint('  - _lastCategoryBuildingNames: $_lastCategoryBuildingNames');
      }
    } else {
      // 정말 데이터가 없을 때만 fallback!
      _buildingData = _getStaticBuildingData();
      _isBuildingDataLoaded = true;
      debugPrint('⚠️ 정적 데이터로 fallback');
    }
  } catch (e) {
    debugPrint('❌ 서버 건물 데이터 로딩 실패: $e');
    _buildingData = _getStaticBuildingData();
    _isBuildingDataLoaded = true;
    debugPrint('⚠️ 정적 데이터로 fallback');
  }
}

  /// 정적 건물 데이터 (fallback용) - 자동 운영상태 지원
  List<Building> _getStaticBuildingData() {
    return [
      // 운영종료 테스트용 건물 추가
      Building(
        name: '24시간 편의점',
        info: '24시간 운영하는 편의점',
        lat: 36.337500,
        lng: 127.446000,
        category: '편의시설',
        baseStatus: '24시간', // 특별 상태 (자동 변경되지 않음)
        hours: '24시간',
        phone: '042-821-5678',
        imageUrl: null,
        description: '24시간 편의점',
      ),
    ];
  }

  /// 건물 마커 아이콘 가져오기
  NOverlayImage? _getBuildingMarkerIcon(Building building) {
    return _blueBuildingIcon;
  }

  /// 현지화된 건물 이름 가져오기
  String _getLocalizedBuildingName(Building building) {
    // 간단한 구현 - 실제로는 다국어 처리 로직 필요
    return building.name;
  }

  /// 안전한 카메라 이동 (메인 스레드 블로킹 방지) - 수정됨
  Future<void> moveCamera(NLatLng location, {double zoom = 15}) async {
    debugPrint('[MapService] moveCamera 호출 - 위치: (${location.latitude}, ${location.longitude}), zoom: $zoom');
    
    if (_mapController == null) {
      debugPrint('[MapService] moveCamera: _mapController가 null입니다!');
      return;
    }

    // 카메라 이동 중복 방지
    if (_isCameraMoving) {
      debugPrint('[MapService] moveCamera: 이미 카메라 이동 중...');
      return;
    }

    _isCameraMoving = true;

    try {
      // 메인 스레드 보호를 위한 지연
      await Future.delayed(const Duration(milliseconds: 200));
      
      final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
        target: location,
        zoom: zoom,
      );
      
      // 타임아웃을 적용하여 안전하게 카메라 이동
      await _mapController!.updateCamera(cameraUpdate).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('[MapService] moveCamera: 카메라 이동 타임아웃');
          throw TimeoutException('카메라 이동 타임아웃', const Duration(seconds: 5));
        },
      );
      
      debugPrint('[MapService] moveCamera 완료: ${location.latitude}, ${location.longitude}');
    } catch (e) {
      debugPrint('[MapService] moveCamera 오류: $e');
      
      // 오류 발생 시 재시도 (한 번만)
      try {
        await Future.delayed(const Duration(milliseconds: 500));
        final retryUpdate = NCameraUpdate.scrollAndZoomTo(
          target: location,
          zoom: zoom,
        );
        await _mapController!.updateCamera(retryUpdate).timeout(
          const Duration(seconds: 3),
        );
        debugPrint('[MapService] moveCamera 재시도 성공');
      } catch (retryError) {
        debugPrint('[MapService] moveCamera 재시도 실패: $retryError');
      }
    } finally {
      _isCameraMoving = false;
    }
  }

  /// 🔥 내 위치 표시 및 카메라 이동 (중복 방지 완전 해결)
  Future<void> showMyLocation(NLatLng location, {double? accuracy, bool shouldMoveCamera = true}) async {
    debugPrint('[MapService] showMyLocation 호출 - 위치: (${location.latitude}, ${location.longitude}), accuracy: $accuracy, moveCamera: $shouldMoveCamera');
    
    if (_mapController == null) {
      debugPrint('[MapService] showMyLocation: _mapController가 null입니다!');
      return;
    }

    // 🔥 중복 실행 방지
    if (_isUpdatingMyLocation) {
      debugPrint('[MapService] showMyLocation: 중복 실행 방지로 리턴');
      return;
    }
    _isUpdatingMyLocation = true;

    try {
      // 1. 기존 내 위치 마커 안전하게 제거
      await _removeMyLocationMarker();
      
      // 2. 새로운 내 위치 원형 마커 추가
      await _addMyLocationCircle(location);
      
      // 3. 상태 업데이트
      _hasMyLocationMarker = true;
      
      // 4. 카메라 이동은 별도로 처리 (약간의 지연 후)
      if (shouldMoveCamera) {
        debugPrint('[MapService] showMyLocation: 카메라 이동 예약...');
        _cameraDelayTimer?.cancel();
        _cameraDelayTimer = Timer(const Duration(milliseconds: 800), () async {
          try {
            debugPrint('[MapService] showMyLocation: 지연된 카메라 이동 시작');
            await moveCamera(location, zoom: 16);
            debugPrint('[MapService] showMyLocation: 지연된 카메라 이동 완료');
          } catch (e) {
            debugPrint('[MapService] showMyLocation: 지연된 카메라 이동 오류: $e');
          }
        });
      }
      
      debugPrint('[MapService] showMyLocation 마커 표시 완료');
    } catch (e) {
      debugPrint('[MapService] showMyLocation 오류: $e');
    } finally {
      _isUpdatingMyLocation = false;
    }
  }

  /// 🔥 내 위치를 파란색 원으로 표시 (중복 방지)
  Future<void> _addMyLocationCircle(NLatLng location) async {
    debugPrint('[MapService] _addMyLocationCircle 호출 - 위치: (${location.latitude}, ${location.longitude})');
    
    try {
      // 기존 원형 마커가 있으면 먼저 제거
      if (_myLocationCircle != null) {
        try {
          await _mapController!.deleteOverlay(_myLocationCircle!.info); // 🔥 오타 수정
          debugPrint('[MapService] 기존 내 위치 원형 마커 제거');
        } catch (e) {
          debugPrint('[MapService] 기존 마커 제거 실패 (무시): $e');
        }
      }
      
      // 새로운 원형 마커 생성
      final circleId = 'my_location_circle_${DateTime.now().millisecondsSinceEpoch}';
      _myLocationCircle = NCircleOverlay(
        id: circleId,
        center: location,
        radius: 8,
        color: const Color(0xFF1E3A8A).withOpacity(0.7),
        outlineColor: Colors.white,
        outlineWidth: 2,
      );
      await _mapController!.addOverlay(_myLocationCircle!); // 🔥 오타 수정
      debugPrint('[MapService] _addMyLocationCircle 완료');
    } catch (e) {
      debugPrint('[MapService] _addMyLocationCircle 오류: $e');
    }
  }

  /// 🔥 내 위치 마커 제거 (안전한 버전)
  Future<void> _removeMyLocationMarker() async {
    debugPrint('[MapService] _removeMyLocationMarker 호출');
    try {
      if (_myLocationCircle != null) {
        await _mapController!.deleteOverlay(_myLocationCircle!.info); // 🔥 오타 수정
        _myLocationCircle = null;
        _hasMyLocationMarker = false;
        debugPrint('[MapService] 기존 내 위치 원형 마커 제거 완료');
      }
    } catch (e) {
      debugPrint('[MapService] _removeMyLocationMarker 오류(무시): $e');
      _myLocationCircle = null;
      _hasMyLocationMarker = false;
    }
  }

  /// 🔥 내 위치 업데이트 (중복 마커 완전 방지)
  Future<void> updateMyLocation(NLatLng location, {bool shouldMoveCamera = false}) async {
    debugPrint('[MapService] updateMyLocation 호출 - 위치: (${location.latitude}, ${location.longitude}), moveCamera: $shouldMoveCamera');
    
    if (_mapController == null) {
      debugPrint('[MapService] updateMyLocation: _mapController가 null입니다!');
      return;
    }
    
    try {
      if (_myLocationCircle != null && _hasMyLocationMarker) {
        // 🔥 기존 원형 마커의 위치만 업데이트 (중복 생성 방지)
        _myLocationCircle!.setCenter(location);
        debugPrint('[MapService] updateMyLocation: 기존 원형 마커 위치만 이동');
        
        // 필요한 경우에만 카메라 이동 (지연 적용)
        if (shouldMoveCamera) {
          _cameraDelayTimer?.cancel();
          _cameraDelayTimer = Timer(const Duration(milliseconds: 500), () async {
            try {
              await moveCamera(location, zoom: 16);
              debugPrint('[MapService] updateMyLocation: 지연된 카메라 이동 완료');
            } catch (e) {
              debugPrint('[MapService] updateMyLocation: 지연된 카메라 이동 오류: $e');
            }
          });
        }
      } else {
        // 🔥 원형 마커가 없으면 새로 생성
        debugPrint('[MapService] updateMyLocation: 원형 마커 없음, showMyLocation 호출');
        await showMyLocation(location, shouldMoveCamera: shouldMoveCamera);
      }
    } catch (e) {
      debugPrint('[MapService] updateMyLocation 오류: $e');
      // 오류 발생 시 새로 생성
      await showMyLocation(location, shouldMoveCamera: shouldMoveCamera);
    }
  }

  /// 내 위치 숨기기
  Future<void> hideMyLocation() async {
    await _removeMyLocationMarker();
  }

  /// 🔥 카테고리 아이콘 마커들 표시
  Future<void> showCategoryIconMarkers(List<CategoryMarkerData> categoryData) async {
    try {
      debugPrint('카테고리 아이콘 마커 표시 시작: ${categoryData.length}개');
      
      // 🔥 Context 재확인
      if (_context == null) {
        debugPrint('❌ Context가 없어서 카테고리 마커 표시 불가');
        return;
      }
      
      // 기존 카테고리 마커들 제거
      await clearCategoryMarkers();

      for (CategoryMarkerData data in categoryData) {
        try {
          debugPrint('🎨 카테고리 마커 생성 중: ${data.buildingName} (${data.category})');
          
          // 카테고리 아이콘으로 마커 생성
          final iconImage = await _createCategoryIconMarker(data.icon, data.category);
          
          final marker = NMarker(
            id: 'category_${data.category}_${data.buildingName}_${DateTime.now().millisecondsSinceEpoch}',
            position: NLatLng(data.location.x, data.location.y),
            icon: iconImage,
            size: const Size(40, 40),
          );

          // 마커 클릭 이벤트
          marker.setOnTapListener((marker) {
            debugPrint('카테고리 마커 클릭: ${data.buildingName} (${data.category})');
          });

          // 지도에 마커 추가
          if (_mapController != null) {
            await _mapController!.addOverlay(marker);
            _categoryMarkers.add(marker);
            debugPrint('✅ 카테고리 마커 추가 완료: ${data.buildingName}');
          }
          
        } catch (e) {
          debugPrint('❌ 개별 카테고리 마커 생성 실패: ${data.buildingName} - $e');
          continue; // 실패한 마커는 건너뛰고 계속
        }
      }

      debugPrint('✅ 카테고리 아이콘 마커 표시 완료: ${_categoryMarkers.length}개');
    } catch (e) {
      debugPrint('🚨 카테고리 마커 표시 오류: $e');
    }
  }

  /// 🔥 카테고리 아이콘 마커 생성
  Future<NOverlayImage> _createCategoryIconMarker(IconData iconData, String category) async {
    try {
      debugPrint('🎨 카테고리 아이콘 생성 시작: $category');
      
      // 🔥 Context 재확인
      if (_context == null) {
        debugPrint('❌ Context가 설정되지 않았습니다 - 기본 에셋 아이콘 사용');
        // 기본 에셋 아이콘으로 fallback
        return const NOverlayImage.fromAssetImage('lib/asset/building_marker_blue.png');
      }

      debugPrint('✅ Context 확인됨, 커스텀 아이콘 생성 중...');

      // 카테고리별 색상 지정
      Color backgroundColor = _getCategoryColor(category);
      
      // 아이콘 이미지 생성 (원형 배경 + 아이콘)
      final iconImage = _createIconMarkerImage(
        iconData: iconData,
        backgroundColor: backgroundColor,
        iconColor: Colors.white,
        size: 40,
      );
      
      final overlayImage = await NOverlayImage.fromWidget(
        widget: iconImage,
        size: const Size(40, 40),
        context: _context!,
      );
      
      debugPrint('✅ 카테고리 아이콘 생성 완료: $category');
      return overlayImage;
      
    } catch (e) {
      debugPrint('❌ 카테고리 아이콘 생성 오류: $e');
      
      // 🔥 오류 발생 시 기본 아이콘으로 fallback
      try {
        return const NOverlayImage.fromAssetImage('lib/asset/building_marker_blue.png');
      } catch (e2) {
        debugPrint('❌ 기본 아이콘도 로딩 실패: $e2');
        // 최후의 수단: NOverlayImage.fromAssetImage의 기본 마커
        rethrow;
      }
    }
  }

  /// 🔥 아이콘 마커 이미지 위젯 생성
  Widget _createIconMarkerImage({
    required IconData iconData,
    required Color backgroundColor,
    required Color iconColor,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: size * 0.5,
      ),
    );
  }

  /// 🔥 카테고리별 색상 지정
  Color _getCategoryColor(String category) {
    switch (category) {
      case '카페':
        return const Color(0xFF8B4513); // 갈색
      case '식당':
        return const Color(0xFFFF6B35); // 오렌지
      case '편의점':
        return const Color(0xFF4CAF50); // 초록
      case '자판기':
        return const Color(0xFF2196F3); // 파랑
      case '화장실':
        return const Color(0xFF607D8B); // 회색
      case '프린터':
        return const Color(0xFF9C27B0); // 보라
      case '복사기':
        return const Color(0xFF9C27B0); // 보라
      case 'ATM':
      case '은행(atm)':
        return const Color(0xFF4CAF50); // 초록
      case '의료':
      case '보건소':
        return const Color(0xFFF44336); // 빨강
      case '도서관':
        return const Color(0xFF3F51B5); // 남색
      case '체육관':
      case '헬스장':
        return const Color(0xFFFF9800); // 주황
      case '주차장':
        return const Color(0xFF795548); // 갈색
      case '라운지':
        return const Color(0xFFE91E63); // 핑크
      case '소화기':
        return const Color(0xFFF44336); // 빨강
      case '정수기':
        return const Color(0xFF00BCD4); // 청록
      case '서점':
        return const Color(0xFF673AB7); // 보라
      case '우체국':
        return const Color(0xFF4CAF50); // 초록
      default:
        return const Color(0xFF757575); // 기본 회색
    }
  }

  /// 🔥 카테고리 마커들 제거
  Future<void> clearCategoryMarkers() async {
    try {
      debugPrint('카테고리 마커 제거 시작: ${_categoryMarkers.length}개');
      
      for (NMarker marker in _categoryMarkers) {
        await _mapController?.deleteOverlay(marker.info);
      }
      
      _categoryMarkers.clear();
      debugPrint('✅ 카테고리 마커 제거 완료');
    } catch (e) {
      debugPrint('🚨 카테고리 마커 제거 오류: $e');
    }
  }

  /// 🔥 모든 건물 마커 숨기기 (수정됨)
  Future<void> hideAllBuildingMarkers() async {
    debugPrint('모든 건물 마커 숨기기 시작: ${_buildingMarkers.length}개');
    
    for (NMarker marker in _buildingMarkers) {
      marker.setIsVisible(false);
    }
    
    debugPrint('✅ 모든 건물 마커 숨기기 완료');
  }

  /// 🔥 모든 건물 마커 다시 표시 (수정됨)
  Future<void> showAllBuildingMarkers(List<Building> buildings) async {
    debugPrint('모든 건물 마커 다시 표시 시작: ${_buildingMarkers.length}개');
    
    // 기존 건물 마커들 다시 표시
    for (NMarker marker in _buildingMarkers) {
      marker.setIsVisible(true);
    }
    
    debugPrint('✅ 모든 건물 마커 다시 표시 완료');
  }

  /// 🔥 안전한 건물 마커 제거 메서드
  Future<void> clearBuildingMarkers() async {
    if (_mapController == null) return;
    
    try {
      debugPrint('기존 건물 마커 제거 시작: ${_buildingMarkers.length}개');
      
      // 🔥 Set을 사용해서 중복 제거 방지
      final markersToRemove = Set<NMarker>.from(_buildingMarkers);
      
      for (final marker in markersToRemove) {
        try {
          // 🔥 마커가 실제로 지도에 있는지 확인하고 제거
          await _mapController!.deleteOverlay(marker.info);
        } catch (e) {
          // 이미 제거된 마커는 무시 (로그 출력하지 않음)
          // debugPrint('마커 제거 오류 (무시): ${marker.info.id} - $e');
        }
      }
      
      // 🔥 리스트와 Set 모두 정리
      _buildingMarkers.clear();
      _buildingMarkerIds.clear();
      
      debugPrint('건물 마커 제거 완료');
    } catch (e) {
      debugPrint('건물 마커 제거 중 오류: $e');
      // 오류 발생 시에도 리스트는 정리
      _buildingMarkers.clear();
      _buildingMarkerIds.clear();
    }
  }

  /// 🔥 중복 방지가 적용된 addBuildingMarkers 메서드
 Future<void> addBuildingMarkers(Function(NMarker, Building) onTap) async {
  try {
    if (_mapController == null) {
      debugPrint('❌ 지도 컨트롤러가 없음');
      return;
    }

    _onBuildingMarkerTap = onTap;

    // 서버 데이터가 없으면 즉시 로딩 시작 (비동기)
    if (!_isBuildingDataLoaded) {
      debugPrint('🚀 서버 데이터 즉시 로딩 시작...');
      _loadBuildingDataFromServer(); // 백그라운드 실행
    }

    final buildings = _getCurrentBuildingData();

    if (buildings.isEmpty) {
      debugPrint('❌ 건물 데이터가 없음 - 재시도 예약');
      Timer(const Duration(seconds: 2), () {
        if (_onBuildingMarkerTap != null) {
          addBuildingMarkers(_onBuildingMarkerTap!);
        }
      });
      return;
    }

    debugPrint('🏢 건물 마커 추가 시작: ${buildings.length}개');

    // 기존 마커가 있으면 안전하게 제거
    if (_buildingMarkers.isNotEmpty || _buildingMarkerIds.isNotEmpty) {
      await clearBuildingMarkers();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    for (final building in buildings) {
      final markerId = 'building_${building.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
      final marker = NMarker(
        id: markerId,
        position: NLatLng(building.lat, building.lng),
        icon: _getBuildingMarkerIcon(building),
        caption: NOverlayCaption(
          text: '',
          color: Colors.blue,
          textSize: 12,
        ),
      );
      marker.setOnTapListener((NMarker marker) => onTap(marker, building));
      try {
        await _mapController!.addOverlay(marker);
        _buildingMarkers.add(marker);
        _buildingMarkerIds.add(markerId);
        await Future.delayed(const Duration(milliseconds: 10));
      } catch (e) {
        debugPrint('개별 마커 추가 실패: $markerId - $e');
      }
    }

    _buildingMarkersVisible = true;
    debugPrint('✅ 건물 마커 추가 완료: ${_buildingMarkers.length}개');
  } catch (e) {
    debugPrint('❌ 건물 마커 추가 실패: $e');
  }
}

  // 나머지 메서드들은 기존과 동일하게 유지
  List<Building> searchBuildings(String query) {
    final buildings = _getCurrentBuildingData();
    final lowercaseQuery = query.toLowerCase();
    
    return buildings.where((building) {
      return building.name.toLowerCase().contains(lowercaseQuery) ||
             building.info.toLowerCase().contains(lowercaseQuery) ||
             building.category.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  List<Building> getBuildingsByCategory(String category) {
    final buildings = _getCurrentBuildingData();
    
    return buildings.where((building) {
      return building.category == category;
    }).toList();
  }

  // 건물 마커 표시/숨기기 토글
  Future<void> toggleBuildingMarkers() async {
    _buildingMarkersVisible = !_buildingMarkersVisible; // 🔥 오타 수정
    
    if (_buildingMarkersVisible) {
      // 마커 다시 표시
      for (final marker in _buildingMarkers) {
        try {
          await _mapController?.addOverlay(marker);
        } catch (e) {
          debugPrint('마커 표시 오류: ${marker.info.id} - $e');
        }
      }
      debugPrint('건물 마커 표시됨');
    } else {
      // 마커 숨기기
      for (final marker in _buildingMarkers) {
        try {
          await _mapController?.deleteOverlay(marker.info);
        } catch (e) {
          debugPrint('마커 숨기기 오류: ${marker.info.id} - $e');
        }
      }
      debugPrint('건물 마커 숨겨짐');
    }
  }

  // 경로 관련 메서드들 (기존과 동일)
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

  Future<void> _addSimpleRouteMarkers(List<NLatLng> path) async {
    if (path.length < 2) return;
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final startMarkerId = 'route_start_$timestamp';
      final startMarker = NMarker(
        id: startMarkerId,
        position: path.first,
        caption: NOverlayCaption(
          text: '출발',
          color: Colors.white,
          haloColor: const Color(0xFF10B981),
          textSize: 12,
        ),
      );
      
      final endMarkerId = 'route_end_$timestamp';
      final endMarker = NMarker(
        id: endMarkerId,
        position: path.last,
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
      
    } catch (e) {
      debugPrint('경로 마커 추가 오류: $e');
    }
  }

  Future<void> moveCameraToPath(List<NLatLng> pathCoordinates) async {
    debugPrint('[MapService] moveCameraToPath 호출 - 좌표 개수: ${pathCoordinates.length}');
    if (_mapController == null || pathCoordinates.isEmpty) return;

    try {
      if (pathCoordinates.length == 1) {
        await moveCamera(pathCoordinates.first, zoom: 16);
      } else {
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

        _cameraDelayTimer?.cancel();
        _cameraDelayTimer = Timer(const Duration(milliseconds: 500), () async {
          try {
            await _mapController!.updateCamera(
              NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(50)),
            ).timeout(const Duration(seconds: 5));
            debugPrint('[MapService] moveCameraToPath 지연된 이동 완료');
          } catch (e) {
            debugPrint('[MapService] moveCameraToPath 지연된 이동 오류: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('[MapService] moveCameraToPath 오류: $e');
    }
  }

  Future<void> clearPath() async {
    if (_mapController == null) return;
    
    try {
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

  Future<void> refreshBuildingData() async {
    _isBuildingDataLoaded = false;
    _buildingData.clear();
    await _loadBuildingDataFromServer();
    
    if (_onBuildingMarkerTap != null) {
      await addBuildingMarkers(_onBuildingMarkerTap!);
    }
  }

  // 🔥 추가: 카테고리 매칭 콜백 및 상태 저장
  void Function(String, List<String>)? _onCategorySelected;
  String? _lastSelectedCategory;
  List<String>? _lastCategoryBuildingNames;

  // 카테고리 매칭 콜백 등록 함수
  void setCategorySelectedCallback(void Function(String, List<String>) callback) {
    _onCategorySelected = callback;
  }

  // 카테고리 선택 시 정보 저장 (컨트롤러/뷰모델에서 호출)
  void saveLastCategorySelection(String category, List<String> buildingNames) {
    _lastSelectedCategory = category;
    _lastCategoryBuildingNames = buildingNames;
  }

  List<Building> getOperatingBuildings() {
    final allBuildings = getAllBuildings();
    return allBuildings.where((building) => building.baseStatus == '운영중' || building.baseStatus == '24시간').toList();
  }

  List<Building> getClosedBuildings() {
    final allBuildings = getAllBuildings();
    return allBuildings.where((building) => building.baseStatus == '운영종료' || building.baseStatus == '임시휴무').toList();
  }

  void dispose() {      
    _cameraDelayTimer?.cancel();
    _buildingMarkers.clear();
    _buildingMarkerIds.clear();
    _pathOverlayIds.clear();
    _routeMarkerIds.clear();
    _categoryMarkers.clear();
    _myLocationCircle = null;
    _hasMyLocationMarker = false;
    _onBuildingMarkerTap = null;
    debugPrint('MapService 정리 완료');
  }

  /// 선택된 건물 마커 강조
  Future<void> highlightBuildingMarker(NMarker marker) async {
    await resetAllBuildingMarkers();

    marker.setIcon(const NOverlayImage.fromAssetImage('lib/asset/building_marker_blue.png'));
    marker.setCaption(NOverlayCaption(
      text: '', // 건물이름과 별 없이 빈 문자열
      color: Colors.deepOrange, // 색상은 원하는 대로
      textSize: 16,
      haloColor: Colors.white,
    ));
    marker.setSize(const Size(110,110));
    _selectedMarker = marker;
  }

  /// 모든 건물 마커 스타일 초기화
  Future<void> resetAllBuildingMarkers() async {
    for (final marker in _buildingMarkers) {
      marker.setIcon(_blueBuildingIcon);
      marker.setCaption(NOverlayCaption(
        text: '', // 항상 빈 문자열
        color: Colors.blue,
        textSize: 12,
        haloColor: Colors.white,
      ));
      marker.setSize(const Size(40, 40));
    }
    _selectedMarker = null;
  }
}