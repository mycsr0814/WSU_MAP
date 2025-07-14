// lib/services/map/building_marker_service.dart (새로 생성)
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../../models/building.dart';

class BuildingMarkerService {
  NaverMapController? _mapController;
  NOverlayImage? _blueBuildingIcon;
  
  // 건물 마커 관리
  final List<NMarker> _buildingMarkers = [];
  final Set<String> _buildingMarkerIds = {};
  bool _buildingMarkersVisible = true;
  NMarker? _selectedMarker;
  
  // 마커 클릭 콜백
  Function(NMarker, Building)? _onBuildingMarkerTap;

  // Getters
  bool get buildingMarkersVisible => _buildingMarkersVisible;
  List<NMarker> get buildingMarkers => _buildingMarkers;

  /// 지도 컨트롤러 설정
  void setMapController(NaverMapController controller) {
    _mapController = controller;
    debugPrint('✅ BuildingMarkerService 지도 컨트롤러 설정 완료');
  }

  /// 마커 아이콘 로딩
  Future<void> loadMarkerIcons() async {
    try {
      _blueBuildingIcon = const NOverlayImage.fromAssetImage(
        'lib/asset/building_marker_blue.png'
      );
      debugPrint('BuildingMarkerService: 마커 아이콘 로딩 완료');
    } catch (e) {
      debugPrint('BuildingMarkerService: 마커 아이콘 로딩 실패 (기본 마커 사용): $e');
      _blueBuildingIcon = null;
    }
  }

  /// 건물 마커들 추가 (map_service.dart에서 이동)
  Future<void> addBuildingMarkers(
    List<Building> buildings, 
    Function(NMarker, Building) onTap
  ) async {
    try {
      if (_mapController == null) {
        debugPrint('❌ 지도 컨트롤러가 없음');
        return;
      }

      _onBuildingMarkerTap = onTap;

      if (buildings.isEmpty) {
        debugPrint('❌ 건물 데이터가 없음');
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

  /// 건물 마커 아이콘 가져오기
  NOverlayImage? _getBuildingMarkerIcon(Building building) {
    return _blueBuildingIcon;
  }

  /// 안전한 건물 마커 제거
  Future<void> clearBuildingMarkers() async {
    if (_mapController == null) return;
    
    try {
      debugPrint('기존 건물 마커 제거 시작: ${_buildingMarkers.length}개');
      
      final markersToRemove = Set<NMarker>.from(_buildingMarkers);
      
      for (final marker in markersToRemove) {
        try {
          await _mapController!.deleteOverlay(marker.info);
        } catch (e) {
          // 이미 제거된 마커는 무시
        }
      }
      
      _buildingMarkers.clear();
      _buildingMarkerIds.clear();
      
      debugPrint('건물 마커 제거 완료');
    } catch (e) {
      debugPrint('건물 마커 제거 중 오류: $e');
      _buildingMarkers.clear();
      _buildingMarkerIds.clear();
    }
  }

  /// 건물 마커 표시/숨기기 토글
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

  /// 모든 건물 마커 숨기기
  Future<void> hideAllBuildingMarkers() async {
    debugPrint('모든 건물 마커 숨기기 시작: ${_buildingMarkers.length}개');
    
    for (NMarker marker in _buildingMarkers) {
      marker.setIsVisible(false);
    }
    
    debugPrint('✅ 모든 건물 마커 숨기기 완료');
  }

  /// 모든 건물 마커 다시 표시
  Future<void> showAllBuildingMarkers() async {
    debugPrint('모든 건물 마커 다시 표시 시작: ${_buildingMarkers.length}개');
    
    for (NMarker marker in _buildingMarkers) {
      marker.setIsVisible(true);
    }
    
    debugPrint('✅ 모든 건물 마커 다시 표시 완료');
  }

  /// 선택된 건물 마커 강조
  Future<void> highlightBuildingMarker(NMarker marker) async {
    await resetAllBuildingMarkers();

    marker.setIcon(const NOverlayImage.fromAssetImage('lib/asset/building_marker_blue.png'));
    marker.setCaption(NOverlayCaption(
      text: '',
      color: Colors.deepOrange,
      textSize: 16,
      haloColor: Colors.white,
    ));
    marker.setSize(const Size(110, 110));
    _selectedMarker = marker;
  }

  /// 모든 건물 마커 스타일 초기화
  Future<void> resetAllBuildingMarkers() async {
    for (final marker in _buildingMarkers) {
      marker.setIcon(_blueBuildingIcon);
      marker.setCaption(NOverlayCaption(
        text: '',
        color: Colors.blue,
        textSize: 12,
        haloColor: Colors.white,
      ));
      marker.setSize(const Size(40, 40));
    }
    _selectedMarker = null;
  }

  /// 서비스 정리
  void dispose() {
    debugPrint('🧹 BuildingMarkerService 정리');
    _buildingMarkers.clear();
    _buildingMarkerIds.clear();
    _selectedMarker = null;
    _onBuildingMarkerTap = null;
    _mapController = null;
  }
}