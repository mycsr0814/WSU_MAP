// lib/map/widgets/search_screen.dart - 수정된 전체 화면 검색

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/map/building_data.dart';

class SearchScreen extends StatefulWidget {
  final Function(Building) onBuildingSelected;

  const SearchScreen({
    super.key,
    required this.onBuildingSelected,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Building> _searchResults = [];
  List<Building> _recentSearches = []; // 최근 검색 기록
  bool _isSearching = false;

  // 인기 검색어/카테고리 - 다국어 지원을 위해 한국어와 영어 모두 포함
  final List<String> _popularSearches = [
    '도서관', 'library', '카페', 'cafe', '식당', '체육관', 'gymnasium', 
    '강의실', '기숙사', 'dormitory', '주차장', '편의점'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // 자동으로 검색창에 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = _searchBuildings(query);
    });
  }

  List<Building> _searchBuildings(String query) {
    final lowercaseQuery = query.toLowerCase();
    
    // BuildingDataProvider를 사용하여 건물 데이터 가져오기
    final buildings = BuildingDataProvider.getBuildingData(context);
    
    return buildings.where((building) {
      final nameMatch = building.name.toLowerCase().contains(lowercaseQuery);
      final infoMatch = building.info.toLowerCase().contains(lowercaseQuery);
      final categoryMatch = building.category.toLowerCase().contains(lowercaseQuery);
      final descriptionMatch = building.description.toLowerCase().contains(lowercaseQuery);
      
      return nameMatch || infoMatch || categoryMatch || descriptionMatch;
    }).toList();
  }

  void _onBuildingTap(Building building) {
    // 최근 검색에 추가
    setState(() {
      _recentSearches.removeWhere((b) => b.name == building.name);
      _recentSearches.insert(0, building);
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.take(5).toList();
      }
    });
    
    Navigator.pop(context);
    widget.onBuildingSelected(building);
  }

  void _onPopularSearchTap(String searchTerm) {
    _searchController.text = searchTerm;
    _onSearchChanged();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isSearching 
                ? _buildSearchResults() 
                : _buildDefaultContent(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
      ),
      title: const Text(
        '장소 검색',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: '학교 건물을 검색해주세요',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 15,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search,
              color: Colors.indigo.shade400,
              size: 22,
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: InkWell(
                    onTap: _clearSearch,
                    borderRadius: BorderRadius.circular(12),
                    child: Icon(
                      Icons.clear,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDefaultContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 인기 검색어
          _buildPopularSearches(),
          
          const SizedBox(height: 24),
          
          // 최근 검색
          if (_recentSearches.isNotEmpty) _buildRecentSearches(),
        ],
      ),
    );
  }

  Widget _buildPopularSearches() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.indigo.shade400,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '인기 검색어',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularSearches.map((search) => 
              _buildPopularSearchChip(search)
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularSearchChip(String searchTerm) {
    return InkWell(
      onTap: () => _onPopularSearchTap(searchTerm),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.indigo.shade200),
        ),
        child: Text(
          searchTerm,
          style: TextStyle(
            color: Colors.indigo.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '최근 검색',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _recentSearches.clear();
                  });
                },
                child: Text(
                  '전체 삭제',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final building = _recentSearches[index];
              return _buildRecentSearchItem(building);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearchItem(Building building) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.location_on,
          color: Colors.grey.shade600,
          size: 20,
        ),
      ),
      title: Text(
        building.name,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        building.category,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: IconButton(
        onPressed: () {
          setState(() {
            _recentSearches.removeWhere((b) => b.name == building.name);
          });
        },
        icon: Icon(
          Icons.close,
          color: Colors.grey.shade400,
          size: 18,
        ),
      ),
      onTap: () => _onBuildingTap(building),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final building = _searchResults[index];
        return _buildSearchResultItem(building);
      },
    );
  }

  Widget _buildSearchResultItem(Building building) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.location_on,
          color: Colors.indigo.shade400,
          size: 24,
        ),
      ),
      title: Text(
        building.name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            building.category,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          if (building.info.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              building.info,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: Icon(
        Icons.north_east,
        color: Colors.grey.shade400,
        size: 16,
      ),
      onTap: () => _onBuildingTap(building),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            color: Colors.grey.shade400,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            '검색 결과가 없습니다',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 검색어로 시도해보세요',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}