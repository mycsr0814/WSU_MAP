// lib/map/widgets/search_screen.dart - 강의실 직접 이동 기능 추가

import 'package:flutter/material.dart';
import 'package:flutter_application_1/generated/app_localizations.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/models/search_result.dart';
import 'package:flutter_application_1/services/integrated_search_service.dart';
// 🔥 BuildingMapPage import 추가
import 'package:flutter_application_1/inside/building_map_page.dart';

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
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

String _lastQuery = '';

Future<void> _onSearchChanged() async {
  final query = _searchController.text.trim();
  _lastQuery = query;

  if (query.isEmpty) {
    setState(() {
      _searchResults = [];
      _isSearching = false;
      _isLoading = false;
    });
    return;
  }

  setState(() {
    _isSearching = true;
    _isLoading = true;
  });

  try {
    final results = await IntegratedSearchService.search(query, context);
    if (mounted && _lastQuery == query) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  } catch (e) {
    debugPrint('검색 오류: $e');
    if (mounted && _lastQuery == query) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }
}

  // 🔥 기존 _onResultSelected 메서드 수정
  void _onResultSelected(SearchResult result) {
    if (result.isRoom) {
      // 🔥 강의실인 경우 BuildingMapPage로 직접 이동
      _navigateToRoom(result);
    } else {
      // 건물인 경우 기존 방식대로
      widget.onBuildingSelected(result.building);
      Navigator.pop(context);
    }
  }

  // 🔥 새로 추가: 강의실로 직접 이동하는 메서드
  void _navigateToRoom(SearchResult result) {
    final buildingCode = _extractBuildingCode(result.building.name);
    
    debugPrint('🎯 강의실로 바로 이동: ${result.displayName}');
    debugPrint('   건물: $buildingCode');
    debugPrint('   층: ${result.floorNumber}');
    debugPrint('   호실: ${result.roomNumber}');
    
    // 사용자에게 이동 중임을 알림
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result.displayName}로 이동 중...'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
    
    // BuildingMapPage로 직접 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BuildingMapPage(
          buildingName: buildingCode,
          targetRoomId: result.roomNumber,      // 🔥 자동 선택할 강의실
          targetFloorNumber: result.floorNumber, // 🔥 해당 층으로 이동
        ),
      ),
    );
  }

  // 🔥 건물명에서 건물 코드 추출 헬퍼 메서드
  String _extractBuildingCode(String buildingName) {
    final regex = RegExp(r'\(([^)]+)\)');
    final match = regex.firstMatch(buildingName);
    if (match != null) {
      return match.group(1)!;
    }
    final spaceSplit = buildingName.trim().split(' ');
    if (spaceSplit.isNotEmpty && RegExp(r'^[A-Za-z0-9\-]+$').hasMatch(spaceSplit[0])) {
      return spaceSplit[0];
    }
    return buildingName;
  }

  @override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return Scaffold(
    backgroundColor: Colors.grey.shade50,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
      ),
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: (_) => _onSearchChanged(),
          decoration: InputDecoration(
            hintText: l10n.searchHint, // ✅ 다국어 처리된 안내문
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.search,
                color: Colors.indigo.shade400,
                size: 20,
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged();
                    },
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey.shade200,
        ),
      ),
    ),
    body: _buildBody(),
  );
}

  Widget _buildBody() {
    if (!_isSearching) {
      return _buildInitialState();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }

    return _buildSearchResults();
  }

  Widget _buildInitialState() {
  final l10n = AppLocalizations.of(context)!;

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.search, color: Colors.grey, size: 64),
        const SizedBox(height: 16),
        Text(
          l10n.searchInitialGuide,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.searchHintExample,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    ),
  );
}

Widget _buildLoadingState() {
  final l10n = AppLocalizations.of(context)!;

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.indigo),
        const SizedBox(height: 16),
        Text(
          l10n.searchLoading,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ],
    ),
  );
}

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildSearchResultItem(result);
      },
    );
  }

  // 🔥 검색 결과 아이템 - 강의실 표시 개선
  Widget _buildSearchResultItem(SearchResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: result.isBuilding
                ? const Color(0xFF3B82F6).withOpacity(0.1)
                : const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            result.isBuilding ? Icons.business : Icons.room,
            color: result.isBuilding
                ? const Color(0xFF3B82F6)
                : const Color(0xFF10B981),
            size: 18,
          ),
        ),
        title: Text(
          result.displayName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          result.isRoom
              ? '${result.floorNumber}층 • ${result.roomDescription ?? '강의실'}'  // 🔥 층 정보 추가
              : result.building.info.isNotEmpty 
                  ? result.building.info 
                  : result.building.category,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔥 강의실인 경우 직접 이동 표시
            if (result.isRoom) 
              Icon(
                Icons.map,
                color: Colors.green.shade600,
                size: 16,
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
        onTap: () => _onResultSelected(result),
      ),
    );
  }

 Widget _buildNoResults() {
  final l10n = AppLocalizations.of(context)!;

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, color: Colors.grey.shade400, size: 64),
        const SizedBox(height: 16),
        Text(
          l10n.searchNoResult,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.searchTryAgain,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    ),
  );
}

}