import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_application_1/data/category_fallback_data.dart';

/// 🔥 Context 의존성을 제거한 카테고리 마커 위젯 팩토리
class CategoryMarkerWidget {
  /// 한국어 카테고리 이름을 영어 ID로 변환
  static String _convertToEnglishId(String koreanCategory) {
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

  /// 🔥 카테고리 아이콘 위젯을 사전 생성하는 팩토리 메서드
  static Future<Map<String, NOverlayImage>> preGenerateMarkerIcons(
    BuildContext context,
    List<String> categories,
  ) async {
    final markerImages = <String, NOverlayImage>{};

    debugPrint('🎨 === 카테고리 마커 아이콘 사전 생성 시작 ===');
    debugPrint('🎨 요청된 카테고리들: $categories');
    debugPrint('🎨 카테고리 개수: ${categories.length}');

    for (final category in categories) {
      try {
        debugPrint('🎨 === 개별 카테고리 아이콘 생성 시작: $category ===');

        // 한국어 카테고리 이름을 영어 ID로 변환
        final englishId = _convertToEnglishId(category);
        debugPrint('🎨 변환된 영어 ID: "$englishId"');

        final iconData = CategoryFallbackData.getCategoryIcon(englishId);
        debugPrint('🎨 CategoryFallbackData에서 가져온 아이콘: $iconData');

        final backgroundColor = _getCategoryColor(englishId);
        debugPrint('🎨 배경색: $backgroundColor');

        final iconWidget = _createIconMarkerWidget(
          iconData: iconData,
          backgroundColor: backgroundColor,
          iconColor: Colors.white,
          size: 40,
        );
        debugPrint('🎨 아이콘 위젯 생성 완료');

        final overlayImage = await NOverlayImage.fromWidget(
          widget: iconWidget,
          size: const Size(40, 40),
          context: context,
        );
        debugPrint('🎨 NOverlayImage 생성 완료');

        markerImages[category] = overlayImage;
        debugPrint('✅ 카테고리 아이콘 생성 성공: $category -> $englishId');
        debugPrint('🎨 === 개별 카테고리 아이콘 생성 끝: $category ===');
      } catch (e) {
        debugPrint('❌ 카테고리 아이콘 생성 실패: $category - $e');

        // Fallback으로 기본 에셋 이미지 사용
        try {
          markerImages[category] = const NOverlayImage.fromAssetImage(
            'lib/asset/building_marker_blue.png',
          );
          debugPrint('⚠️ 기본 아이콘으로 대체: $category');
        } catch (e2) {
          debugPrint('❌ 기본 아이콘도 실패: $category - $e2');
        }
      }
    }

    debugPrint('✅ 카테고리 마커 아이콘 사전 생성 완료: ${markerImages.length}개');
    debugPrint('🎨 생성된 아이콘 키들: ${markerImages.keys.toList()}');
    debugPrint('🎨 === 카테고리 마커 아이콘 사전 생성 끝 ===');
    return markerImages;
  }

  /// 🔥 단일 카테고리 아이콘 생성 (필요시)
  static Future<NOverlayImage?> generateSingleMarkerIcon(
    BuildContext context,
    String category,
  ) async {
    try {
      debugPrint('🎨 === 단일 카테고리 아이콘 생성 시작 ===');
      debugPrint('🎨 원본 카테고리: "$category"');

      // 한국어 카테고리 이름을 영어 ID로 변환
      final englishId = _convertToEnglishId(category);
      debugPrint('🎨 변환된 영어 ID: "$englishId"');

      final iconData = CategoryFallbackData.getCategoryIcon(englishId);
      debugPrint('🎨 CategoryFallbackData에서 가져온 아이콘: $iconData');

      final backgroundColor = _getCategoryColor(englishId);
      debugPrint('🎨 배경색: $backgroundColor');

      final iconWidget = _createIconMarkerWidget(
        iconData: iconData,
        backgroundColor: backgroundColor,
        iconColor: Colors.white,
        size: 40,
      );
      debugPrint('🎨 아이콘 위젯 생성 완료');

      final overlayImage = await NOverlayImage.fromWidget(
        widget: iconWidget,
        size: const Size(40, 40),
        context: context,
      );
      debugPrint('🎨 NOverlayImage 생성 완료');

      debugPrint('✅ 단일 카테고리 아이콘 생성 성공: $category -> $englishId');
      debugPrint('🎨 === 단일 카테고리 아이콘 생성 끝 ===');
      return overlayImage;
    } catch (e) {
      debugPrint('❌ 단일 카테고리 아이콘 생성 실패: $category - $e');

      try {
        return const NOverlayImage.fromAssetImage(
          'lib/asset/building_marker_blue.png',
        );
      } catch (e2) {
        debugPrint('❌ 기본 아이콘도 실패: $category - $e2');
        return null;
      }
    }
  }

  /// 🔥 아이콘 마커 위젯 생성 (내부 메서드)
  static Widget _createIconMarkerWidget({
    required IconData iconData,
    required Color backgroundColor,
    required Color iconColor,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(iconData, color: iconColor, size: size * 0.5),
      ),
    );
  }

  /// 🔥 카테고리별 색상 가져오기
  static Color _getCategoryColor(String category) {
    final colorValue = CategoryUtils.getCategoryColorValue(category);
    return Color(colorValue);
  }

  /// 🔥 모든 카테고리의 기본 아이콘 목록 반환
  static List<String> getAllSupportedCategories() {
    return CategoryFallbackData.getCategories();
  }

  /// 🔥 카테고리 유효성 검증
  static bool isValidCategory(String category) {
    return CategoryFallbackData.hasCategory(category);
  }

  /// 🔥 카테고리 정규화
  static String normalizeCategory(String category) {
    return CategoryUtils.normalizeCategory(category);
  }
}
