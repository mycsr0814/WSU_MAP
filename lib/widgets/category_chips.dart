import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/category_api_service.dart';
import 'package:flutter_application_1/data/category_fallback_data.dart';
import 'package:flutter_application_1/utils/CategoryLocalization.dart';

class CategoryChips extends StatefulWidget {
  final Function(String, List<Map<String, dynamic>>) onCategorySelected;
  final String? selectedCategory;

  const CategoryChips({
    super.key,
    required this.onCategorySelected,
    this.selectedCategory,
  });

  // 외부에서 카테고리 선택을 위한 GlobalKey
  static final GlobalKey<_CategoryChipsState> globalKey = GlobalKey<_CategoryChipsState>();

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true; // 초기 로딩만

  // 외부에서 카테고리 선택을 위한 메서드
  void selectCategory(String category) {
    if (!mounted) return;
    
    debugPrint('🎯 selectCategory 호출됨: $category');
    
    if (_categories.contains(category)) {
      debugPrint('✅ 카테고리 찾음, 선택 처리 중: $category');
      setState(() {
        _selectedCategory = category;
      });
      _onCategoryTap(category);
    } else {
      debugPrint('❌ 카테고리를 찾을 수 없음: $category');
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _loadCategoriesOnce(); // 한 번만 로드
  }

  @override
  void didUpdateWidget(CategoryChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      setState(() {
        _selectedCategory = widget.selectedCategory;
      });
    }
  }

  void refresh() {
    // 새로고침 시에만 다시 로드
    if (mounted) {
      debugPrint('🔄 카테고리 새로고침');
      _loadCategoriesOnce();
    }
  }

  /// 🔥 한 번만 카테고리 로드
  Future<void> _loadCategoriesOnce() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔄 카테고리 로드 시작...');
      
      // 서버에서 카테고리 가져오기
      final categories = await CategoryApiService.getCategories();
      final categoryNames = categories
          .map((category) => category.categoryName)
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      if (categoryNames.isNotEmpty && mounted) {
        debugPrint('✅ 서버에서 카테고리 로딩 성공: ${categoryNames.length}개');
        setState(() {
          _categories = categoryNames;
          _isLoading = false;
        });
      } else {
        debugPrint('⚠️ 서버에서 빈 카테고리 목록 반환, fallback 사용');
        if (mounted) {
          setState(() {
            _categories = CategoryFallbackData.getCategories();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ 서버 카테고리 로딩 실패: $e, fallback 사용');
      if (mounted) {
        setState(() {
          _categories = CategoryFallbackData.getCategories();
          _isLoading = false;
        });
      }
    }
  }

  void _onCategoryTap(String? category) async {
    debugPrint('🎯 카테고리 탭: $category');

    if (category == null) {
      setState(() {
        _selectedCategory = null;
      });
      widget.onCategorySelected('', []);
      return;
    }

    if (_selectedCategory == category) {
      // 같은 카테고리를 다시 누르면 선택 해제
      debugPrint('🎯 같은 카테고리 재선택 → 해제: $category');
      setState(() {
        _selectedCategory = null;
      });
      widget.onCategorySelected('', []);
      return;
    }

    setState(() {
      _selectedCategory = category;
    });

    try {
      debugPrint('📡 카테고리 선택: $category');

      // 카테고리별 건물 정보 가져오기
      final buildingInfoList = await _getCategoryBuildingInfoList(category);

      debugPrint('📡 카테고리 선택 완료: $category, 건물 수: ${buildingInfoList.length}');

      if (mounted) {
        widget.onCategorySelected(category, buildingInfoList);
      }
    } catch (e) {
      debugPrint('❌ 카테고리 선택 오류: $e');
      if (mounted) {
        setState(() {
          _selectedCategory = null;
        });
        widget.onCategorySelected('', []);
      }
    }
  }

  /// 카테고리별 건물 정보 가져오기
  Future<List<Map<String, dynamic>>> _getCategoryBuildingInfoList(String category) async {
    try {
      debugPrint('🔍 카테고리 건물 정보 조회: $category');
      
      final buildingNames = await CategoryApiService.getCategoryBuildingNames(category);
      debugPrint('🏢 건물 목록: $buildingNames');
      
      return buildingNames.map((name) => {
        'Building_Name': name,
        'Floor_Numbers': <String>[],
      }).toList();
    } catch (e) {
      debugPrint('❌ 건물 정보 가져오기 실패: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '카테고리 로딩 중...',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryChip(category);
        },
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    final icon = CategoryFallbackData.getCategoryIcon(category);

    return InkWell(
      onTap: () {
        if (mounted) {
          _onCategoryTap(category);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: isSelected 
              ? const LinearGradient(
                  colors: [
                    Color(0xFF667eea),
                    Color(0xFF764ba2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                ? const Color(0xFF667eea)
                : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(isSelected ? 3 : 2),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFF667eea).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  icon,
                  size: isSelected ? 14 : 12,
                  color: isSelected 
                    ? Colors.white 
                    : const Color(0xFF667eea),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                CategoryLocalization.getLabel(context, category),
                style: TextStyle(
                  fontSize: isSelected ? 11 : 10,
                  color: isSelected 
                    ? Colors.white 
                    : const Color(0xFF667eea),
                  fontWeight: isSelected 
                    ? FontWeight.w700 
                    : FontWeight.w600,
                  letterSpacing: isSelected ? 0.1 : 0.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
