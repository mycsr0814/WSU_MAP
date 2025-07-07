// lib/services/map_service.dart - 내 위치 이동 문제 수정

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/map/building_data.dart';
import 'package:flutter_application_1/services/building_data_service.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_application_1/models/building.dart';

class MapService {
  NaverMapController? _mapController;
  NOverlayImage? _blueBuildingIcon;
  
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

  // Getters
  bool get buildingMarkersVisible => _buildingMarkersVisible;

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
      _blueBuildingIcon = NOverlayImage.fromAssetImage(
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

  /// 현재 언어로 건물 데이터 가져오기 (운영상태 자동 적용)
  List<Building> _getCurrentBuildingData() {
    List<Building> buildings;
    
    if (_context != null) {
      try {
        buildings = BuildingDataProvider.getBuildingData(_context!);
      } catch (e) {
        debugPrint('다국어 건물 데이터 로딩 실패, fallback 사용: $e');
        buildings = _getStaticBuildingData();
      }
    } else {
      buildings = _getStaticBuildingData(); // fallback
    }
    
    // 모든 건물에 자동 운영상태 적용
    return buildings.map((building) {
      final autoStatus = _getAutoOperatingStatus(building.baseStatus);
      return building.copyWith(baseStatus: autoStatus);
    }).toList();
  }

  /// 정적 건물 데이터 (fallback용) - 자동 운영상태 지원
  List<Building> _getStaticBuildingData() {
    return [
      Building(
        name: '우송도서관(W1)',
        info: 'B2F\t주차장\nB1F\t소강당, 기관실, 전기실, 주차장\n1F\t취업지원센터(630-9976),대출실, 정보라운지\n2F\t일반열람실, 단체학습실\n3F\t일반열람실\n4F\t문학도서/서양도서',
        lat: 36.338133,
        lng: 127.446423,
        category: '교육시설',
        baseStatus: '운영중', // 기본 상태는 운영중
        hours: '09:00 - 18:00',
        phone: '042-821-5678',
        imageUrl: 'lib/resource/ws1.jpg',
        description: '우송대학교 중앙도서관',
      ),
      Building(
        name: '솔카페',
        info: '1F\t식당\n2F\t카페',
        lat: 36.337923,
        lng: 127.445895,
        category: '카페',
        baseStatus: '운영중', // 기본 상태는 운영중
        hours: '09:00 - 18:00',
        phone: '042-821-5678',
        imageUrl: 'lib/resource/solpark.jpg',
        description: '캠퍼스 내 카페',
      ),
      Building(
        name: '청운1숙',
        info: '1F\t실습실\n2F\t학생식당\n2F\t청운1숙(여)(629-6542)\n2F\t생활관\n3~5F\t생활관',
        lat: 36.338490,
        lng: 127.447739,
        category: '기숙사',
        baseStatus: '운영중', // 기본 상태는 운영중
        hours: '09:00 - 18:00',
        phone: '042-821-5678',
        imageUrl: 'lib/resource/1suk.jpg',
        description: '여학생 기숙사',
      ),
      Building(
        name: '산학협력단(W2)',
        info: '1F\t산학협력단\n2F\t건축공학전공(630-9720)\n3F\t우송대 융합기술연구소, 산학연총괄기업지원센터\n4F\t기업부설연구소, LG CNS강의실, 철도디젯아카데미 강의실',
        lat: 36.339574,
        lng: 127.447216,
        category: '교육시설',
        baseStatus: '운영중', // 기본 상태는 운영중
        hours: '09:00 - 18:00',
        phone: '042-821-5678',
        imageUrl: 'lib/resource/ws2.jpg',
        description: '산학협력 및 연구시설',
      ),
      Building(
        name: '학군단(W2-1)',
        info: '\t학군단(630-4601)',
        lat: 36.339525,
        lng: 127.447818,
        category: '군사시설',
        baseStatus: '운영중', // 기본 상태는 운영중
        hours: '09:00 - 18:00',
        phone: '042-821-5678',
        imageUrl: 'lib/resource/ws2-1.jpg',
        description: '학군단 시설',
      ),
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
      Building(
        name: '임시휴무 시설',
        info: '현재 임시휴무 중인 시설',
        lat: 36.337000,
        lng: 127.446500,
        category: '기타',
        baseStatus: '임시휴무', // 특별 상태 (자동 변경되지 않음)
        hours: '임시휴무',
        phone: '042-821-5678',
        imageUrl: null,
        description: '임시휴무 중인 시설',
      ),
    ];
  }

  /// 카메라 이동 (단일 좌표) - 수정됨
  Future<void> moveCamera(NLatLng location, {double zoom = 15}) async {
    debugPrint('[MapService] moveCamera 호출 - 위치: (${location.latitude}, ${location.longitude}), zoom: $zoom');
    
    if (_mapController == null) {
      debugPrint('[MapService] moveCamera: _mapController가 null입니다!');
      return;
    }

    try {
      final cameraUpdate = NCameraUpdate.scrollAndZoomTo(
        target: location,
        zoom: zoom,
      );
      
      await _mapController!.updateCamera(cameraUpdate);
      debugPrint('[MapService] moveCamera 완료: ${location.latitude}, ${location.longitude}');
    } catch (e) {
      debugPrint('[MapService] moveCamera 오류: $e');
    }
  }

  /// 내 위치 표시 및 카메라 이동 (파란색 원으로) - 수정됨
 Future<void> showMyLocation(NLatLng location, {double? accuracy, bool shouldMoveCamera = true}) async {
  debugPrint('[MapService] showMyLocation 호출 - 위치: (${location.latitude}, ${location.longitude}), accuracy: $accuracy, moveCamera: $shouldMoveCamera');
  
  if (_mapController == null) {
    debugPrint('[MapService] showMyLocation: _mapController가 null입니다!');
    return;
  }
  
  try {
    // 기존 마커 제거
    await _removeMyLocationMarker();
    
    // 새 위치 마커 추가
    await _addMyLocationCircle(location);
    
    // 카메라를 내 위치로 이동 (옵션)
    if (shouldMoveCamera) {
      debugPrint('[MapService] showMyLocation: 카메라 이동 시작');
      await moveCamera(location, zoom: 16);  // 이제 정상 작동
      debugPrint('[MapService] showMyLocation: 카메라 이동 완료');
    }
    
    debugPrint('[MapService] showMyLocation 완료');
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

  /// 내 위치 업데이트 (기존 마커 이동, 카메라 이동 없음) - 수정됨
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
      
      // 필요한 경우 카메라도 이동
      if (shouldMoveCamera) {
        await moveCamera(location, zoom: 16);
        debugPrint('[MapService] updateMyLocation: 카메라 이동 완료');
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


  /// 내 위치로 카메라 이동만 (마커 표시 없이) - 수정됨
  Future<void> moveToMyLocation(NLatLng location) async {
    debugPrint('[MapService] moveToMyLocation 호출 - 위치: (${location.latitude}, ${location.longitude})');
    
    if (_mapController == null) {
      debugPrint('[MapService] moveToMyLocation: _mapController가 null입니다!');
      return;
    }
    
    try {
      await moveCamera(location, zoom: 16);
      debugPrint('[MapService] moveToMyLocation 완료');
    } catch (e) {
      debugPrint('[MapService] moveToMyLocation 오류: $e');
    }
  }

  /// 내 위치 숨기기
  Future<void> hideMyLocation() async {
    await _removeMyLocationMarker();
  }

  /// 모든 건물 마커 제거
  Future<void> clearBuildingMarkers() async {
    if (_mapController == null) return;
    
    try {
      debugPrint('기존 건물 마커 제거 시작: ${_buildingMarkers.length}개');
      
      for (final marker in _buildingMarkers) {
        try {
          await _mapController!.deleteOverlay(marker.info);
        } catch (e) {
          debugPrint('마커 제거 오류 (무시): ${marker.info.id} - $e');
        }
      }
      
      _buildingMarkers.clear();
      debugPrint('건물 마커 제거 완료');
    } catch (e) {
      debugPrint('건물 마커 제거 중 오류: $e');
    }
  }

  Future<void> addBuildingMarkers(
    Function(NMarker, Building) onMarkerTap,
  ) async {
    if (_mapController == null) {
      debugPrint('MapController가 null입니다');
      return;
    }

    try {
      debugPrint('서버에서 건물 데이터 로딩 시작...');
      
      // 서버에서 건물 데이터 로드
      await _buildingDataService.loadBuildings();
      
      if (_buildingDataService.hasData) {
        debugPrint('서버에서 ${_buildingDataService.buildings.length}개 건물 데이터 수신');
        
        // 서버 데이터에 자동 운영상태 적용
        final buildingsWithAutoStatus = _buildingDataService.buildings.map((building) {
          final autoStatus = _getAutoOperatingStatus(building.baseStatus);
          return building.copyWith(baseStatus: autoStatus);
        }).toList();
        
        // 서버 데이터로 마커 생성
        await _createMarkersFromData(buildingsWithAutoStatus, onMarkerTap, '서버');
        
      } else {
        debugPrint('서버에서 건물 데이터를 받아오지 못했습니다');
        
        // 서버 데이터 로딩 실패 시 로컬 데이터 사용 (fallback)
        debugPrint('로컬 데이터로 fallback 시도...');
        await _addLocalBuildingMarkers(onMarkerTap);
      }
    } catch (e) {
      debugPrint('서버 기반 마커 추가 오류: $e');
      
      // 오류 발생 시 로컬 데이터 사용
      debugPrint('오류로 인한 로컬 데이터 fallback...');
      await _addLocalBuildingMarkers(onMarkerTap);
    }
  }

  // 공통 마커 생성 메서드 - 운영상태 정보 로깅 추가
  Future<void> _createMarkersFromData(
    List<Building> buildings,
    Function(NMarker, Building) onMarkerTap,
    String dataSource,
  ) async {
    // 기존 마커 제거
    await clearBuildingMarkers();

    // 현재 시간 로깅
    final now = DateTime.now();
    debugPrint('🕐 현재 시간: ${now.hour}:${now.minute.toString().padLeft(2, '0')}');

    // 데이터로 마커 생성
    for (var building in buildings) {
      // 현재 운영상태 로깅
      debugPrint('🏢 ${building.name}: ${building.baseStatus} (기본: ${building.baseStatus})');
      
      final marker = NMarker(
        id: 'building_${building.name}',
        position: NLatLng(building.lat, building.lng),
        icon: _blueBuildingIcon,
      );

      marker.setOnTapListener((_) {
        debugPrint('건물 마커 탭 ($dataSource): ${building.name} - ${building.baseStatus}');
        onMarkerTap(marker, building);
        return true;
      });

      _buildingMarkers.add(marker);
      
      if (_buildingMarkersVisible) {
        try {
          await _mapController?.addOverlay(marker);
        } catch (e) {
          debugPrint('건물 마커 추가 실패: ${building.name} - $e');
        }
      }
    }
    
    debugPrint('$dataSource 기반 건물 마커 ${_buildingMarkers.length}개 추가 완료');
  }

  // 로컬 데이터로 마커 추가 (fallback 용도)
  Future<void> _addLocalBuildingMarkers(
    Function(NMarker, Building) onMarkerTap,
  ) async {
    try {
      // 현재 언어로 건물 데이터 가져오기 (자동 운영상태 적용됨)
      final localBuildings = _getCurrentBuildingData();
      
      if (localBuildings.isNotEmpty) {
        await _createMarkersFromData(localBuildings, onMarkerTap, '로컬(현재언어)');
      } else {
        debugPrint('로컬 데이터도 비어있습니다');
      }
      
    } catch (e) {
      debugPrint('로컬 마커 추가 실패: $e');
    }
  }

  // 서버에서 건물 데이터 새로고침
  Future<void> refreshBuildingData() async {
    debugPrint('건물 데이터 새로고침 시작...');
    await _buildingDataService.refresh();
    debugPrint('건물 데이터 새로고침 완료');
  }

  // 건물 검색 (서버 데이터 우선, fallback은 로컬)
  List<Building> searchBuildings(String query) {
    if (_buildingDataService.hasData) {
      // 서버 데이터에 자동 운영상태 적용
      final buildingsWithAutoStatus = _buildingDataService.buildings.map((building) {
        final autoStatus = _getAutoOperatingStatus(building.baseStatus);
        return building.copyWith(baseStatus: autoStatus);
      }).toList();
      
      final lowercaseQuery = query.toLowerCase();
      return buildingsWithAutoStatus.where((building) {
        return building.name.toLowerCase().contains(lowercaseQuery) ||
               building.info.toLowerCase().contains(lowercaseQuery) ||
               building.category.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } else {
      // 서버 데이터가 없으면 현재 언어의 로컬 데이터에서 검색 (자동 운영상태 적용됨)
      final localBuildings = _getCurrentBuildingData();
      final lowercaseQuery = query.toLowerCase();
      return localBuildings.where((building) {
        return building.name.toLowerCase().contains(lowercaseQuery) ||
               building.info.toLowerCase().contains(lowercaseQuery) ||
               building.category.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }
  }

  // 카테고리별 건물 조회 (서버 데이터 우선, fallback은 로컬)
  List<Building> getBuildingsByCategory(String category) {
    if (_buildingDataService.hasData) {
      // 서버 데이터에 자동 운영상태 적용
      final buildingsWithAutoStatus = _buildingDataService.buildings.map((building) {
        final autoStatus = _getAutoOperatingStatus(building.baseStatus);
        return building.copyWith(baseStatus: autoStatus);
      }).toList();
      
      return buildingsWithAutoStatus.where((building) {
        return building.category == category;
      }).toList();
    } else {
      // 서버 데이터가 없으면 현재 언어의 로컬 데이터에서 조회 (자동 운영상태 적용됨)
      final localBuildings = _getCurrentBuildingData();
      return localBuildings.where((building) {
        return building.category == category;
      }).toList();
    }
  }

  // 모든 건물 데이터 조회 (자동 운영상태 적용)
  List<Building> getAllBuildings() {
    if (_buildingDataService.hasData) {
      // 서버 데이터에 자동 운영상태 적용
      return _buildingDataService.buildings.map((building) {
        final autoStatus = _getAutoOperatingStatus(building.baseStatus);
        return building.copyWith(baseStatus: autoStatus);
      }).toList();
    } else {
      // 서버 데이터가 없으면 현재 언어의 로컬 데이터 조회 (자동 운영상태 적용됨)
      return _getCurrentBuildingData();
    }
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

  // 경로 관련 오버레이 모두 제거
  Future<void> clearPathOverlays() async {
    if (_mapController == null) return;
    
    try {
      // 경로 오버레이 제거
      for (final overlayId in _pathOverlayIds) {
        try {
          await _mapController!.deleteOverlay(NOverlayInfo(type: NOverlayType.pathOverlay, id: overlayId));
        } catch (e) {
          debugPrint('경로 오버레이 제거 오류 (무시): $overlayId - $e');
        }
      }
      _pathOverlayIds.clear();
      
      // 경로 마커 제거
      for (final markerId in _routeMarkerIds) {
        try {
          await _mapController!.deleteOverlay(NOverlayInfo(type: NOverlayType.marker, id: markerId));
        } catch (e) {
          debugPrint('경로 마커 제거 오류 (무시): $markerId - $e');
        }
      }
      _routeMarkerIds.clear();
      
      debugPrint('모든 경로 관련 오버레이 제거 완료');
    } catch (e) {
      debugPrint('경로 오버레이 제거 중 오류: $e');
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
    _buildingMarkers.clear();
    _pathOverlayIds.clear();
    _routeMarkerIds.clear();
    _myLocationMarker = null;
    _myLocationAccuracyCircle = null;
    debugPrint('MapService 정리 완료');
  }

  // map_service.dart의 drawPath 메서드를 다음과 같이 수정
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



  /// 카메라를 경로에 맞춰 이동
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

      await _mapController!.updateCamera(
        NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(50)),
      );
    }

    debugPrint('[MapService] moveCameraToPath 완료: ${pathCoordinates.length}개 좌표');
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
}
