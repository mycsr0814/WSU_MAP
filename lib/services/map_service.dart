// lib/services/map_service.dart - 수정된 버전

import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/map/building_data.dart';
import 'package:flutter_application_1/services/building_api_service.dart';
import 'package:flutter_application_1/services/building_data_service.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_application_1/models/building.dart';

class MapService {
  NaverMapController? _mapController;
  NOverlayImage? _blueBuildingIcon;
  NMarker? _selectedMarker;
  
  // 건물 마커만 관리
  final List<NMarker> _buildingMarkers = [];
  bool _buildingMarkersVisible = true;

  // 경로 관련 오버레이 관리
  final List<String> _pathOverlayIds = [];
  final List<String> _routeMarkerIds = [];

  // 내 위치 마커 관리
  NMarker? _myLocationMarker;
  NCircleOverlay? _myLocationAccuracyCircle;

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
  // 🔥 첫 번째 우선순위: 서버에서 로딩된 데이터
  if (_isBuildingDataLoaded && _buildingData.isNotEmpty) {
    debugPrint('✅ 서버 건물 데이터 사용: ${_buildingData.length}개');
    return _buildingData.map((building) {
      final autoStatus = _getAutoOperatingStatus(building.baseStatus);
      return building.copyWith(baseStatus: autoStatus);
    }).toList();
  }
  
  // 🔥 두 번째 우선순위: BuildingDataService의 서버 데이터
  if (_buildingDataService.hasData) {
    debugPrint('✅ BuildingDataService 서버 데이터 사용: ${_buildingDataService.buildings.length}개');
    return _buildingDataService.buildings.map((building) {
      final autoStatus = _getAutoOperatingStatus(building.baseStatus);
      return building.copyWith(baseStatus: autoStatus);
    }).toList();
  }
  
  // 🔥 세 번째 우선순위: 정적 데이터 (fallback)
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
    
    // 🔥 BuildingApiService와 BuildingDataService 모두 시도
    List<Building> buildings = [];
    
