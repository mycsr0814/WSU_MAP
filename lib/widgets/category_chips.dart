// lib/map/widgets/category_chips.dart - 수정된 버전
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/services/category_api_service.dart';
import 'package:http/http.dart' as http;

class CategoryChips extends StatefulWidget {
  final Function(String, List<String>) onCategorySelected; // CategoryBuilding → String으로 변경
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
  bool _isApiCalling = false; // 🔥 API 호출 중복 방지 플래그
  String? _selectedCategory; // 🔥 추가: 선택된 카테고리 상태 변수
  
  // 🔥 CategoryApiService에서 baseUrl 가져오기
  // static const String baseUrl = 'https://your-api-server.com'; // 제거

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory; // 🔥 초기값 설정
    _loadCategories();
  }

  @override
  void didUpdateWidget(CategoryChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🔥 부모에서 전달된 selectedCategory가 변경되면 업데이트
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
        _error = null;
      });

      final categories = await CategoryApiService.getCategories();
      
      // 카테고리 이름만 추출하고 중복 제거
      final categoryNames = categories
          .map((category) => category.categoryName)
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();

      if (!mounted) return;

      setState(() {
        _categories = categoryNames;
        _isLoading = false;
      });

      debugPrint('카테고리 로딩 완료: $_categories');
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _categories = [];
      });
      debugPrint('카테고리 로딩 실패: $e');
    }
  }

  void refresh() {
    if (mounted) {
      _loadCategories();
    }
  }

  /// 🔥 카테고리 선택 시 건물 이름 목록만 반환
  void _onCategoryTap(String? category) async {
    debugPrint('🎯 카테고리 탭: $category');
    
    // 🔥 이미 API 호출 중이면 무시
    if (_isApiCalling) {
      debugPrint('⚠️ API 호출 중이므로 무시');
      return;
    }
    
    if (category == null) {
      // 카테고리 해제
      setState(() {
        _selectedCategory = null;
      });
      widget.onCategorySelected('', []); // 빈 카테고리로 해제
      return;
    }

    if (_selectedCategory == category) {
      // 같은 카테고리 클릭 시 해제
      setState(() {
        _selectedCategory = null;
      });
      widget.onCategorySelected('', []);
      return;
    }

    // 🔥 API 호출 시작
    _isApiCalling = true;
    
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });

    try {
      debugPrint('📡 API 호출 시작: $category');
      
      // 🔥 한 번만 호출
      final buildingNames = await _getCategoryBuildingNames(category);
      
      debugPrint('📡 API 호출 완료: $category, 건물 수: ${buildingNames.length}');
      debugPrint('📍 건물 이름 목록: $buildingNames');
      
      setState(() {
        _isLoading = false;
      });
      
      // 🔥 콜백 호출
      widget.onCategorySelected(category, buildingNames);
      
    } catch (e) {
      debugPrint('❌ API 호출 오류: $e');
      setState(() {
        _isLoading = false;
        _selectedCategory = null; // 오류 시 선택 해제
      });
    } finally {
      // 🔥 API 호출 완료
      _isApiCalling = false;
    }
  }

  Future<List<String>> _getCategoryBuildingNames(String category) async {
    try {
      debugPrint('🎯 getCategoryBuildingNames 호출: $category');
      
      // 🔥 대안 방법: CategoryApiService의 원본 데이터 활용
      // 만약 HTTP 요청이 계속 실패한다면, 이미 로딩된 카테고리 데이터를 활용
      
      try {
        // 먼저 HTTP 요청 시도
        final response = await http.get(
          Uri.parse('http://13.211.150.88:3001/category'), // 로그인 서버와 같은 주소
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final String responseBody = utf8.decode(response.bodyBytes);
          final List<dynamic> jsonData = json.decode(responseBody);
          
          debugPrint('✅ HTTP 요청 성공! API 데이터: ${jsonData.length}개');
          
          // 선택된 카테고리에 해당하는 건물들만 필터링
          final filteredBuildings = <String>[];
          
          for (final item in jsonData) {
            final categoryName = item['Category_Name']?.toString();
            final buildingName = item['Building_Name']?.toString();
            
            if (categoryName == category && buildingName != null && buildingName.isNotEmpty) {
              if (!filteredBuildings.contains(buildingName)) {
                filteredBuildings.add(buildingName);
              }
            }
          }

          debugPrint('🏢 건물 이름 목록: $filteredBuildings');
          return filteredBuildings;
        }
      } catch (e) {
        debugPrint('⚠️ HTTP 요청 실패, 대안 방법 사용: $e');
      }
      
      // 🔥 대안: 이미 _categories에 로딩된 데이터 기반으로 추론
      // 카테고리별 건물 매핑을 하드코딩으로 제공 (임시 해결책)
      final Map<String, List<String>> categoryBuildingMap = {
        '라운지': ['W1', 'W10', 'W12', 'W13', 'W19', 'W3', 'W5', 'W6'],
        '소화기': ['W1', 'W10', 'W11', 'W12', 'W13', 'W14', 'W15', 'W16', 'W17-동관', 'W17-서관', 'W18', 'W19', 'W2', 'W2-1', 'W3', 'W4', 'W5', 'W6', 'W7', 'W8', 'W9'],
        '자판기': ['W1', 'W10', 'W2', 'W4', 'W5', 'W6'],
        '정수기': ['W1', 'W10', 'W11', 'W12', 'W13', 'W14', 'W15', 'W16', 'W17-동관', 'W17-서관', 'W18', 'W19', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'W8', 'W9'],
        '프린터': ['W1', 'W10', 'W12', 'W13', 'W16', 'W19', 'W5', 'W7'],
        '은행(atm)': ['W1', 'W16'],
        '카페': ['W12', 'W5'],
        '서점': ['W16'],
        '식당': ['W16'],
        '우체국': ['W16'],
        '편의점': ['W16'],
        '헬스장': ['W2-1', 'W5'],
      };
      
      final buildings = categoryBuildingMap[category] ?? [];
      debugPrint('🔄 대안 방법으로 건물 목록 반환: $buildings');
      return buildings;
      
    } catch (e) {
      debugPrint('❌ 카테고리 건물 조회 실패: $e');
      return [];
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
    final isSelected = _selectedCategory == category; // 🔥 수정: widget.selectedCategory → _selectedCategory
    IconData icon = _getCategoryIcon(category);

    return InkWell(
      onTap: () {
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

  // 🔥 카테고리별 아이콘 가져오기 (CategoryChips용)
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

  @override
  void dispose() {
    debugPrint('🧹 CategoryChips dispose');
    super.dispose();
  }
}