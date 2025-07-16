// lib/map/widgets/directions_screen.dart - 통합 API 적용 버전 (수정됨)

import 'package:flutter/material.dart';
import 'package:flutter_application_1/inside/building_map_page.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/models/search_result.dart';
import 'package:flutter_application_1/services/integrated_search_service.dart';
import 'package:flutter_application_1/map/building_data.dart';
import 'package:flutter_application_1/managers/location_manager.dart';
import 'package:flutter_application_1/unified_navigation_stepper_page.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:flutter_naver_map/flutter_naver_map.dart';

// 🔥 통합 API 관련 imports
import 'package:flutter_application_1/services/unified_path_service.dart';

class DirectionsScreen extends StatefulWidget {
  final Building? presetStart;
  final Building? presetEnd;
  final Map<String, dynamic>? roomData;

  const DirectionsScreen({
    super.key,
    this.presetStart,
    this.presetEnd,
    this.roomData,
  });

  @override
  State<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<DirectionsScreen> {
  Building? _startBuilding;
  Building? _endBuilding;
  
  // 🔥 호실 정보 추가
  Map<String, dynamic>? _startRoomInfo;
  Map<String, dynamic>? _endRoomInfo;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String? _searchType; // 'start' or 'end'
  List<Building> _recentSearches = [];

  bool _needsCoordinateUpdate = false;
  
  // 네비게이션 상태 관련
  bool _isNavigationActive = false;
  String _estimatedDistance = '';
  String _estimatedTime = '';
  
  // 🔥 통합 API 미리보기 정보
  UnifiedPathResponse? _previewResponse;
  bool _isCalculatingPreview = false;

  @override
void initState() {
  super.initState();
  
  if (widget.roomData != null) {
    _handleRoomData(widget.roomData!);
  } else {
    // 🔥 preset 건물들도 건물 코드 추출
    if (widget.presetStart != null) {
      final startCode = _extractBuildingCode(widget.presetStart!.name);
      _startBuilding = Building(
        name: startCode,
        info: widget.presetStart!.info,
        lat: widget.presetStart!.lat,
        lng: widget.presetStart!.lng,
        category: widget.presetStart!.category,
        baseStatus: widget.presetStart!.baseStatus,
        hours: widget.presetStart!.hours,
        phone: widget.presetStart!.phone,
        imageUrl: widget.presetStart!.imageUrl,
        description: widget.presetStart!.description,
      );
    }
    
    if (widget.presetEnd != null) {
      final endCode = _extractBuildingCode(widget.presetEnd!.name);
      _endBuilding = Building(
        name: endCode,
        info: widget.presetEnd!.info,
        lat: widget.presetEnd!.lat,
        lng: widget.presetEnd!.lng,
        category: widget.presetEnd!.category,
        baseStatus: widget.presetEnd!.baseStatus,
        hours: widget.presetEnd!.hours,
        phone: widget.presetEnd!.phone,
        imageUrl: widget.presetEnd!.imageUrl,
        description: widget.presetEnd!.description,
      );
    }
  }
  
  if (_startBuilding != null) {
    debugPrint('PresetStart 건물: ${_startBuilding!.name}');
    if (_startBuilding!.lat == 0.0 && _startBuilding!.lng == 0.0) {
      debugPrint('경고: 출발지 좌표가 (0,0)입니다');
    }
  }
  
  if (_endBuilding != null) {
    debugPrint('PresetEnd 건물: ${_endBuilding!.name}');
  }
  
  _recentSearches = [];
  
  // 출발지와 도착지가 모두 설정되면 미리보기 계산
  if (_startBuilding != null && _endBuilding != null) {
    _calculateRoutePreview();
  }
}

void _handleRoomData(Map<String, dynamic> roomData) {
  try {
    debugPrint('=== _handleRoomData 시작 ===');
    debugPrint('받은 방 정보: $roomData');

    final String roomName = (roomData['roomName'] ?? '').toString();
    final String buildingNameRaw = (roomData['buildingName'] ?? '').toString();
    final String buildingName = _extractBuildingCode(buildingNameRaw); // 🔥 건물 코드만 사용
    final String type = (roomData['type'] ?? '').toString();

    final String floorNumberStr = (roomData['floorNumber'] ?? '1').toString(); // 🔥 항상 문자열

    final roomInfo = {
      'roomName': roomName,
      'buildingName': buildingName,
      'floorNumber': floorNumberStr,
    };

    final roomBuilding = Building(
      name: buildingName,
      info: '${floorNumberStr.isNotEmpty ? "${floorNumberStr}층 " : ""}$roomName호',
      lat: 0.0,
      lng: 0.0,
      category: '강의실',
      baseStatus: '사용가능',
      hours: '',
      phone: '',
      imageUrl: '',
      description: '$buildingName ${floorNumberStr.isNotEmpty ? "${floorNumberStr}층 " : ""}$roomName호',
    );

    if (type == 'start') {
      setState(() {
        _startBuilding = roomBuilding;
        _startRoomInfo = roomInfo;
      });
      debugPrint('출발지로 설정: $buildingName ($floorNumberStr층 $roomName호)');
    } else if (type == 'end') {
      setState(() {
        _endBuilding = roomBuilding;
        _endRoomInfo = roomInfo;
      });
      debugPrint('도착지로 설정: $buildingName ($floorNumberStr층 $roomName호)');
    }

    _needsCoordinateUpdate = true;

    debugPrint('=== _handleRoomData 완료 ===');
  } catch (e, stackTrace) {
    debugPrint('❌ _handleRoomData 오류: $e');
    debugPrint('스택 트레이스: $stackTrace');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('방 정보 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


// 🔥 추가: 건물명에서 건물 코드 추출 헬퍼 메서드

// 6. _extractBuildingCode 헬퍼 메서드 (이미 제공했지만 다시 포함)
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
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
void didChangeDependencies() {
  super.didChangeDependencies();
  
  // 🔥 좌표 업데이트가 필요한 경우
  if (_needsCoordinateUpdate) {
    _updateBuildingCoordinates();
    _needsCoordinateUpdate = false;
  }
}

void _updateBuildingCoordinates() {
  try {
    final buildings = BuildingDataProvider.getBuildingData(context);
    
    // 출발지 좌표 업데이트
    if (_startBuilding != null && _startBuilding!.lat == 0.0) {
      final matchingBuilding = _findMatchingBuilding(buildings, _startBuilding!.name);
      if (matchingBuilding != null) {
        setState(() {
          _startBuilding = Building(
            name: _startBuilding!.name,
            info: _startBuilding!.info,
            lat: matchingBuilding.lat,
            lng: matchingBuilding.lng,
            category: _startBuilding!.category,
            baseStatus: _startBuilding!.baseStatus,
            hours: _startBuilding!.hours,
            phone: _startBuilding!.phone,
            imageUrl: _startBuilding!.imageUrl,
            description: _startBuilding!.description,
          );
        });
        debugPrint('✅ 출발지 좌표 업데이트: ${_startBuilding!.name} -> (${matchingBuilding.lat}, ${matchingBuilding.lng})');
      } else {
        debugPrint('⚠️ 출발지 건물 좌표를 찾을 수 없음: ${_startBuilding!.name}');
      }
    }
    
    // 도착지 좌표 업데이트
    if (_endBuilding != null && _endBuilding!.lat == 0.0) {
      final matchingBuilding = _findMatchingBuilding(buildings, _endBuilding!.name);
      if (matchingBuilding != null) {
        setState(() {
          _endBuilding = Building(
            name: _endBuilding!.name,
            info: _endBuilding!.info,
            lat: matchingBuilding.lat,
            lng: matchingBuilding.lng,
            category: _endBuilding!.category,
            baseStatus: _endBuilding!.baseStatus,
            hours: _endBuilding!.hours,
            phone: _endBuilding!.phone,
            imageUrl: _endBuilding!.imageUrl,
            description: _endBuilding!.description,
          );
        });
        debugPrint('✅ 도착지 좌표 업데이트: ${_endBuilding!.name} -> (${matchingBuilding.lat}, ${matchingBuilding.lng})');
      } else {
        debugPrint('⚠️ 도착지 건물 좌표를 찾을 수 없음: ${_endBuilding!.name}');
      }
    }
    
    // 좌표 업데이트 후 미리보기 재계산
    if (_startBuilding != null && _endBuilding != null) {
      _calculateRoutePreview();
    }
  } catch (e) {
    debugPrint('❌ 건물 좌표 업데이트 오류: $e');
  }
}

Building? _findMatchingBuilding(List<Building> buildings, String buildingCode) {
  try {
    return buildings.firstWhere(
      (building) => 
        building.name.contains(buildingCode) || 
        building.name == buildingCode ||
        _extractBuildingCode(building.name) == buildingCode,
    );
  } catch (e) {
    // firstWhere에서 찾지 못하면 StateError가 발생하므로 null 반환
    return null;
  }
}

  // 🔥 통합 API를 사용한 경로 미리보기 계산
  // 3. 경로 미리보기 계산 시 (건물 코드/층번호 일치 보장)
Future<void> _calculateRoutePreview() async {
  if (_startBuilding == null || _endBuilding == null) return;

  setState(() => _isCalculatingPreview = true);

  try {
    debugPrint('🔍 경로 미리보기 계산 시작');

    UnifiedPathResponse? response;

    if (_startRoomInfo != null && _endRoomInfo != null) {
      response = await UnifiedPathService.getPathBetweenRooms(
        fromBuilding: _startRoomInfo!['buildingName'],
        fromFloor: int.tryParse(_startRoomInfo!['floorNumber'] ?? '1') ?? 1,
        fromRoom: _startRoomInfo!['roomName'],
        toBuilding: _endRoomInfo!['buildingName'],
        toFloor: int.tryParse(_endRoomInfo!['floorNumber'] ?? '1') ?? 1,
        toRoom: _endRoomInfo!['roomName'],
      );
    } else if (_startRoomInfo != null) {
      response = await UnifiedPathService.getPathFromRoom(
        fromBuilding: _startRoomInfo!['buildingName'],
        fromFloor: int.tryParse(_startRoomInfo!['floorNumber'] ?? '1') ?? 1,
        fromRoom: _startRoomInfo!['roomName'],
        toBuilding: _endBuilding!,
      );
    } else if (_endRoomInfo != null) {
      response = await UnifiedPathService.getPathToRoom(
        fromBuilding: _startBuilding!,
        toBuilding: _endRoomInfo!['buildingName'],
        toFloor: int.tryParse(_endRoomInfo!['floorNumber'] ?? '1') ?? 1,
        toRoom: _endRoomInfo!['roomName'],
      );
    } else if (_startBuilding!.name == '내 위치') {
      final locationManager = Provider.of<LocationManager>(context, listen: false);
      if (locationManager.hasValidLocation) {
        final currentLocation = locationManager.currentLocation!;
        response = await UnifiedPathService.getPathFromLocation(
          fromLocation: NLatLng(currentLocation.latitude!, currentLocation.longitude!),
          toBuilding: _endBuilding!,
        );
      }
    } else {
      response = await UnifiedPathService.getPathBetweenBuildings(
        fromBuilding: _startBuilding!,
        toBuilding: _endBuilding!,
      );
    }

    if (response != null && mounted) {
      _previewResponse = response;
      _calculateEstimatesFromResponse(response);
      debugPrint('✅ 경로 미리보기 계산 완료: ${response.type}');
    }

  } catch (e) {
    debugPrint('❌ 경로 미리보기 계산 오류: $e');
  } finally {
    if (mounted) {
      setState(() => _isCalculatingPreview = false);
    }
  }
}

  // 🔥 통합 API 응답으로부터 예상 시간과 거리 계산
  void _calculateEstimatesFromResponse(UnifiedPathResponse response) {
    double totalDistance = 0;
    
    // 모든 구간의 거리 합산
    if (response.result.departureIndoor != null) {
      totalDistance += response.result.departureIndoor!.path.distance;
    }
    if (response.result.outdoor != null) {
      totalDistance += response.result.outdoor!.path.distance;
    }
    if (response.result.arrivalIndoor != null) {
      totalDistance += response.result.arrivalIndoor!.path.distance;
    }
    
    // 거리 포맷팅
    if (totalDistance < 1000) {
      _estimatedDistance = '${totalDistance.round()}m';
    } else {
      _estimatedDistance = '${(totalDistance / 1000).toStringAsFixed(1)}km';
    }
    
    // 예상 시간 계산 (평균 도보 속도 4km/h 기준)
    double walkingSpeedKmh = 4.0;
    double timeInHours = totalDistance / 1000 / walkingSpeedKmh;
    int timeInMinutes = (timeInHours * 60).round();
    
    if (timeInMinutes < 60) {
      _estimatedTime = '도보 ${timeInMinutes}분';
    } else {
      int hours = timeInMinutes ~/ 60;
      int minutes = timeInMinutes % 60;
      _estimatedTime = '도보 ${hours}시간 ${minutes}분';
    }
    
    debugPrint('📊 통합 API 기반 예상: 거리 $_estimatedDistance, 시간 $_estimatedTime');
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text.trim();
    
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
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('검색 오류: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    }
  }

  void _selectStartLocation() {
    setState(() {
      _searchType = 'start';
      _isSearching = false;
      _isLoading = false;
      _searchResults = [];
      _searchController.clear();
    });
    _focusNode.requestFocus();
  }

  void _selectEndLocation() {
    setState(() {
      _searchType = 'end';
      _isSearching = false;
      _isLoading = false;
      _searchResults = [];
      _searchController.clear();
    });
    _focusNode.requestFocus();
  }

 // 2. 검색 결과 선택 시 (건물/호실 모두 건물 코드만 사용)
void _onSearchResultSelected(SearchResult result) {
  Building building;
  Map<String, dynamic>? roomInfo;

  if (result.isRoom) {
    building = result.toBuildingWithRoomLocation();
    roomInfo = {
      'roomName': result.roomNumber ?? '',
      'buildingName': _extractBuildingCode(result.building.name), // 🔥 건물 코드만 사용
      'floorNumber': result.floorNumber?.toString() ?? '1',        // 🔥 항상 문자열
    };
  } else {
    final buildingCode = _extractBuildingCode(result.building.name);
    building = Building(
      name: buildingCode,
      info: result.building.info,
      lat: result.building.lat,
      lng: result.building.lng,
      category: result.building.category,
      baseStatus: result.building.baseStatus,
      hours: result.building.hours,
      phone: result.building.phone,
      imageUrl: result.building.imageUrl,
      description: result.building.description,
    );
  }

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
      _startRoomInfo = roomInfo;
      _searchType = null;
      _isSearching = false;
      _isLoading = false;
      _searchResults = [];
      _searchController.clear();
    });
  } else if (_searchType == 'end') {
    setState(() {
      _endBuilding = building;
      _endRoomInfo = roomInfo;
      _searchType = null;
      _isSearching = false;
      _isLoading = false;
      _searchResults = [];
      _searchController.clear();
    });
  }

  _focusNode.unfocus();

  if (_startBuilding != null && _endBuilding != null) {
    _calculateRoutePreview();
  }
}

  void _onBuildingSelected(Building building) {
  final buildingCode = _extractBuildingCode(building.name);
  final cleanBuilding = Building(
    name: buildingCode, // 건물 코드만 사용
    info: building.info,
    lat: building.lat,
    lng: building.lng,
    category: building.category,
    baseStatus: building.baseStatus,
    hours: building.hours,
    phone: building.phone,
    imageUrl: building.imageUrl,
    description: building.description,
  );

  setState(() {
    _recentSearches.removeWhere((b) => b.name == cleanBuilding.name);
    _recentSearches.insert(0, cleanBuilding);
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.take(5).toList();
    }
  });

  if (_searchType == 'start') {
    setState(() {
      _startBuilding = cleanBuilding;
      _startRoomInfo = null;
      _searchType = null;
      _isSearching = false;
      _isLoading = false;
      _searchResults = [];
      _searchController.clear();
    });
  } else if (_searchType == 'end') {
    setState(() {
      _endBuilding = cleanBuilding;
      _endRoomInfo = null;
      _searchType = null;
      _isSearching = false;
      _isLoading = false;
      _searchResults = [];
      _searchController.clear();
    });
  }
  _focusNode.unfocus();

  if (_startBuilding != null && _endBuilding != null) {
    _calculateRoutePreview();
  }
}

  void _swapLocations() {
    if (_startBuilding != null && _endBuilding != null) {
      setState(() {
        final tempBuilding = _startBuilding;
        final tempRoomInfo = _startRoomInfo;
        
        _startBuilding = _endBuilding;
        _startRoomInfo = _endRoomInfo;
        
        _endBuilding = tempBuilding;
        _endRoomInfo = tempRoomInfo;
      });
      
      // 🔥 교환 후 미리보기 재계산
      _calculateRoutePreview();
    }
  }

  // 🔥 통합 네비게이션 시작 (기존 _startNavigation 대체)
void _startUnifiedNavigation() {
  debugPrint('=== 통합 네비게이션 시작 ===');
  debugPrint('출발지: ${_startBuilding?.name} (호실: ${_startRoomInfo?['roomName'] ?? 'None'})');
  debugPrint('도착지: ${_endBuilding?.name} (호실: ${_endRoomInfo?['roomName'] ?? 'None'})');

  if (_startBuilding != null && _endBuilding != null) {
    // 🔥 통합 네비게이션 데이터 구성
    final unifiedNavigationData = {
      'type': 'unified_navigation',
      'start': _startBuilding,
      'end': _endBuilding,
      'startRoomInfo': _startRoomInfo,
      'endRoomInfo': _endRoomInfo,
      'useCurrentLocation': _startBuilding!.name == '내 위치',
      'estimatedDistance': _estimatedDistance,
      'estimatedTime': _estimatedTime,
      'pathResponse': _previewResponse,
      'showNavigationStatus': true,
    };

    debugPrint('✅ 통합 네비게이션 데이터 구성 완료');
    debugPrint('전달 데이터: $unifiedNavigationData');

    // === 단계별 네비게이션 데이터 추출 ===
    final departureIndoor = _previewResponse?.result?.departureIndoor;
    final outdoor = _previewResponse?.result?.outdoor;
    final arrivalIndoor = _previewResponse?.result?.arrivalIndoor;

    // 출발 실내 노드 리스트
    final List<String> departureNodeIds = (departureIndoor?.path?.path ?? [])
        .map((e) => e.toString())
        .toList();

    // 실외 경로 좌표 리스트 (List<Map<String, dynamic>>)
    final List<Map<String, dynamic>> outdoorPath =
        (outdoor?.path?.path ?? []).cast<Map<String, dynamic>>();

    // 실외 거리
    final double outdoorDistance = outdoor?.path?.distance ?? 0.0;

    // 도착 실내 노드 리스트
    final List<String> arrivalNodeIds = (arrivalIndoor?.path?.path ?? [])
        .map((e) => e.toString())
        .toList();

    // 출발/도착 건물 코드만 추출해서 전달
    final String departureBuilding = _extractBuildingCode(_startBuilding?.name ?? '');
    final String arrivalBuilding = _extractBuildingCode(_endBuilding?.name ?? '');

    // 단계별 네비게이션 Wrapper로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnifiedNavigationStepperPage(
          departureBuilding: departureBuilding,
          departureNodeIds: departureNodeIds,
          outdoorPath: outdoorPath,
          outdoorDistance: outdoorDistance,
          arrivalBuilding: arrivalBuilding,
          arrivalNodeIds: arrivalNodeIds,
        ),
      ),
    );
  } else {
    debugPrint('❌ 출발지 또는 도착지가 설정되지 않음');
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
      _isLoading = false;
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
              hintText: _searchType == 'start' 
                  ? '출발지를 검색해주세요 (건물명 또는 호실)' 
                  : '도착지를 검색해주세요 (건물명 또는 호실)',
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
          _isNavigationActive ? '통합 길찾기 진행중' : '통합 길찾기',
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
          child: _buildSearchContent(),
        ),
      ],
    );
  }

  Widget _buildSearchContent() {
    if (!_isSearching) {
      return _buildRecentSearches();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }

    return _buildSearchResults();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.indigo,
          ),
          SizedBox(height: 16),
          Text(
            '검색 중...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
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
        return _buildBuildingResultItem(building, isRecent: true);
      },
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildSearchResultItem(result);
      },
    );
  }

  // 🔥 수정된 _buildSearchResultItem 메서드 - 강의실 직접 이동 기능 추가

  // directions_screen.dart에서 _buildSearchResultItem의 onTap 부분을 다음과 같이 수정

