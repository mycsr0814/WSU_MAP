// lib/widgets/category_marker_widget.dart - 새로 생성
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_application_1/data/category_fallback_data.dart';

/// 🔥 Context 의존성을 제거한 카테고리 마커 위젯 팩토리
class CategoryMarkerWidget {
  
  /// 🔥 카테고리 아이콘 위젯을 사전 생성하는 팩토리 메서드
  static Future<Map<String, NOverlayImage>> preGenerateMarkerIcons(
    BuildContext context,
    List<String> categories
  ) async {
    final markerImages = <String, NOverlayImage>{};
    
    debugPrint('🎨 카테고리 마커 아이콘 사전 생성 시작: ${categories.length}개');
    
    for (final category in categories) {
      try {
        final iconData = _getCategoryIcon(category);
        final backgroundColor = _getCategoryColor(category);
        
        final iconWidget = _createIconMarkerWidget(
          iconData: iconData,
          backgroundColor: backgroundColor,
          iconColor: Colors.white,
          size: 40,
        );
        
        final overlayImage = await NOverlayImage.fromWidget(
          widget: iconWidget,
          size: const Size(40, 40),
          context: context,
        );
        
        markerImages[category] = overlayImage;
        debugPrint('✅ 카테고리 아이콘 생성: $category');
        
      } catch (e) {
        debugPrint('❌ 카테고리 아이콘 생성 실패: $category - $e');
        
        // Fallback으로 기본 에셋 이미지 사용
        try {
          markerImages[category] = const NOverlayImage.fromAssetImage(
            'lib/asset/building_marker_blue.png'
          );
        } catch (e2) {
          debugPrint('❌ 기본 아이콘도 실패: $category - $e2');
        }
      }
    }
    
    debugPrint('✅ 카테고리 마커 아이콘 사전 생성 완료: ${markerImages.length}개');
    return markerImages;
  }

  /// 🔥 단일 카테고리 아이콘 생성 (필요시)
  static Future<NOverlayImage?> generateSingleMarkerIcon(
    BuildContext context,
    String category
  ) async {
    try {
      final iconData = _getCategoryIcon(category);
      final backgroundColor = _getCategoryColor(category);
      
      final iconWidget = _createIconMarkerWidget(
        iconData: iconData,
        backgroundColor: backgroundColor,
        iconColor: Colors.white,
        size: 40,
      );
      
      final overlayImage = await NOverlayImage.fromWidget(
        widget: iconWidget,
        size: const Size(40, 40),
        context: context,
      );
      
      debugPrint('✅ 단일 카테고리 아이콘 생성: $category');
      return overlayImage;
      
    } catch (e) {
      debugPrint('❌ 단일 카테고리 아이콘 생성 실패: $category - $e');
      
      try {
        return const NOverlayImage.fromAssetImage(
          'lib/asset/building_marker_blue.png'
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

  /// 🔥 카테고리별 아이콘 가져오기
  static IconData _getCategoryIcon(String category) {
    // CategoryFallbackData에서 아이콘 코드 포인트 가져오기
    final codePoint = CategoryFallbackData.categoryIconCodePoints[category];
    if (codePoint != null) {
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }
    
    // 기본 아이콘들
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
      case '은행':
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
      case '우체국':
        return Icons.local_post_office;
      case '서점':
        return Icons.menu_book;
      case '정수기':
        return Icons.water_drop;
      case '소화기':
        return Icons.fire_extinguisher;
      case '라운지':
        return Icons.weekend;
      default:
        return Icons.category;
    }
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