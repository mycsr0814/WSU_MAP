// lib/map/widgets/directions_screen.dart - 길찾기 화면 (네비게이션 상태 추가)

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/map/building_data.dart';
import 'package:flutter_application_1/managers/location_manager.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class DirectionsScreen extends StatefulWidget {
  // preset 매개변수 추가
  final Building? presetStart;
  final Building? presetEnd;

  const DirectionsScreen({
    super.key,
    this.presetStart,
    this.presetEnd,
  });

  @override
  State<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<DirectionsScreen> {
  Building? _startBuilding;
  Building? _endBuilding;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Building> _searchResults = [];
  bool _isSearching = false;
  String? _searchType; // 'start' or 'end'
  List<Building> _recentSearches = [];
  
  // 네비게이션 상태 관련
  bool _isNavigationActive = false;
  String _estimatedDistance = '';
  String _estimatedTime = '';

@override
void initState() {
  super.initState();
  
  // preset 값들로 초기화
  _startBuilding = widget.presetStart;
  _endBuilding = widget.presetEnd;
  
  // 건물 객체 검증
  if (_startBuilding != null) {
    debugPrint('PresetStart 건물: ${_startBuilding!.name}');
    debugPrint('좌표: ${_startBuilding!.lat}, ${_startBuilding!.lng}');
    
    // 좌표가 유효한지 확인
    if (_startBuilding!.lat == 0.0 && _startBuilding!.lng == 0.0) {
      debugPrint('경고: 출발지 좌표가 (0,0)입니다');
    }
  }
  
  if (_endBuilding != null) {
    debugPrint('PresetEnd 건물: ${_endBuilding!.name}');
    debugPrint('좌표: ${_endBuilding!.lat}, ${_endBuilding!.lng}');
  }
  
  _recentSearches = [];
}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeSampleData();
  }

  void _initializeSampleData() {
    try {
      final buildings = BuildingDataProvider.getBuildingData(context);
      if (buildings.isNotEmpty && mounted) {
        setState(() {
          _recentSearches = [buildings.first];
        });
      }
    } catch (e) {
      debugPrint('샘플 데이터 초기화 오류: $e');
      if (mounted) {
        setState(() {
          _recentSearches = [];
        });
      }
    }
  }

  @override
  void dispose() {
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
    
    try {
      final buildings = BuildingDataProvider.getBuildingData(context);
      
      return buildings.where((building) {
        final nameMatch = building.name.toLowerCase().contains(lowercaseQuery);
        final infoMatch = building.info.toLowerCase().contains(lowercaseQuery);
        final categoryMatch = building.category.toLowerCase().contains(lowercaseQuery);
        final descriptionMatch = building.description.toLowerCase().contains(lowercaseQuery);
        
        return nameMatch || infoMatch || categoryMatch || descriptionMatch;
      }).toList();
    } catch (e) {
      debugPrint('BuildingDataProvider 오류: $e');
      return [];
    }
  }

  void _selectStartLocation() {
    setState(() {
      _searchType = 'start';
      _isSearching = false;
      _searchResults = [];
      _searchController.clear();
    });
    _focusNode.requestFocus();
  }

  void _selectEndLocation() {
    setState(() {
      _searchType = 'end';
      _isSearching = false;
      _searchResults = [];
      _searchController.clear();
    });
    _focusNode.requestFocus();
  }

  void _onBuildingSelected(Building building) {
    setState(() {
      _recentSearches.removeWhere((b) => b.name == building.name);
      _recentSearches.insert(0, building);
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.take(5).toList();
      }
    });

    if (_searchType == 'start') {
      setState(() {
        _startBuilding = building;
        _searchType = null;
        _isSearching = false;
        _searchResults = [];
        _searchController.clear();
      });
    } else if (_searchType == 'end') {
      setState(() {
        _endBuilding = building;
        _searchType = null;
        _isSearching = false;
        _searchResults = [];
        _searchController.clear();
      });
    }
    _focusNode.unfocus();
  }

  void _swapLocations() {
    if (_startBuilding != null && _endBuilding != null) {
      setState(() {
        final temp = _startBuilding;
        _startBuilding = _endBuilding;
        _endBuilding = temp;
      });
    }
  }

  // 거리 계산 함수 (Haversine 공식)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // 지구 반지름 (미터)
    
    double dLat = (lat2 - lat1) * (math.pi / 180);
    double dLon = (lon2 - lon1) * (math.pi / 180);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c; // 미터 단위
  }

  // 예상 시간과 거리 계산
  void _calculateRouteEstimates() {
    if (_startBuilding != null && _endBuilding != null) {
      double distance = _calculateDistance(
        _startBuilding!.lat,
        _startBuilding!.lng,
        _endBuilding!.lat,
        _endBuilding!.lng,
      );
      
      // 거리 포맷팅
      if (distance < 1000) {
        _estimatedDistance = '${distance.round()}m';
      } else {
        _estimatedDistance = '${(distance / 1000).toStringAsFixed(1)}km';
      }
      
      // 예상 시간 계산 (평균 도보 속도 4km/h 기준)
      double walkingSpeedKmh = 4.0;
      double timeInHours = distance / 1000 / walkingSpeedKmh;
      int timeInMinutes = (timeInHours * 60).round();
      
      if (timeInMinutes < 60) {
        _estimatedTime = '도보 ${timeInMinutes}분';
      } else {
        int hours = timeInMinutes ~/ 60;
        int minutes = timeInMinutes % 60;
        _estimatedTime = '도보 ${hours}시간 ${minutes}분';
      }
    }
  }

