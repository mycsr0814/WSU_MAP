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
  bool _isLoading = true;
  bool _isApiCalling = false;
  String? _selectedCategory;
  bool _useServerData = true; // 🔥 서버 데이터 사용 여부
  final ScrollController _scrollController = ScrollController();
  double _lastScrollPosition = 0.0;

  // 외부에서 카테고리 선택을 위한 메서드
  void selectCategory(String category) {
    debugPrint('🎯 selectCategory 호출됨: $category');
    debugPrint('🎯 현재 사용 가능한 카테고리: $_categories');
    
    if (_categories.contains(category)) {
      debugPrint('✅ 카테고리 찾음, 선택 처리 중: $category');
      setState(() {
        _selectedCategory = category;
      });
      debugPrint('✅ setState 완료, _selectedCategory: $_selectedCategory');
      _onCategoryTap(category);
      debugPrint('✅ _onCategoryTap 호출 완료: $category');
    } else {
      debugPrint('❌ 카테고리를 찾을 수 없음: $category');
      debugPrint('❌ 사용 가능한 카테고리 목록: $_categories');
    }
  }

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

      // 🔥 초기 상태에서 fallback 데이터를 먼저 로드 (버튼이 사라지지 않도록)
      if (_categories.isEmpty) {
        debugPrint('🔄 초기 fallback 데이터 로드...');
        setState(() {
          _categories = CategoryFallbackData.getCategories();
          _isLoading = false;
          _useServerData = false;
        });
      }

      // 🔥 백그라운드에서 서버 데이터 시도 (기존 카테고리는 유지)
      // setState(() {
      //   _isLoading = true; // 이 부분을 제거하여 기존 카테고리가 사라지지 않도록 함
      // });

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

      // 카테고리가 비어있으면 fallback 데이터 사용
      if (categoryNames.isEmpty) {
        debugPrint('⚠️ 카테고리 목록이 비어있음, fallback 데이터 사용');
        categoryNames = CategoryFallbackData.getCategories();
        _useServerData = false;
      }

      setState(() {
        _categories = categoryNames;
        _isLoading = false;
      });

      debugPrint('카테고리 로딩 완료: $_categories (서버 데이터: $_useServerData)');
    } catch (e) {
      debugPrint('❌ 카테고리 로딩 중 오류: $e');
      if (mounted) {
        setState(() {
          _categories = CategoryFallbackData.getCategories();
          _isLoading = false;
          _useServerData = false;
        });
      }
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
      // 같은 카테고리를 다시 누르면 선택 해제
      debugPrint('🎯 같은 카테고리 재선택 → 해제: $category');
      setState(() {
        _selectedCategory = null;
      });
      widget.onCategorySelected('', []);
      return;
    }

    _isApiCalling = true;

    setState(() {
      _selectedCategory = category;
      // _isLoading = true; // 로딩 상태 설정 제거하여 깜빡임 방지
    });

    try {
      debugPrint('📡 API 호출 시작: $category');

      final buildingInfoList = await _getCategoryBuildingInfoList(category);

      debugPrint('📡 API 호출 완료: $category, 건물 수: ${buildingInfoList.length}');
      debugPrint('📍 건물+층 목록: $buildingInfoList');

      // setState(() {
      //   _isLoading = false;
      // });

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
    // 카테고리가 비어있으면 로딩 표시
    if (_categories.isEmpty) {
      return Container(
        height: 40, // 50에서 40으로 축소
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 20,12에서 16,8로 축소
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade50,
                  Colors.orange.shade100,
                ],
              ),
              borderRadius: BorderRadius.circular(12), // 16에서 12로 축소
              border: Border.all(
                color: Colors.orange.shade200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4), // 6에서 4로 축소
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6), // 8에서 6으로 축소
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade600,
                    size: 14, // 18에서 14로 축소
                  ),
                ),
                const SizedBox(width: 8), // 12에서 8로 축소
                Text(
                  '카테고리 로딩 중...',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12, // 14에서 12로 축소
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8), // 12에서 8로 축소
                _buildRetryButton(),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 40, // 50에서 40으로 축소
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 🔥 로딩 중일 때만 상단에 인디케이터 표시 (카테고리는 계속 보이도록)
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // 12,6에서 10,4로 축소
              margin: const EdgeInsets.only(bottom: 4), // 6에서 4로 축소
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                    const Color(0xFF3B82F6).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10), // 12에서 10으로 축소
                border: Border.all(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14, // 16에서 14로 축소
                    height: 14, // 16에서 14로 축소
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                    ),
                  ),
                  const SizedBox(width: 6), // 8에서 6으로 축소
                  Text(
                    '카테고리 업데이트 중...',
                    style: TextStyle(
                      color: const Color(0xFF1E3A8A),
                      fontSize: 11, // 12에서 11로 축소
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // 🔥 서버 데이터를 사용하지 않을 때 경고 표시
          if (!_useServerData)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // 12,6에서 10,4로 축소
              margin: const EdgeInsets.only(bottom: 4), // 6에서 4로 축소
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade50,
                    Colors.orange.shade100,
                  ],
                ),
                borderRadius: BorderRadius.circular(10), // 12에서 10으로 축소
                border: Border.all(
                  color: Colors.orange.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3), // 4에서 3으로 축소
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4), // 6에서 4로 축소
                    ),
                    child: Icon(
                      Icons.wifi_off,
                      color: Colors.orange.shade600,
                      size: 12, // 14에서 12로 축소
                    ),
                  ),
                  const SizedBox(width: 6), // 8에서 6으로 축소
                  Text(
                    '오프라인 모드',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 11, // 12에서 11로 축소
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6), // 8에서 6으로 축소
                  _buildRetryButton(),
                ],
              ),
            ),
          // 🔥 카테고리 버튼들은 항상 표시
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6), // 8에서 6으로 축소
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E3A8A).withValues(alpha: 0.1),
              const Color(0xFF3B82F6).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh,
              size: 16,
              color: const Color(0xFF1E3A8A),
            ),
            const SizedBox(width: 4),
            Text(
              '재시도',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w600,
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
      borderRadius: BorderRadius.circular(12), // 16에서 12로 축소
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected 
            ? [
                BoxShadow(
                  color: const Color(0xFF667eea).withValues(alpha: 0.4), // 보라색 그림자
                  blurRadius: 8, // 12에서 8로 축소
                  offset: const Offset(0, 2), // 4에서 2로 축소
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: const Color(0xFF764ba2).withValues(alpha: 0.2), // 진한 보라색 그림자
                  blurRadius: 12, // 20에서 12로 축소
                  offset: const Offset(0, 4), // 8에서 4로 축소
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4, // 8에서 4로 축소
                  offset: const Offset(0, 1), // 2에서 1로 축소
                ),
              ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 16,10에서 12,6으로 축소
          decoration: BoxDecoration(
            gradient: isSelected 
              ? const LinearGradient(
                  colors: [
                    Color(0xFF667eea), // 보라색 계열
                    Color(0xFF764ba2), // 진한 보라색
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
            borderRadius: BorderRadius.circular(12), // 16에서 12로 축소
            border: Border.all(
              color: isSelected 
                ? const Color(0xFF667eea) // 보라색 테두리
                : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1.0, // 2.0,1.5에서 1.5,1.0으로 축소
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(isSelected ? 3 : 2), // 5,3에서 3,2로 축소
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Colors.white.withValues(alpha: 0.25) // 더 밝은 흰색 배경
                    : const Color(0xFF667eea).withValues(alpha: 0.1), // 보라색 배경
                  borderRadius: BorderRadius.circular(4), // 6에서 4로 축소
                ),
                child: Icon(
                  icon,
                  size: isSelected ? 14 : 12, // 18,16에서 14,12로 축소
                  color: isSelected 
                    ? Colors.white 
                    : const Color(0xFF667eea), // 보라색 아이콘
                ),
              ),
              const SizedBox(width: 6), // 8에서 6으로 축소
              Text(
                CategoryLocalization.getLabel(context, category),
                style: TextStyle(
                  fontSize: isSelected ? 11 : 10, // 13,12에서 11,10으로 축소
                  color: isSelected 
                    ? Colors.white 
                    : const Color(0xFF667eea), // 보라색 텍스트
                  fontWeight: isSelected 
                    ? FontWeight.w700 
                    : FontWeight.w600,
                  letterSpacing: isSelected ? 0.1 : 0.0, // 0.2에서 0.1로 축소
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