// directions_screen.dart에서 _buildSearchResultItem의 onTap 부분을 다음과 같이 수정

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
            ? result.roomDescription ?? '강의실'
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
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey.shade400,
        size: 20,
      ),
      // 🔥 이 부분을 수정
      onTap: () {
        if (_searchType != null) {
          // 길찾기 모드: 출발지/도착지 설정
          _onSearchResultSelected(result);
        } else {
          // 🔥 단독 검색 모드: 강의실이면 바로 이동
          if (result.isRoom) {
            _navigateToRoomDirectly(result);
          } else {
            // 건물이면 길찾기 화면으로 이동하거나 다른 처리
            _onSearchResultSelected(result);
          }
        }
      },
    ),
  );
}

// 🔥 강의실로 바로 이동하는 메서드 추가
void _navigateToRoomDirectly(SearchResult result) {
  if (!result.isRoom) return;
  
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

  Widget _buildBuildingResultItem(Building building, {bool isRecent = false}) {
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
            
            // 🔥 preset 및 호실 알림 메시지
            if (widget.presetStart != null || widget.presetEnd != null || widget.roomData != null) ...[
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
                        _getPresetMessage(),
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
              roomInfo: _startRoomInfo,
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
              roomInfo: _endRoomInfo,
              onTap: _selectEndLocation,
            ),
            
            const Spacer(),
            
            // 🔥 통합 API 경로 미리보기 정보
            if (_previewResponse != null && !_isCalculatingPreview) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.route,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '경로 미리보기',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRoutePreview(),
                  ],
                ),
              ),
            ],
            
            // 로딩 중이거나 기본 안내 메시지
            if (_isCalculatingPreview) ...[
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
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '최적 경로를 계산하고 있습니다...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_previewResponse == null && _startBuilding == null && _endBuilding == null) ...[
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
                        '출발지와 도착지를 설정해주세요\n건물명 또는 호실을 입력할 수 있습니다',
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
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
          ],
        ),
        
        // 하단 고정 버튼
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          child: ElevatedButton(
            onPressed: (_startBuilding != null && _endBuilding != null) 
                ? _startUnifiedNavigation 
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
                  '통합 길찾기 시작',
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

  // 🔥 경로 미리보기 위젯
  Widget _buildRoutePreview() {
    if (_previewResponse == null) return Container();

    final result = _previewResponse!.result;
    final steps = <Widget>[];

    // 출발지 실내 구간
    if (result.departureIndoor != null) {
      steps.add(_buildRouteStep(
        icon: Icons.home,
        title: '출발지 실내',
        distance: '${result.departureIndoor!.path.distance.toStringAsFixed(0)}m',
        description: '건물 출구까지',
        color: Colors.green,
      ));
    }

    // 실외 구간
    if (result.outdoor != null) {
      steps.add(_buildRouteStep(
        icon: Icons.directions_walk,
        title: '실외 이동',
        distance: '${result.outdoor!.path.distance.toStringAsFixed(0)}m',
        description: '목적지 건물까지',
        color: Colors.blue,
      ));
    }

    // 도착지 실내 구간
    if (result.arrivalIndoor != null) {
      steps.add(_buildRouteStep(
        icon: Icons.location_on,
        title: '도착지 실내',
        distance: '${result.arrivalIndoor!.path.distance.toStringAsFixed(0)}m',
        description: '최종 목적지까지',
        color: Colors.orange,
      ));
    }

    return Column(
      children: [
        // 전체 요약
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('총 거리', _estimatedDistance),
            _buildSummaryItem('예상 시간', _estimatedTime),
            _buildSummaryItem('경로 타입', _getRouteTypeDescription()),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        
        // 단계별 경로
        ...steps,
      ],
    );
  }

  Widget _buildRouteStep({
    required IconData icon,
    required String title,
    required String distance,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            distance,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _getRouteTypeDescription() {
    if (_previewResponse == null) return '';
    
    switch (_previewResponse!.type) {
      case 'building-building':
        return '건물간';
      case 'room-building':
        return '호실→건물';
      case 'building-room':
        return '건물→호실';
      case 'room-room':
        return '호실간';
      case 'location-building':
        return '현위치→건물';
      default:
        return '통합경로';
    }
  }

  String _getPresetMessage() {
    if (widget.roomData != null) {
      final type = widget.roomData!['type'] ?? '';
      final roomName = widget.roomData!['roomName'] ?? '';
      final buildingName = widget.roomData!['buildingName'] ?? '';
      
      if (type == 'start') {
        return '$buildingName $roomName호가 출발지로 설정되었습니다';
      } else {
        return '$buildingName $roomName호가 도착지로 설정되었습니다';
      }
    } else if (widget.presetStart != null) {
      return '${widget.presetStart!.name}이 출발지로 설정되었습니다';
    } else if (widget.presetEnd != null) {
      return '${widget.presetEnd!.name}이 도착지로 설정되었습니다';
    }
    return '';
  }

  Widget _buildLocationInput({
    required IconData icon,
    required Color iconColor,
    required String hint,
    required Building? selectedBuilding,
    Map<String, dynamic>? roomInfo,
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
                            // 🔥 호실 정보 표시
                            if (roomInfo != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${roomInfo['floorNumber'] ?? ''}층 ${roomInfo['roomName'] ?? ''}호',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ] else if (selectedBuilding.category.isNotEmpty) ...[
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
                        _startRoomInfo = null; // 현재 위치는 호실 정보 없음
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
                        
                        // 🔥 현재 위치 설정 후 미리보기 계산
                        if (_endBuilding != null) {
                          _calculateRoutePreview();
                        }
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
                            _startRoomInfo = null;
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
                          
                          // 🔥 현재 위치 설정 후 미리보기 계산
                          if (_endBuilding != null) {
                            _calculateRoutePreview();
                          }
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
                      _startRoomInfo = null;
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
                      
                      // 🔥 기본 위치 설정 후 미리보기 계산
                      if (_endBuilding != null) {
                        _calculateRoutePreview();
                      }
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