void _startNavigation() {
  print('=== 경로 안내 시작 디버깅 ===');
  print('출발지: ${_startBuilding?.name}');
  print('출발지 좌표: ${_startBuilding?.lat}, ${_startBuilding?.lng}');
  print('도착지: ${_endBuilding?.name}');
  print('도착지 좌표: ${_endBuilding?.lat}, ${_endBuilding?.lng}');
  
  if (_startBuilding != null && _endBuilding != null) {
    // 예상 시간과 거리 계산
    _calculateRouteEstimates();
    
    // 바로 map_screen으로 데이터 전달하고 DirectionsScreen 닫기
    final navigationData = {
      'start': _startBuilding!.name == '내 위치' ? null : _startBuilding,
      'end': _endBuilding,
      'useCurrentLocation': _startBuilding!.name == '내 위치',
      'estimatedDistance': _estimatedDistance,
      'estimatedTime': _estimatedTime,
      'showNavigationStatus': true, // 네비게이션 상태 표시 플래그
    };
    
    print('map_screen으로 전달할 데이터: $navigationData');
    
    // 데이터 반환하고 DirectionsScreen 닫기
    Navigator.pop(context, navigationData);
  } else {
    print('출발지 또는 도착지가 null입니다');
    print('_startBuilding null 여부: ${_startBuilding == null}');
    print('_endBuilding null 여부: ${_endBuilding == null}');
    
    // 오류 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('출발지와 도착지를 모두 설정해주세요'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void _cancelSearch() {
    setState(() {
      _searchType = null;
      _isSearching = false;
      _searchResults = [];
      _searchController.clear();
    });
    _focusNode.unfocus();
  }

  void _stopNavigation() {
    setState(() {
      _isNavigationActive = false;
      _estimatedDistance = '';
      _estimatedTime = '';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('길찾기가 종료되었습니다'),
        backgroundColor: Colors.grey,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _searchType != null ? _buildSearchView() : _buildDirectionsView(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_searchType != null) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _cancelSearch,
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
              hintText: _searchType == 'start' ? '출발지를 검색해주세요' : '도착지를 검색해주세요',
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
      );
    } else {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: Text(
          _isNavigationActive ? '길찾기 진행중' : '길찾기',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: _isNavigationActive ? [
          IconButton(
            onPressed: _stopNavigation,
            icon: const Icon(Icons.close, color: Colors.black87),
          ),
        ] : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      );
    }
  }

  Widget _buildSearchView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_recentSearches.isNotEmpty && !_isSearching) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최근 검색',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
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
          ),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: _isSearching ? _buildSearchResults() : _buildRecentSearches(),
        ),
      ],
    );
  }

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return Container();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _recentSearches.length,
      itemBuilder: (context, index) {
        final building = _recentSearches[index];
        return _buildSearchResultItem(building, isRecent: true);
      },
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

  Widget _buildSearchResultItem(Building building, {bool isRecent = false}) {
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
            color: isRecent 
                ? Colors.grey.shade100 
                : const Color(0xFFFF6B6B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            isRecent ? Icons.history : Icons.location_on,
            color: isRecent 
                ? Colors.grey.shade600 
                : const Color(0xFFFF6B6B),
            size: 18,
          ),
        ),
        title: Text(
          building.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          building.info.isNotEmpty ? building.info : building.category,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isRecent
            ? IconButton(
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
              )
            : null,
        onTap: () => _onBuildingSelected(building),
      ),
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

  Widget _buildDirectionsView() {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 16),
            
            // preset 알림 메시지 추가
            if (widget.presetStart != null || widget.presetEnd != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.presetStart != null 
                            ? '${widget.presetStart!.name}이 출발지로 설정되었습니다'
                            : '${widget.presetEnd!.name}이 도착지로 설정되었습니다',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // 출발지 입력
            _buildLocationInput(
              icon: Icons.my_location,
              iconColor: const Color(0xFF10B981),
              hint: '출발지를 입력해주세요',
              selectedBuilding: _startBuilding,
              onTap: _selectStartLocation,
            ),
            
            // 교환 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 56),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _swapLocations,
                        child: Icon(
                          Icons.swap_vert,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 도착지 입력
            _buildLocationInput(
              icon: Icons.location_on,
              iconColor: const Color(0xFFEF4444),
              hint: '도착지를 입력해주세요',
              selectedBuilding: _endBuilding,
              onTap: _selectEndLocation,
            ),
            
            const Spacer(),
            
            // 안내 메시지 (네비게이션이 활성화되지 않은 경우에만 표시)
            if (!_isNavigationActive) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '출발지와 도착지를 설정해주세요',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + (_isNavigationActive ? 160 : 80)),
          ],
        ),
        
        // 네비게이션 상태 표시 (활성화된 경우)
        if (_isNavigationActive) ...[
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 80,
            child: _buildNavigationStatus(),
          ),
        ],
        
        // 하단 고정 버튼
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          child: ElevatedButton(
            onPressed: (_startBuilding != null && _endBuilding != null) 
                ? _startNavigation 
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.grey.shade500,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.navigation,
                  size: 20,
                  color: (_startBuilding != null && _endBuilding != null) 
                      ? Colors.white 
                      : Colors.grey.shade500,
                ),
                const SizedBox(width: 8),
                Text(
                  _isNavigationActive ? '길 안내' : '길찾기 시작',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: (_startBuilding != null && _endBuilding != null) 
                        ? Colors.white 
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 네비게이션 상태 표시 위젯
  Widget _buildNavigationStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(Icons.straighten, '예상 거리', _estimatedDistance.isNotEmpty ? _estimatedDistance : '계산중'),
          Container(
            width: 1,
            height: 30,
            color: Colors.white.withOpacity(0.2),
          ),
          _buildInfoItem(Icons.access_time, '예상 시간', _estimatedTime.isNotEmpty ? _estimatedTime : '계산중'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInput({
    required IconData icon,
    required Color iconColor,
    required String hint,
    required Building? selectedBuilding,
    required VoidCallback onTap,
  }) {
    final bool isStartLocation = hint.contains('출발지');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 기본 위치 입력
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedBuilding != null) ...[
                            Text(
                              selectedBuilding.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            if (selectedBuilding.category.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                selectedBuilding.category,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ] else ...[
                            Text(
                              hint,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 출발지인 경우 "내 위치" 옵션 추가
          if (isStartLocation && selectedBuilding == null) ...[
            const Divider(height: 1),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  try {
                    if (!mounted) return;
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('현재 위치를 가져오는 중...'),
                          ],
                        ),
                        backgroundColor: Color(0xFF2196F3),
                        duration: Duration(seconds: 5),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.all(16),
                      ),
                    );
                    
                    final locationManager = Provider.of<LocationManager>(context, listen: false);
                    
                    if (locationManager.hasValidLocation && locationManager.currentLocation != null) {
                      final myLocationBuilding = Building(
                        name: '내 위치',
                        info: '현재 위치에서 출발',
                        lat: locationManager.currentLocation!.latitude!,
                        lng: locationManager.currentLocation!.longitude!,
                        category: '현재위치',
                        baseStatus: '사용가능',
                        hours: '',
                        phone: '',
                        imageUrl: '',
                        description: '현재 위치에서 길찾기를 시작합니다',
                      );
                      
                      setState(() {
                        _startBuilding = myLocationBuilding;
                      });
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.my_location, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                const Text('현재 위치가 출발지로 설정되었습니다'),
                              ],
                            ),
                            backgroundColor: const Color(0xFF10B981),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    } else {
                      await locationManager.requestLocation();
                      await Future.delayed(const Duration(milliseconds: 500));
                      
                      if (locationManager.hasValidLocation && locationManager.currentLocation != null) {
                        final myLocationBuilding = Building(
                          name: '내 위치',
                          info: '현재 위치에서 출발',
                          lat: locationManager.currentLocation!.latitude!,
                          lng: locationManager.currentLocation!.longitude!,
                          category: '현재위치',
                          baseStatus: '사용가능',
                          hours: '',
                          phone: '',
                          imageUrl: '',
                          description: '현재 위치에서 길찾기를 시작합니다',
                        );
                        
                        if (mounted) {
                          setState(() {
                            _startBuilding = myLocationBuilding;
                          });
                          
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.my_location, color: Colors.white, size: 16),
                                  const SizedBox(width: 8),
                                  const Text('현재 위치가 출발지로 설정되었습니다'),
                                ],
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      } else {
                        throw Exception('위치를 가져올 수 없습니다');
                      }
                    }
                  } catch (e) {
                    final myLocationBuilding = Building(
                      name: '내 위치',
                      info: '현재 위치에서 출발 (기본 위치)',
                      lat: 36.338133,
                      lng: 127.446423,
                      category: '현재위치',
                      baseStatus: '사용가능',
                      hours: '',
                      phone: '',
                      imageUrl: '',
                      description: '현재 위치에서 길찾기를 시작합니다',
                    );
                    
                    setState(() {
                      _startBuilding = myLocationBuilding;
                    });
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              const Text('기본 위치를 사용합니다'),
                            ],
                          ),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Color(0xFF2196F3),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '내 위치',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '현재 위치에서 출발',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.gps_fixed,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}