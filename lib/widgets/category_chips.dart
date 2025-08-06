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
  // 🔥 고정된 카테고리 목록 (UI는 항상 이걸 사용)
  final List<String> _fixedCategories = CategoryFallbackData.getCategories();
  
  // 🔥 서버에서 받은 카테고리 (별도 관리)
  List<String> _serverCategories = [];
  
  String? _selectedCategory;
  bool _isLoading = false;
  bool _isApiCalling = false;
  bool _isDisposed = false;

  // 외부에서 카테고리 선택을 위한 메서드
  void selectCategory(String category) {
    if (!mounted || _isDisposed) return;
    
    debugPrint('🎯 selectCategory 호출됨: $category');
    
    if (_fixedCategories.contains(category)) {
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
    
    // 🔥 백그라운드에서 서버 데이터 시도 (UI에는 영향 없음)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _loadCategoriesFromServer();
      }
    });
  }

  @override
  void didUpdateWidget(CategoryChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory != oldWidget.selectedCategory && mounted && !_isDisposed) {
      setState(() {
        _selectedCategory = widget.selectedCategory;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void refresh() {
    if (mounted && !_isDisposed) {
      debugPrint('🔄 카테고리 새로고침');
      _loadCategoriesFromServer();
    }
  }

  /// 🔥 서버에서 카테고리 로드 (백그라운드에서 실행) - UI에 영향 없음
  Future<void> _loadCategoriesFromServer() async {
    if (!mounted || _isDisposed) return;

    // 이미 로딩 중이면 중복 실행 방지
    if (_isLoading) {
      debugPrint('⚠️ 이미 로딩 중이므로 서버 요청 건너뜀');
      return;
    }

    // 🔥 로딩 상태만 업데이트 (UI 카테고리는 변경하지 않음)
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔄 서버에서 카테고리 로드 시작...');
      
      final categories = await CategoryApiService.getCategories();
      final categoryNames = categories
          .map((category) => category.categoryName)
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      if (categoryNames.isNotEmpty && mounted && !_isDisposed) {
        debugPrint('✅ 서버에서 카테고리 로딩 성공: ${categoryNames.length}개');
        
        // 🔥 서버 데이터는 별도로 저장 (UI에는 영향 없음)
        _serverCategories = categoryNames;
        setState(() {
          _isLoading = false;
        });
        debugPrint('🔄 서버 카테고리 데이터 저장됨 (UI는 그대로)');
      } else {
        debugPrint('⚠️ 서버에서 빈 카테고리 목록 반환');
        if (mounted && !_isDisposed) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ 서버 카테고리 로딩 실패: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onCategoryTap(String? category) async {
    debugPrint('🎯 카테고리 탭: $category');

    if (_isApiCalling || !mounted || _isDisposed) {
      debugPrint('⚠️ API 호출 중이거나 위젯이 dispose됨');
      return;
    }

    if (category == null) {
      if (mounted && !_isDisposed) {
        setState(() {
          _selectedCategory = null;
        });
      }
      widget.onCategorySelected('', []);
      return;
    }

    if (_selectedCategory == category) {
      // 같은 카테고리를 다시 누르면 선택 해제
      debugPrint('🎯 같은 카테고리 재선택 → 해제: $category');
      if (mounted && !_isDisposed) {
        setState(() {
          _selectedCategory = null;
        });
      }
      widget.onCategorySelected('', []);
      return;
    }

    _isApiCalling = true;

    if (mounted && !_isDisposed) {
      setState(() {
        _selectedCategory = category;
      });
    }

    try {
      debugPrint('📡 카테고리 선택: $category');

      // 🔥 서버에서 건물 정보 가져오기
      final buildingInfoList = await _getCategoryBuildingInfoList(category);

      debugPrint('📡 카테고리 선택 완료: $category, 건물 수: ${buildingInfoList.length}');

      if (mounted && !_isDisposed) {
        widget.onCategorySelected(category, buildingInfoList);
      }
    } catch (e) {
      debugPrint('❌ 카테고리 선택 오류: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _selectedCategory = null;
        });
        widget.onCategorySelected('', []);
      }
    } finally {
      _isApiCalling = false;
    }
  }

  /// 카테고리별 건물 정보 가져오기 (서버 요청)
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
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 🔥 로딩 중일 때만 상단에 인디케이터 표시 (카테고리는 계속 보이도록)
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                    const Color(0xFF3B82F6).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '카테고리 업데이트 중...',
                    style: TextStyle(
                      color: const Color(0xFF1E3A8A),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          
          // 🔥 카테고리 버튼들은 항상 표시 (로딩 중에도 유지)
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _fixedCategories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final category = _fixedCategories[index];
                return _buildCategoryChip(category);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    // 🔥 카테고리 이름을 영어 ID로 변환하여 아이콘 가져오기
    final categoryId = _getCategoryId(category);
    final icon = CategoryFallbackData.getCategoryIcon(categoryId);

    return InkWell(
      onTap: () {
        if (mounted && !_isDisposed) {
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

  /// 🔥 카테고리 이름을 영어 ID로 변환
  String _getCategoryId(String categoryName) {
    // 한국어 카테고리 이름을 영어 ID로 매핑
    switch (categoryName.toLowerCase().trim()) {
      case '카페':
        return 'cafe';
      case '식당':
        return 'restaurant';
      case '편의점':
        return 'convenience';
      case '자판기':
        return 'vending';
      case '화장실':
      case '정수기':
        return 'water';
      case '프린터':
        return 'printer';
      case '복사기':
        return 'copier';
      case 'atm':
      case '은행(atm)':
        return 'atm';
      case '의료':
      case '보건소':
        return 'medical';
      case '도서관':
        return 'library';
      case '체육관':
      case '헬스장':
        return 'gym';
      case '라운지':
        return 'lounge';
      case '소화기':
        return 'extinguisher';
      case '서점':
        return 'bookstore';
      case '우체국':
        return 'post';
      default:
        // 이미 영어 ID인 경우 그대로 반환
        return categoryName;
    }
  }
}
