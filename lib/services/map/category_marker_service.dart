import 'package:flutter/material.dart';
import 'package:flutter_application_1/map/widgets/category_marker_widget.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../../models/category_marker_data.dart';
import 'package:flutter_application_1/map/widgets/building_floor_sheet.dart'; // Added import for BuildingFloorSheet

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

  /// 한국어 카테고리 이름을 영어 ID로 변환
  String _convertToEnglishId(String koreanCategory) {
    switch (koreanCategory) {
      case '카페':
        return 'cafe';
      case '식당':
        return 'restaurant';
      case '편의점':
        return 'convenience';
      case '자판기':
        return 'vending';
      case '화장실':
        return 'wc';
      case '프린터':
        return 'printer';
      case '복사기':
        return 'copier';
      case 'ATM':
      case '은행(atm)':
        return 'atm';
      case '의료':
      case '보건소':
        return 'medical';
      case '도서관':
        return 'library';
      case '체육관':
      case '헬스장':
        return 'fitness';
      case '주차장':
        return 'parking';
      case '라운지':
        return 'lounge';
      case '소화기':
        return 'extinguisher';
      case '정수기':
        return 'water';
      case '서점':
        return 'bookstore';
      case '우체국':
      case 'post_office':
        return 'post';
      default:
        return koreanCategory.toLowerCase();
    }
  }

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
      debugPrint('🎨 === 카테고리 마커 아이콘 사전 생성 시작 ===');

      // 영어 카테고리 ID들
      final englishCategories =
          CategoryMarkerWidget.getAllSupportedCategories();
      debugPrint('🎨 영어 카테고리들: $englishCategories');

      // 한국어 카테고리 이름들 (실제 UI에서 사용되는 이름들)
      final koreanCategories = [
        '카페',
        '식당',
        '편의점',
        '자판기',
        '화장실',
        '프린터',
        '복사기',
        'ATM',
        '의료',
        '도서관',
        '체육관',
        '주차장',
        '라운지',
        '소화기',
        '정수기',
        '서점',
        '우체국',
      ];
      debugPrint('🎨 한국어 카테고리들: $koreanCategories');

      // 영어 카테고리들로 아이콘 생성
      final englishIcons = await CategoryMarkerWidget.preGenerateMarkerIcons(
        context,
        englishCategories,
      );
      _preGeneratedIcons.addAll(englishIcons);

      // 한국어 카테고리들도 영어 ID로 변환하여 동일한 아이콘 사용
      for (final koreanCategory in koreanCategories) {
        final englishId = _convertToEnglishId(koreanCategory);
        if (englishIcons.containsKey(englishId)) {
          _preGeneratedIcons[koreanCategory] = englishIcons[englishId]!;
          debugPrint('🎨 한국어 카테고리 매핑: "$koreanCategory" -> "$englishId"');
        }
      }

      _iconsPreGenerated = true;
      debugPrint('✅ 카테고리 마커 아이콘 사전 생성 완료: ${_preGeneratedIcons.length}개');
      debugPrint('🎨 생성된 아이콘 키들: ${_preGeneratedIcons.keys.toList()}');
      debugPrint('🎨 === 카테고리 마커 아이콘 사전 생성 끝 ===');
    } catch (e) {
      debugPrint('❌ 카테고리 마커 아이콘 사전 생성 실패: $e');
      _iconsPreGenerated = false;
    }
  }

  /// 카테고리 아이콘 마커 표시 (항상 기존 마커 완전 제거 후 추가)
  Future<void> showCategoryIconMarkers(
    List<CategoryMarkerData> categoryData,
    BuildContext context,
  ) async {
    debugPrint('🎯 === 카테고리 아이콘 마커 표시 시작 ===');
    debugPrint('🎯 받은 카테고리 데이터 개수: ${categoryData.length}');

    // 1. 기존 카테고리 마커 완전 제거
    await clearCategoryMarkers();

    // 2. 아이콘이 사전 생성되지 않았다면 동적으로 생성
    if (!_iconsPreGenerated) {
      debugPrint('⚠️ 아이콘이 사전 생성되지 않음 - 동적 생성 시도');
      await _generateIconsDynamically(context, categoryData);
    }

    // 3. 새 마커 추가
    for (final data in categoryData) {
      try {
        debugPrint('🎯 === 개별 마커 생성 시작 ===');
        debugPrint('🎯 원본 카테고리: "${data.category}"');

        final iconImage = _getPreGeneratedIcon(data.category);
        debugPrint('🎯 아이콘 이미지 획득 완료');

        final marker = NMarker(
          id: 'category_${data.category}_${data.buildingName}_${DateTime.now().millisecondsSinceEpoch}',
          position: NLatLng(data.lat, data.lng),
          icon: iconImage,
          size: const Size(40, 40),
        );
        debugPrint('🎯 마커 객체 생성 완료');

        marker.setOnTapListener((marker) {
          debugPrint('카테고리 마커 클릭: ${data.buildingName} (${data.category})');
          debugPrint(
            '🔍 마커 클릭 데이터 - buildingName: ${data.buildingName}, category: ${data.category}, floors: ${data.floors}',
          );
          // 층 정보 바텀시트 띄우기 - 고정된 높이로 설정
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            isDismissible: true, // 다른 곳을 누르면 닫힘
            enableDrag: true, // 드래그로 닫기 가능
            builder: (context) => BuildingFloorSheet(
              buildingName: data.buildingName,
              floors: data.floors,
              category: data.category, // 카테고리 정보 전달
            ),
          );
        });

        if (_mapController != null) {
          await _mapController!.addOverlay(marker);
          _categoryMarkers.add(marker);
          debugPrint(
            '✅ 카테고리 마커 추가 완료: ${data.buildingName} (${data.category})',
          );
        }
        debugPrint('🎯 === 개별 마커 생성 끝 ===');
      } catch (e) {
        debugPrint('❌ 개별 카테고리 마커 생성 실패: ${data.buildingName} - $e');
      }
    }
    debugPrint('✅ 카테고리 아이콘 마커 표시 완료: ${_categoryMarkers.length}개');
    debugPrint('🎯 === 카테고리 아이콘 마커 표시 끝 ===');
  }

  /// 🔥 동적 아이콘 생성 (사전 생성 실패 시 대안)
  Future<void> _generateIconsDynamically(
    BuildContext context,
    List<CategoryMarkerData> categoryData,
  ) async {
    try {
      debugPrint('🔄 === 동적 아이콘 생성 시작 ===');

      // 현재 카테고리들만 동적으로 생성
      final categories = categoryData
          .map((data) => data.category)
          .toSet()
          .toList();
      debugPrint('🔄 카테고리들: $categories');

      for (final category in categories) {
        if (!_preGeneratedIcons.containsKey(category)) {
          try {
            debugPrint('🔄 동적 아이콘 생성 시도: $category');
            final iconImage =
                await CategoryMarkerWidget.generateSingleMarkerIcon(
                  context,
                  category,
                );
            if (iconImage != null) {
              _preGeneratedIcons[category] = iconImage;
              debugPrint('✅ 동적 아이콘 생성 성공: $category');
            }
          } catch (e) {
            debugPrint('❌ 동적 아이콘 생성 실패: $category - $e');
            // 기본 아이콘 사용
            _preGeneratedIcons[category] = const NOverlayImage.fromAssetImage(
              'lib/asset/building_marker_blue.png',
            );
          }
        } else {
          debugPrint('⚡ 이미 존재하는 아이콘: $category');
        }
      }

      _iconsPreGenerated = true;
      debugPrint('✅ 동적 아이콘 생성 완료: ${_preGeneratedIcons.length}개');
      debugPrint('🔄 생성된 아이콘 키들: ${_preGeneratedIcons.keys.toList()}');
      debugPrint('🔄 === 동적 아이콘 생성 끝 ===');
    } catch (e) {
      debugPrint('❌ 동적 아이콘 생성 실패: $e');
      _iconsPreGenerated = false;
    }
  }

  /// 사전 생성된 아이콘 가져오기
  NOverlayImage _getPreGeneratedIcon(String category) {
    debugPrint('🔍 === 아이콘 조회 시작 ===');
    debugPrint('🔍 요청된 카테고리: "$category"');
    debugPrint('🔍 사전 생성된 아이콘 개수: ${_preGeneratedIcons.length}');
    debugPrint('🔍 사전 생성된 아이콘 키들: ${_preGeneratedIcons.keys.toList()}');

    // 1. 직접 매칭 시도
    final icon = _preGeneratedIcons[category];
    if (icon != null) {
      debugPrint('✅ 사전 생성된 아이콘 찾음 (직접 매칭): $category');
      return icon;
    }

    // 2. 한국어 카테고리인 경우 영어 ID로 변환하여 시도
    final englishId = _convertToEnglishId(category);
    debugPrint('🔍 영어 ID로 변환 시도: "$category" -> "$englishId"');
    final englishIcon = _preGeneratedIcons[englishId];
    if (englishIcon != null) {
      debugPrint('✅ 사전 생성된 아이콘 찾음 (영어 ID 매칭): $category -> $englishId');
      return englishIcon;
    }

    debugPrint('❌ 사전 생성된 아이콘 없음, 기본 아이콘 사용: $category');
    debugPrint('🔍 === 아이콘 조회 끝 ===');
    return const NOverlayImage.fromAssetImage(
      'lib/asset/building_marker_blue.png',
    );
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
      final icon = await CategoryMarkerWidget.generateSingleMarkerIcon(
        context,
        category,
      );
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
