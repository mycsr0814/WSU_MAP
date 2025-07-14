// lib/map/widgets/category_chips.dart - 안정화된 버전
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/services/category_api_service.dart';
import 'package:flutter_application_1/data/category_fallback_data.dart';
import 'package:http/http.dart' as http;

class CategoryChips extends StatefulWidget {
  final Function(String, List<String>) onCategorySelected;
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
  bool _isApiCalling = false;
  String? _selectedCategory;
  bool _useServerData = true; // 🔥 서버 데이터 사용 여부
  
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

  /// 🔥 개선된 카테고리 로딩 - fallback 지원
  Future<void> _loadCategories() async {
    try {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
        _error = null;
      });

      List<String> categoryNames = [];

      // 🔥 1단계: 서버에서 카테고리 로딩 시도
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
        
        // 🔥 2단계: Fallback 데이터 사용
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
        _error = e.toString();
        _isLoading = false;
        _categories = CategoryFallbackData.getCategories(); // 🔥 최후 fallback
        _useServerData = false;
      });
      debugPrint('❌ 카테고리 로딩 완전 실패, 최후 fallback 사용: $e');
    }
  }

  /// 🔥 서버/Fallback 데이터를 사용한 카테고리별 건물 가져오기
  Future<List<String>> _getCategoryBuildingNames(String category) async {
    try {
      debugPrint('🎯 getCategoryBuildingNames 호출: $category (서버 데이터: $_useServerData)');

      // 🔥 서버 데이터 사용 시도
      if (_useServerData) {
        try {
          debugPrint('📡 서버에서 카테고리별 건물 조회 시도...');
          
          final response = await http.get(
            Uri.parse('http://13.210.72.194:3001/category'),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final String responseBody = utf8.decode(response.bodyBytes);
            final List<dynamic> jsonData = json.decode(responseBody);
            
            debugPrint('✅ 서버 응답 성공! 데이터 개수: ${jsonData.length}개');
            
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

            if (filteredBuildings.isNotEmpty) {
              debugPrint('🏢 서버에서 건물 목록 반환: $filteredBuildings');
              return filteredBuildings;
            } else {
              debugPrint('⚠️ 서버에서 해당 카테고리의 건물을 찾지 못함');
            }
          } else {
            debugPrint('❌ 서버 응답 오류: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ 서버 요청 실패: $e');
        }
      }

      // 🔥 Fallback 데이터 사용
      debugPrint('🔄 Fallback 데이터에서 건물 목록 조회...');
      final buildings = CategoryFallbackData.getBuildingsByCategory(category);
      debugPrint('🏢 Fallback에서 건물 목록 반환: $buildings');
      return buildings;
      
    } catch (e) {
      debugPrint('❌ 카테고리 건물 조회 완전 실패: $e');
      return [];
    }
  }

  /// 🔥 카테고리 선택 처리 - 개선된 오류 처리
  void _onCategoryTap(String? category) async {
    debugPrint('🎯 카테고리 탭: $category');
    
    if (_isApiCalling) {
      debugPrint('⚠️ API 호출 중이므로 무시');
      return;
    }
    
    if (category == null) {
      setState(() {
        _selectedCategory = null;
      });
      widget.onCategorySelected('', []);
      return;
    }

    if (_selectedCategory == category) {
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
        _selectedCategory = null;
      });
      
      // 🔥 오류 시에도 빈 배열로 콜백 호출 (앱 크래시 방지)
      widget.onCategorySelected('', []);
    } finally {
      _isApiCalling = false;
    }
  }

  /// 🔥 새로고침 메서드 (서버 재연결 시도)
  void refresh() {
    if (mounted) {
      _useServerData = true; // 🔥 서버 데이터 재시도
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
          // 🔥 데이터 소스 표시 (디버그용)
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
          
          // 카테고리 칩들
          Expanded(
            child: ListView.separated(
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

  /// 🔥 재시도 버튼
  Widget _buildRetryButton() {
    return InkWell(
      onTap: refresh,
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

  /// 🔥 카테고리별 아이콘 가져오기 - Fallback 데이터와 연동
  IconData _getCategoryIcon(String category) {
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

  @override
  void dispose() {
    debugPrint('🧹 CategoryChips dispose');
    super.dispose();
  }
}