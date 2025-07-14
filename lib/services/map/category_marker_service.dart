// lib/services/map/category_marker_service.dart - 완전한 버전
import 'package:flutter/material.dart';
import 'package:flutter_application_1/map/widgets/category_marker_widget.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../../models/category_marker_data.dart';

class CategoryMarkerService {
  NaverMapController? _mapController;
  
  // 카테고리 마커 관리
  final List<NMarker> _categoryMarkers = [];
  
  // 🔥 사전 생성된 마커 아이콘 캐시
  Map<String, NOverlayImage> _preGeneratedIcons = {};
  bool _iconsPreGenerated = false;

  // Getters
  List<NMarker> get categoryMarkers => _categoryMarkers;
  bool get hasPreGeneratedIcons => _iconsPreGenerated;

  /// 지도 컨트롤러 설정
  void setMapController(NaverMapController controller) {
    _mapController = controller;
    debugPrint('✅ CategoryMarkerService 지도 컨트롤러 설정 완료');
  }

  /// 🔥 마커 아이콘 사전 생성 (Context가 있을 때 한 번만 실행)
  Future<void> preGenerateMarkerIcons(BuildContext context) async {
    if (_iconsPreGenerated) {
      debugPrint('⚡ 카테고리 마커 아이콘이 이미 생성됨');
      return;
    }

    try {
      debugPrint('🎨 카테고리 마커 아이콘 사전 생성 시작...');
      
      final categories = CategoryMarkerWidget.getAllSupportedCategories();
      _preGeneratedIcons = await CategoryMarkerWidget.preGenerateMarkerIcons(context, categories);
      _iconsPreGenerated = true;
      
      debugPrint('✅ 카테고리 마커 아이콘 사전 생성 완료: ${_preGeneratedIcons.length}개');
      
    } catch (e) {
      debugPrint('❌ 카테고리 마커 아이콘 사전 생성 실패: $e');
      _iconsPreGenerated = false;
    }
  }

  /// 🔥 카테고리 아이콘 마커들 표시 - Context 의존성 제거
  Future<void> showCategoryIconMarkers(List<CategoryMarkerData> categoryData) async {
    try {
      debugPrint('카테고리 아이콘 마커 표시 시작: ${categoryData.length}개');
      
      if (!_iconsPreGenerated) {
        debugPrint('❌ 마커 아이콘이 사전 생성되지 않음. preGenerateMarkerIcons() 먼저 호출 필요');
        return;
      }
      
      // 기존 카테고리 마커들 제거
      await clearCategoryMarkers();

      for (CategoryMarkerData data in categoryData) {
        try {
          debugPrint('🎨 카테고리 마커 생성 중: ${data.buildingName} (${data.category})');
          
          // 🔥 사전 생성된 아이콘 사용
          final iconImage = _getPreGeneratedIcon(data.category);
          
          final marker = NMarker(
            id: 'category_${data.category}_${data.buildingName}_${DateTime.now().millisecondsSinceEpoch}',
            position: _getPositionFromData(data),
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
          continue;
        }
      }

      debugPrint('✅ 카테고리 아이콘 마커 표시 완료: ${_categoryMarkers.length}개');
    } catch (e) {
      debugPrint('🚨 카테고리 마커 표시 오류: $e');
    }
  }

  /// 🔥 사전 생성된 아이콘 가져오기
  NOverlayImage _getPreGeneratedIcon(String category) {
    final icon = _preGeneratedIcons[category];
    if (icon != null) {
      return icon;
    }
    
    // Fallback: 기본 아이콘 (보통 발생하지 않음)
    debugPrint('⚠️ 사전 생성된 아이콘 없음, 기본 아이콘 사용: $category');
    try {
      return const NOverlayImage.fromAssetImage('lib/asset/building_marker_blue.png');
    } catch (e) {
      debugPrint('❌ 기본 아이콘도 로딩 실패: $e');
      rethrow;
    }
  }

  /// 🔥 CategoryMarkerData에서 위치 정보 추출
  NLatLng _getPositionFromData(CategoryMarkerData data) {
    return NLatLng(data.lat, data.lng);
  }

  /// 카테고리 마커들 제거
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

  /// 🔥 아이콘 캐시 무효화 (Context 변경 시)
  void invalidateIconCache() {
    _preGeneratedIcons.clear();
    _iconsPreGenerated = false;
    debugPrint('🗑️ 카테고리 마커 아이콘 캐시 무효화');
  }

  /// 🔥 특정 카테고리 아이콘 추가 생성 (필요시)
  Future<void> addCategoryIcon(BuildContext context, String category) async {
    if (_preGeneratedIcons.containsKey(category)) {
      debugPrint('⚡ 카테고리 아이콘이 이미 존재: $category');
      return;
    }

    try {
      final icon = await CategoryMarkerWidget.generateSingleMarkerIcon(context, category);
      if (icon != null) {
        _preGeneratedIcons[category] = icon;
        debugPrint('✅ 카테고리 아이콘 추가 생성: $category');
      }
    } catch (e) {
      debugPrint('❌ 카테고리 아이콘 추가 생성 실패: $category - $e');
    }
  }

  /// 서비스 정리
  void dispose() {
    debugPrint('🧹 CategoryMarkerService 정리');
    _categoryMarkers.clear();
    _preGeneratedIcons.clear();
    _iconsPreGenerated = false;
    _mapController = null;
  }
}