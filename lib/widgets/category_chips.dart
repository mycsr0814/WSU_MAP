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

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  List<String> _categories = [];
  bool _isLoading = true;
  bool _isApiCalling = false;
  String? _selectedCategory;
  bool _useServerData = true; // 🔥 서버 데이터 사용 여부
  final ScrollController _scrollController = ScrollController();
  double _lastScrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _loadCategories();
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

  Future<void> _loadCategories() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
      });

      List<String> categoryNames = [];

      try {
        final categories = await CategoryApiService.getCategories();
        categoryNames = categories
            .map((category) => category.categoryName)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();

        if (categoryNames.isNotEmpty) {
          debugPrint('✅ 서버에서 카테고리 로딩 성공: ${categoryNames.length}개');
          _useServerData = true;
        } else {
          throw Exception('서버에서 빈 카테고리 목록 반환');
        }
      } catch (e) {
        debugPrint('⚠️ 서버 카테고리 로딩 실패: $e');
        categoryNames = CategoryFallbackData.getCategories();
        _useServerData = false;
        debugPrint('🔄 Fallback 카테고리 데이터 사용: ${categoryNames.length}개');
      }

      if (!mounted) return;

      setState(() {
        _categories = categoryNames;
        _isLoading = false;
      });

      debugPrint('카테고리 로딩 완료: $_categories (서버 데이터: $_useServerData)');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _categories = CategoryFallbackData.getCategories();
        _useServerData = false;
      });
      debugPrint('❌ 카테고리 로딩 완전 실패, 최후 fallback 사용: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getCategoryBuildingInfoList(String category) async {
    try {
      debugPrint('🎯 getCategoryBuildingInfoList 호출: $category (서버 데이터: $_useServerData)');
      if (_useServerData) {
        try {
          // 서버에서 [{Building_Name, Floor_Numbers}] 형태로 받아온다고 가정
          final response = await CategoryApiService.getCategoryBuildingInfoList(category);
          if (response.isNotEmpty) {
            debugPrint('🏢 서버에서 건물+층 목록 반환: $response');
            return response;
          } else {
            debugPrint('⚠️ 서버에서 해당 카테고리의 건물을 찾지 못함, fallback 사용');
          }
        } catch (e) {
          debugPrint('❌ 서버 요청 실패: $e');
        }
      }
      debugPrint('🔄 Fallback 데이터에서 건물 목록 조회...');
      final buildings = CategoryFallbackData.getBuildingsByCategory(category);
      debugPrint('🏢 Fallback에서 건물 목록 반환: $buildings');
      // fallback은 층 정보 없이 건물명만 있으므로, floors는 빈 배열로 처리
      return buildings.map((name) => {'Building_Name': name, 'Floor_Numbers': <String>[]}).toList();
    } catch (e) {
      debugPrint('❌ 카테고리 건물 조회 완전 실패: $e');
      return [];
    }
  }

  void _onCategoryTap(String? category) async {
    debugPrint('🎯 카테고리 탭: $category');

    if (_isApiCalling) {
      debugPrint('⚠️ API 호출 중이므로 무시');
      return;
    }

    // 현재 스크롤 위치 저장
    _lastScrollPosition = _scrollController.position.pixels;

    if (category == null) {
      setState(() {
        _selectedCategory = null;
      });
      widget.onCategorySelected('', []);
      return;
    }

    if (_selectedCategory == category) {
      // 같은 카테고리를 다시 누르면 선택 해제하고 맨 앞으로 스크롤
      setState(() {
        _selectedCategory = null;
      });
      widget.onCategorySelected('', []);
      
      // 맨 앞으로 스크롤
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
      return;
    }

    _isApiCalling = true;

    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });

    try {
      debugPrint('📡 API 호출 시작: $category');

      final buildingInfoList = await _getCategoryBuildingInfoList(category);

      debugPrint('📡 API 호출 완료: $category, 건물 수: ${buildingInfoList.length}');
      debugPrint('📍 건물+층 목록: $buildingInfoList');

      setState(() {
        _isLoading = false;
      });

      widget.onCategorySelected(category, buildingInfoList);
      
      // 스크롤 위치 복원
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _lastScrollPosition,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    } catch (e) {
      debugPrint('❌ API 호출 오류: $e');
      setState(() {
        _isLoading = false;
        _selectedCategory = null;
      });

      widget.onCategorySelected('', []);
    } finally {
      _isApiCalling = false;
    }
  }

  void refresh() {
    if (mounted) {
      _useServerData = true;
      _loadCategories();
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

    if (_categories.isEmpty) {
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
                '카테고리를 불러올 수 없습니다',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              _buildRetryButton(),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (!_useServerData)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.offline_bolt, size: 12, color: Colors.orange.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Offline 모드',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: refresh,
                    child: Icon(Icons.refresh, size: 12, color: Colors.orange.shade600),
                  ),
                ],
              ),
            ),

          Expanded(
            child: ListView.separated(
              controller: _scrollController, // 스크롤 컨트롤러 연결
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _buildCategoryChip(category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return InkWell(
      onTap: refresh,
      borderRadius: BorderRadius.circular(12),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.indigo.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              CategoryLocalization.getLabel(context, category),
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
