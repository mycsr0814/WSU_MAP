import 'package:flutter/material.dart';
import 'package:flutter_application_1/map/widgets/category_marker_widget.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../../models/category_marker_data.dart';

class CategoryMarkerService {
  NaverMapController? _mapController;

  // 카테고리 마커만 별도 리스트로 관리
  final List<NMarker> _categoryMarkers = [];

  // 아이콘 캐시
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

  /// 마커 아이콘 사전 생성 (Context가 있을 때 한 번만 실행)
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

  /// 카테고리 아이콘 마커 표시 (항상 기존 마커 완전 제거 후 추가)
  Future<void> showCategoryIconMarkers(List<CategoryMarkerData> categoryData) async {
    if (!_iconsPreGenerated) {
      debugPrint('❌ 마커 아이콘이 사전 생성되지 않음. preGenerateMarkerIcons() 먼저 호출 필요');
      return;
    }
    // 1. 기존 카테고리 마커 완전 제거
    await clearCategoryMarkers();

    // 2. 새 마커 추가
    for (final data in categoryData) {
      try {
        final iconImage = _getPreGeneratedIcon(data.category);
        final marker = NMarker(
          id: 'category_${data.category}_${data.buildingName}_${DateTime.now().millisecondsSinceEpoch}',
          position: NLatLng(data.lat, data.lng),
          icon: iconImage,
          size: const Size(40, 40),
        );
        marker.setOnTapListener((marker) {
          debugPrint('카테고리 마커 클릭: ${data.buildingName} (${data.category})');
        });
        if (_mapController != null) {
          await _mapController!.addOverlay(marker);
          _categoryMarkers.add(marker);
          debugPrint('✅ 카테고리 마커 추가 완료: ${data.buildingName}');
        }
      } catch (e) {
        debugPrint('❌ 개별 카테고리 마커 생성 실패: ${data.buildingName} - $e');
      }
    }
    debugPrint('✅ 카테고리 아이콘 마커 표시 완료: ${_categoryMarkers.length}개');
  }

  /// 사전 생성된 아이콘 가져오기
  NOverlayImage _getPreGeneratedIcon(String category) {
    final icon = _preGeneratedIcons[category];
    if (icon != null) return icon;
    debugPrint('⚠️ 사전 생성된 아이콘 없음, 기본 아이콘 사용: $category');
    return const NOverlayImage.fromAssetImage('lib/asset/building_marker_blue.png');
  }

  /// 카테고리 마커 완전 제거 (지도에서도 삭제)
  Future<void> clearCategoryMarkers() async {
    debugPrint('카테고리 마커 제거 시작: ${_categoryMarkers.length}개');
    for (final marker in _categoryMarkers) {
      try {
        await _mapController?.deleteOverlay(marker.info);
      } catch (e) {
        debugPrint('❌ 마커 제거 중 오류: $e');
      }
    }
    _categoryMarkers.clear();
    debugPrint('✅ 카테고리 마커 제거 완료');
  }

  /// 아이콘 캐시 무효화 (Context 변경 시)
  void invalidateIconCache() {
    _preGeneratedIcons.clear();
    _iconsPreGenerated = false;
    debugPrint('🗑️ 카테고리 마커 아이콘 캐시 무효화');
  }

  /// 특정 카테고리 아이콘 추가 생성 (필요시)
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
