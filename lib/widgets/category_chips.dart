// lib/map/widgets/category_chips.dart - mounted 체크 추가
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/services/category_api_service.dart';

class CategoryChips extends StatefulWidget {
  final Function(String, List<CategoryBuilding>) onCategorySelected;
  final String? selectedCategory;

  const CategoryChips({
    super.key,
    required this.onCategorySelected,
    this.selectedCategory,
  });

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  List<String> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// 🔥 mounted 체크 추가된 카테고리 로딩
  Future<void> _loadCategories() async {
    try {
      // 🔥 mounted 체크 추가
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final categories = await CategoryApiService.getCategories();
      
      // 카테고리 이름만 추출하고 중복 제거
      final categoryNames = categories
          .map((category) => category.categoryName)
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      // 🔥 mounted 체크 추가
      if (!mounted) return;

      setState(() {
        _categories = categoryNames;
        _isLoading = false;
      });

      debugPrint('카테고리 로딩 완료: $_categories');
    } catch (e) {
      // 🔥 mounted 체크 추가
      if (!mounted) return;
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _categories = [];
      });
      debugPrint('카테고리 로딩 실패: $e');
    }
  }

  // 카테고리 새로고침 (외부에서 호출 가능)
  void refresh() {
    // 🔥 mounted 체크 추가
    if (mounted) {
      _loadCategories();
    }
  }

  /// 🔥 안전한 카테고리 선택 처리
  Future<void> _onCategoryTap(String category) async {
    try {
      debugPrint('카테고리 선택: $category');
      
      // 🔥 mounted 체크 추가
      if (!mounted) return;
      
      // 로딩 상태 표시를 위해 먼저 빈 리스트로 콜백 호출
      widget.onCategorySelected(category, []);
      
      // 해당 카테고리의 건물 위치들을 조회
      final buildings = await CategoryApiService.getCategoryBuildings(category);
      
      // 🔥 mounted 체크 추가 (비동기 작업 후)
      if (!mounted) return;
      
      debugPrint('카테고리 $category의 건물 위치 ${buildings.length}개 조회됨');
      
      // 조회된 건물들을 로그로 출력하여 디버깅
      for (var building in buildings) {
        debugPrint('건물: ${building.buildingName}, 위치: (${building.location.x}, ${building.location.y})');
      }
      
      // 부모 위젯에 카테고리명과 건물 위치 정보 전달
      widget.onCategorySelected(category, buildings);
      
    } catch (e) {
      debugPrint('카테고리 건물 조회 실패: $e');
      
      // 🔥 mounted 체크 추가
      if (!mounted) return;
      
      // 에러 발생 시 빈 리스트로 전달
      widget.onCategorySelected(category, []);
      
      // 에러 메시지 표시 (이미 mounted 체크가 있음)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('카테고리 정보를 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ),
      );
    }

    if (_error != null || _categories.isEmpty) {
      return Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.grey[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _error != null ? '카테고리 로딩 실패' : '카테고리가 없습니다',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  // 🔥 mounted 체크 추가
                  if (mounted) {
                    _loadCategories();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh,
                        size: 14,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '재시도',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryChip(category);
        },
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = widget.selectedCategory == category;
    IconData icon = _getCategoryIcon(category);

    return InkWell(
      onTap: () {
        // 🔥 mounted 체크 추가
        if (mounted) {
          _onCategoryTap(category);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFF1E3A8A) 
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected 
                  ? Colors.white 
                  : Colors.indigo.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              category,
              style: TextStyle(
                fontSize: 14,
                color: isSelected 
                    ? Colors.white 
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
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
        return Icons.atm;
      case '의료':
      case '보건소':
        return Icons.local_hospital;
      case '도서관':
        return Icons.local_library;
      case '체육관':
        return Icons.fitness_center;
      case '주차장':
        return Icons.local_parking;
      default:
        return Icons.category;
    }
  }

  // 카테고리 아이콘을 가져오는 static 메서드 (외부에서 사용 가능)
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case '카페':
        return Icons.local_cafe;
      case '식당':
        return Icons.restaurant;
      case '편의점':
        return Icons.store;
      case '자판기':
        return Icons.local_drink;
      case '프린터':
        return Icons.print;
      case '복사기':
        return Icons.content_copy;
      case 'ATM':
      case '은행':
        return Icons.atm;
      case '도서관':
        return Icons.local_library;
      case '체육관':
        return Icons.fitness_center;
      case '주차장':
        return Icons.local_parking;
      default:
        return Icons.category;
    }
  }

  /// 🔥 dispose 메서드 추가 (안전한 정리)
  @override
  void dispose() {
    debugPrint('🧹 CategoryChips dispose');
    super.dispose();
  }
}