    // 첫 번째 시도: BuildingApiService
    try {
      buildings = await BuildingApiService.getAllBuildings();
      debugPrint('✅ BuildingApiService에서 데이터 로딩 성공: ${buildings.length}개');
    } catch (e) {
      debugPrint('❌ BuildingApiService 실패: $e');
      
      // 두 번째 시도: BuildingDataService 새로고침
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
        debugPrint('🔄 서버 데이터 로딩 완료, 마커 즉시 업데이트...');
        Future.microtask(() => addBuildingMarkers(_onBuildingMarkerTap!));
      }
    } else {
      throw Exception('서버에서 건물 데이터를 가져올 수 없음');
    }
    
  } catch (e) {
    debugPrint('❌ 서버 건물 데이터 로딩 실패: $e');
    // 실패 시 정적 데이터 사용
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

  /// 내 위치 표시 및 카메라 이동 (안전한 버전) - 수정됨
  Future<void> showMyLocation(NLatLng location, {double? accuracy, bool shouldMoveCamera = true}) async {
    debugPrint('[MapService] showMyLocation 호출 - 위치: (${location.latitude}, ${location.longitude}), accuracy: $accuracy, moveCamera: $shouldMoveCamera');
    
    if (_mapController == null) {
      debugPrint('[MapService] showMyLocation: _mapController가 null입니다!');
      return;
    }
    
    try {
      // 1. 먼저 내 위치 마커 표시
      await _removeMyLocationMarker();
      await _addMyLocationCircle(location);
      
      // 2. 카메라 이동은 별도로 처리 (약간의 지연 후)
      if (shouldMoveCamera) {
        debugPrint('[MapService] showMyLocation: 카메라 이동 예약...');
        
        // 카메라 이동을 별도 타이머로 처리하여 메인 스레드 블로킹 방지
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
    }
  }

  /// 내 위치를 파란색 원으로 표시 (더 작은 크기)
  Future<void> _addMyLocationCircle(NLatLng location) async {
    debugPrint('[MapService] _addMyLocationCircle 호출 - 위치: (${location.latitude}, ${location.longitude})');
    
    try {
      final circleId = 'my_location_circle_${DateTime.now().millisecondsSinceEpoch}';
      _myLocationAccuracyCircle = NCircleOverlay(
        id: circleId,
        center: location,
        radius: 8, // 반지름을 8미터로 증가 (더 잘 보이도록)
        color: const Color(0xFF1E3A8A).withOpacity(0.7), // 투명도 추가
        outlineColor: Colors.white,
        outlineWidth: 2, // 테두리 두께 증가
      );
      
      await _mapController!.addOverlay(_myLocationAccuracyCircle!);
      debugPrint('[MapService] _addMyLocationCircle 완료');
    } catch (e) {
      debugPrint('[MapService] _addMyLocationCircle 오류: $e');
    }
  }

  /// 내 위치 마커 제거
  Future<void> _removeMyLocationMarker() async {
    debugPrint('[MapService] _removeMyLocationMarker 호출');
    
    try {
      if (_myLocationMarker != null) {
        await _mapController!.deleteOverlay(_myLocationMarker!.info);
        _myLocationMarker = null;
        debugPrint('[MapService] 기존 내 위치 마커 제거 완료');
      }
      
      if (_myLocationAccuracyCircle != null) {
        await _mapController!.deleteOverlay(_myLocationAccuracyCircle!.info);
        _myLocationAccuracyCircle = null;
        debugPrint('[MapService] 기존 내 위치 원형 마커 제거 완료');
      }
    } catch (e) {
      debugPrint('[MapService] _removeMyLocationMarker 오류(무시): $e');
    }
  }

  /// 내 위치 업데이트 (기존 마커 이동, 카메라 이동 제어) - 수정됨
  Future<void> updateMyLocation(NLatLng location, {bool shouldMoveCamera = false}) async {
    debugPrint('[MapService] updateMyLocation 호출 - 위치: (${location.latitude}, ${location.longitude}), moveCamera: $shouldMoveCamera');
    
    if (_mapController == null) {
      debugPrint('[MapService] updateMyLocation: _mapController가 null입니다!');
      return;
    }
    
    try {
      if (_myLocationAccuracyCircle != null) {
        // 기존 원형 마커의 위치만 업데이트
        _myLocationAccuracyCircle!.setCenter(location);
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
        // 원형 마커가 없으면 새로 생성
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
    
    // 🔥 서버 데이터가 없으면 즉시 로딩 시작
    if (!_isBuildingDataLoaded) {
      debugPrint('🚀 서버 데이터 즉시 로딩 시작...');
      _loadBuildingDataFromServer(); // 백그라운드 실행
    }
    
    final buildings = _getCurrentBuildingData();
    
    if (buildings.isEmpty) {
      debugPrint('❌ 건물 데이터가 없음 - 재시도 예약');
      // 2초 후 재시도
      Timer(const Duration(seconds: 2), () {
        if (_onBuildingMarkerTap != null) {
          addBuildingMarkers(_onBuildingMarkerTap!);
        }
      });
      return;
    }

    debugPrint('🏢 건물 마커 추가 시작: ${buildings.length}개');

    // 🔥 기존 마커가 있으면 안전하게 제거
    if (_buildingMarkers.isNotEmpty || _buildingMarkerIds.isNotEmpty) {
      await clearBuildingMarkers();
      // 마커 제거 후 잠시 대기
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // 🔥 새로운 마커들 추가
    for (final building in buildings) {
      final markerId = 'building_${building.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
      
      // 마커 생성
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

      // 마커 클릭 이벤트 등록
      marker.setOnTapListener((NMarker marker) => onTap(marker, building));

      try {
        // 지도에 마커 추가
        await _mapController!.addOverlay(marker);

        // 마커 저장
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

// 4. 서버 데이터 로딩 완료 후 마커 업데이트 스케줄링
void _scheduleMarkerUpdate() {
  if (_isBuildingDataLoaded) return; // 이미 로딩됨
  
  Timer.periodic(const Duration(seconds: 2), (timer) {
    if (_isBuildingDataLoaded) {
      timer.cancel();
      debugPrint('🔄 서버 데이터 로딩 완료, 마커 업데이트...');
      
      // 서버 데이터로 마커 재생성
      if (_onBuildingMarkerTap != null) {
        addBuildingMarkers(_onBuildingMarkerTap!);
      }
    }
  });
}

/// 🔥 안전한 건물 마커 숨기기 메서드
Future<void> hideAllBuildingMarkers() async {
  try {
    if (_mapController == null) return;
    
    debugPrint('모든 건물 마커 숨기기 시작...');
    
    // 🔥 실제 존재하는 마커만 제거
    final existingMarkerIds = Set<String>.from(_buildingMarkerIds);
    
    for (final markerId in existingMarkerIds) {
      try {
        final overlayInfo = NOverlayInfo(
          type: NOverlayType.marker,
          id: markerId,
        );
        await _mapController!.deleteOverlay(overlayInfo);
      } catch (e) {
        // 이미 제거된 마커는 무시 (로그 출력하지 않음)
        // debugPrint('건물 마커 숨기기 실패: $markerId - $e');
      }
    }
    
    // 🔥 상태만 업데이트 (실제 마커 객체는 유지)
    _buildingMarkersVisible = false;
    debugPrint('✅ 모든 건물 마커 숨기기 완료');
  } catch (e) {
    debugPrint('❌ 건물 마커 숨기기 실패: $e');
  }
}

  /// 모든 건물 마커 다시 표시하기
  Future<void> showAllBuildingMarkers() async {
    try {
      if (_mapController == null) return;
      
      debugPrint('모든 건물 마커 다시 표시 시작...');
      
      // 건물 마커들을 다시 생성하여 표시
      if (_onBuildingMarkerTap != null) {
        await addBuildingMarkers(_onBuildingMarkerTap!);
      }
      
      _buildingMarkersVisible = true;
      debugPrint('✅ 모든 건물 마커 다시 표시 완료');
    } catch (e) {
      debugPrint('❌ 건물 마커 표시 실패: $e');
    }
  }

  // 4. 통합된 검색 메서드들 수정
List<Building> searchBuildings(String query) {
  final buildings = _getCurrentBuildingData(); // 🔥 통합된 메서드 사용
  final lowercaseQuery = query.toLowerCase();
  
  return buildings.where((building) {
    return building.name.toLowerCase().contains(lowercaseQuery) ||
           building.info.toLowerCase().contains(lowercaseQuery) ||
           building.category.toLowerCase().contains(lowercaseQuery);
  }).toList();
}


  List<Building> getBuildingsByCategory(String category) {
  final buildings = _getCurrentBuildingData(); // 🔥 통합된 메서드 사용
  
  return buildings.where((building) {
    return building.category == category;
  }).toList();
}

List<Building> getAllBuildings() {
  return _getCurrentBuildingData(); // 🔥 통합된 메서드 사용
}

  // 건물 마커 표시/숨기기 토글
  Future<void> toggleBuildingMarkers() async {
    _buildingMarkersVisible = !_buildingMarkersVisible;
    
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

  // map_service.dart의 drawPath 메서드
  Future<void> drawPath(List<NLatLng> pathCoordinates) async {
    if (_mapController == null || pathCoordinates.isEmpty) return;
    
    try {
      // 기존 경로 제거
      await clearPath();
      
      // NPolylineOverlay 사용 (NPathOverlay 대신)
      final pathOverlayId = 'route_path_${DateTime.now().millisecondsSinceEpoch}';
      final pathOverlay = NPolylineOverlay(
        id: pathOverlayId,
        coords: pathCoordinates,
        color: const Color(0xFF1E3A8A),
        width: 6,
      );
      
      await _mapController!.addOverlay(pathOverlay);
      _pathOverlayIds.add(pathOverlayId);
      
      // 간단한 마커 추가 (Context 의존성 제거)
      await _addSimpleRouteMarkers(pathCoordinates);
      
    } catch (e) {
      debugPrint('경로 그리기 오류: $e');
    }
  }

  // Context 없이 간단한 마커 추가
  Future<void> _addSimpleRouteMarkers(List<NLatLng> path) async {
    if (path.length < 2) return;
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // 출발점 마커
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
      
      // 도착점 마커
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

  /// 카메라를 경로에 맞춰 이동 (안전한 버전)
  Future<void> moveCameraToPath(List<NLatLng> pathCoordinates) async {
    debugPrint('[MapService] moveCameraToPath 호출 - 좌표 개수: ${pathCoordinates.length}');
    if (_mapController == null) {
      debugPrint('[MapService] moveCameraToPath: _mapController가 null입니다!');
      return;
    }
    if (pathCoordinates.isEmpty) {
      debugPrint('[MapService] moveCameraToPath: pathCoordinates가 비어 있습니다!');
      return;
    }

    try {
      if (pathCoordinates.length == 1) {
        debugPrint('[MapService] moveCameraToPath: 단일 좌표 (${pathCoordinates.first.latitude}, ${pathCoordinates.first.longitude})');
        await moveCamera(pathCoordinates.first, zoom: 16);
      } else {
        // 여러 좌표인 경우 경계 계산
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

        debugPrint('[MapService] moveCameraToPath: 경계 - minLat: $minLat, maxLat: $maxLat, minLng: $minLng, maxLng: $maxLng');

        // 경계에 여유 공간 추가
        final latPadding = (maxLat - minLat) * 0.1;
        final lngPadding = (maxLng - minLng) * 0.1;

        final bounds = NLatLngBounds(
          southWest: NLatLng(minLat - latPadding, minLng - lngPadding),
          northEast: NLatLng(maxLat + latPadding, maxLng + lngPadding),
        );

        debugPrint('[MapService] moveCameraToPath: bounds - SW(${bounds.southWest.latitude}, ${bounds.southWest.longitude}), NE(${bounds.northEast.latitude}, ${bounds.northEast.longitude})');

        // 지연을 두고 카메라 이동
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

      debugPrint('[MapService] moveCameraToPath 설정 완료: ${pathCoordinates.length}개 좌표');
    } catch (e) {
      debugPrint('[MapService] moveCameraToPath 오류: $e');
    }
  }

  /// 경로 제거
  Future<void> clearPath() async {
    if (_mapController == null) return;
    
    try {
      // 폴리라인 오버레이 제거 (올바른 타입 사용)
      for (final overlayId in _pathOverlayIds) {
        try {
          await _mapController!.deleteOverlay(NOverlayInfo(
            type: NOverlayType.polylineOverlay, // pathOverlay 대신
            id: overlayId,
          ));
        } catch (e) {
          debugPrint('폴리라인 제거 오류 (무시): $overlayId - $e');
        }
      }
      _pathOverlayIds.clear();
      
      // 마커 제거
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

  // 5. 건물 데이터 새로고침 메서드 수정
Future<void> refreshBuildingData() async {
  _isBuildingDataLoaded = false;
  _buildingData.clear();
  await _loadBuildingDataFromServer();
  
  // 마커도 함께 업데이트
  if (_onBuildingMarkerTap != null) {
    await addBuildingMarkers(_onBuildingMarkerTap!);
  }
}

  // 현재 운영중인 건물만 필터링
  List<Building> getOperatingBuildings() {
    final allBuildings = getAllBuildings();
    return allBuildings.where((building) => building.baseStatus == '운영중' || building.baseStatus == '24시간').toList();
  }

  // 현재 운영종료된 건물만 필터링
  List<Building> getClosedBuildings() {
    final allBuildings = getAllBuildings();
    return allBuildings.where((building) => building.baseStatus == '운영종료' || building.baseStatus == '임시휴무').toList();
  }

  // MapService 정리
  void dispose() {      
    _cameraDelayTimer?.cancel();
    _buildingMarkers.clear();
    _buildingMarkerIds.clear();
    _pathOverlayIds.clear();
    _routeMarkerIds.clear();
    _myLocationMarker = null;
    _myLocationAccuracyCircle = null;
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