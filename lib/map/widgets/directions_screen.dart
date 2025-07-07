// lib/map/widgets/directions_screen.dart - 완성된 길찾기 화면

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/map/building_data.dart';
import 'package:flutter_application_1/managers/location_manager.dart';
import 'package:provider/provider.dart';

class DirectionsScreen extends StatefulWidget {
  const DirectionsScreen({super.key});

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
  List<Building> _recentSearches = [
    // 샘플 최근 검색 데이터
  ];

  @override
  void initState() {
    super.initState();
    // initState에서 BuildingDataProvider 호출하지 않음
    _recentSearches = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 여기서 BuildingDataProvider 초기화
    _initializeSampleData();
  }

  void _initializeSampleData() {
    // 샘플 건물 데이터를 실제 건물 데이터에서 가져오기
    try {
      final buildings = BuildingDataProvider.getBuildingData(context);
      if (buildings.isNotEmpty) {
        // 첫 번째 건물을 샘플로 사용하되, 안전하게 처리
        setState(() {
          _recentSearches = [buildings.first];
        });
      }
    } catch (e) {
      print('샘플 데이터 초기화 오류: $e');
      // 오류시 빈 리스트로 초기화
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
      // BuildingDataProvider를 사용하여 건물 데이터 가져오기
      final buildings = BuildingDataProvider.getBuildingData(context);
      
      return buildings.where((building) {
        final nameMatch = building.name.toLowerCase().contains(lowercaseQuery);
        final infoMatch = building.info.toLowerCase().contains(lowercaseQuery);
        final categoryMatch = building.category.toLowerCase().contains(lowercaseQuery);
        final descriptionMatch = building.description.toLowerCase().contains(lowercaseQuery);
        
        return nameMatch || infoMatch || categoryMatch || descriptionMatch;
      }).toList();
    } catch (e) {
      print('BuildingDataProvider 오류: $e');
      // 오류시 빈 리스트 반환
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
    // 최근 검색에 추가
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

  void _startNavigation() {
    if (_startBuilding != null && _endBuilding != null) {
      // "내 위치"인 경우와 일반 건물인 경우를 구분해서 처리
      if (_startBuilding!.name == '내 위치') {
        // 현재 위치에서 목적지로의 길찾기
        Navigator.pop(context, {
          'start': null, // null이면 현재 위치 사용
          'end': _endBuilding,
          'useCurrentLocation': true,
        });
      } else {
        // 일반 건물 간 길찾기
        Navigator.pop(context, {
          'start': _startBuilding,
          'end': _endBuilding,
          'useCurrentLocation': false,
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _startBuilding!.name == '내 위치' 
                ? '현재 위치에서 ${_endBuilding!.name}으로 길찾기를 시작합니다'
                : '${_startBuilding!.name}에서 ${_endBuilding!.name}으로 길찾기를 시작합니다'
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          duration: const Duration(seconds: 2),
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
      // 검색 모드일 때의 앱바
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
      // 일반 모드일 때의 앱바
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: const Text(
          '길찾기',
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
  }

  Widget _buildSearchView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 최근 검색
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

        // 검색 결과 또는 최근 검색 목록
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
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
    return Column(
      children: [
        const SizedBox(height: 16),
        
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
              const SizedBox(width: 56), // 아이콘 공간만큼 들여쓰기
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
        
        // 안내 메시지
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
        
        // 길찾기 시작 버튼
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
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
              elevation: 0,
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
                  '길찾기 시작',
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
        
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
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
    // 출발지인 경우 "내 위치" 옵션 표시
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
                  // LocationManager를 통해 실제 현재 위치 가져오기
                  try {
                    // 로딩 상태 표시
                    if (mounted) {
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
                    }
                    
                    final locationManager = Provider.of<LocationManager>(context, listen: false);
                    
                    // 이미 최근 위치가 있는지 확인
                    if (locationManager.hasValidLocation && locationManager.currentLocation != null) {
                      print('✅ 기존 위치 사용: ${locationManager.currentLocation!.latitude}, ${locationManager.currentLocation!.longitude}');
                      
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
                      return;
                    }
                    
                    // 새로운 위치 요청
                    print('📍 새로운 위치 요청...');
                    
                    // LocationManager의 onLocationFound 콜백 설정
                    locationManager.onLocationFound = (locationData) {
                      print('✅ 위치 획득 성공: ${locationData.latitude}, ${locationData.longitude}');
                      
                      final myLocationBuilding = Building(
                        name: '내 위치',
                        info: '현재 위치에서 출발',
                        lat: locationData.latitude!,
                        lng: locationData.longitude!,
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
                    };
                    
                    // 위치 요청 실행
                    await locationManager.requestLocation();
                    
                    // 10초 후에도 위치를 못 가져왔으면 기본 위치 사용
                    await Future.delayed(const Duration(seconds: 10));
                    
                    if (mounted && _startBuilding?.name != '내 위치') {
                      print('⚠️ 위치 획득 타임아웃, 기본 위치 사용');
                      
                      final myLocationBuilding = Building(
                        name: '내 위치',
                        info: '현재 위치에서 출발 (기본 위치)',
                        lat: 36.338133, // 우송대학교 중심
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
                      
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              const Text('위치를 가져올 수 없어 기본 위치를 사용합니다'),
                            ],
                          ),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                    
                  } catch (e) {
                    print('❌ 위치 가져오기 실패: $e');
                    
                    // 오류 발생시 기본 위치로 설정
                    final myLocationBuilding = Building(
                      name: '내 위치',
                      info: '현재 위치에서 출발 (기본 위치)',
                      lat: 36.338133, // 우송대학교 중심
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
                              const Icon(Icons.error, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              const Text('위치 서비스를 사용할 수 없어 기본 위치를 사용합니다'),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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