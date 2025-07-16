// lib/page/building_map_page.dart - 통합 API 적용 버전

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_naver_map/flutter_naver_map.dart';

// 기존 imports
import '../inside/api_service.dart';
import '../inside/svg_data_parser.dart';
import '../inside/room_info.dart';
import '../inside/room_info_sheet.dart';
import '../inside/room_shape_painter.dart';
import '../inside/path_painter.dart';

// 🔥 새로 추가된 imports
import '../services/unified_path_service.dart';
import '../controllers/unified_navigation_controller.dart';

class BuildingMapPage extends StatefulWidget {
  final String buildingName;
  
  // 🔥 통합 네비게이션을 위한 새로운 파라미터들
  final List<String>? navigationNodeIds;
  final bool isArrivalNavigation;
  final UnifiedNavigationController? navigationController;

  const BuildingMapPage({
    super.key, 
    required this.buildingName,
    this.navigationNodeIds,
    this.isArrivalNavigation = false,
    this.navigationController,
  });

  @override
  State<BuildingMapPage> createState() => _BuildingMapPageState();
}

class _BuildingMapPageState extends State<BuildingMapPage> {
  // 기존 상태 변수들 (그대로 유지)
  List<dynamic> _floorList = [];
  Map<String, dynamic>? _selectedFloor;
  String? _svgUrl;
  List<Map<String, dynamic>> _buttonData = [];
  Map<String, dynamic>? _startPoint;
  Map<String, dynamic>? _endPoint;
  List<Offset> _departurePath = [];
  List<Offset> _arrivalPath = [];
  List<Offset> _currentShortestPath = [];
  Map<String, String>? _transitionInfo;
  bool _isFloorListLoading = true;
  bool _isMapLoading = false;
  String? _error;
  String? _selectedRoomId;

  final ApiService _apiService = ApiService();
  final TransformationController _transformationController = TransformationController();
  Timer? _resetTimer;
  static const double svgScale = 0.7;
  bool _showTransitionPrompt = false;
  Timer? _promptTimer;

  // 🔥 통합 네비게이션 관련 새로운 상태
  bool _isNavigationMode = false;
  List<Offset> _navigationPath = [];

@override
void initState() {
  super.initState();
  _isNavigationMode = widget.navigationNodeIds != null;
  if (_isNavigationMode && widget.navigationNodeIds!.isNotEmpty) {
    // 네비게이션 모드: 첫 번째 층만 지목해서 로드
    final firstNode = widget.navigationNodeIds!.firstWhere((id) => id.contains('@'), orElse: () => '');
    final floorNum = firstNode.split('@').length >= 2 ? firstNode.split('@')[1] : '1';
    _loadFloorList(widget.buildingName, targetFloorNumber: floorNum);
  } else {
    // 일반 모드: 첫 번째 층 자동 로드
    _loadFloorList(widget.buildingName);
  }
  if (_isNavigationMode) {
    _setupNavigationMode();
  }
}



  // 🔥 네비게이션 모드 설정
  void _setupNavigationMode() {
    debugPrint('🧭 네비게이션 모드 설정');
    debugPrint('   노드 개수: ${widget.navigationNodeIds?.length}');
    debugPrint('   도착 네비게이션: ${widget.isArrivalNavigation}');
    
    // 네비게이션 경로 표시를 위한 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.navigationNodeIds != null) {
        _displayNavigationPath(widget.navigationNodeIds!);
      }
    });
  }

  // 🔥 네비게이션 경로 표시
  Future<void> _displayNavigationPath(List<String> nodeIds) async {
    try {
      debugPrint('🗺️ 네비게이션 경로 표시 시작: ${nodeIds.length}개 노드');
      
      // 현재 층의 노드 맵 로드
      final currentFloorNum = _selectedFloor?['Floor_Number'].toString() ?? '1';
      Map<String, Map<String, Offset>> floorNodesMap = {};
      await _loadNodesForFloor(currentFloorNum, floorNodesMap);
      
      // 노드 ID를 좌표로 변환
      final pathOffsets = _convertNodeIdsToOffsets(nodeIds, currentFloorNum, floorNodesMap);
      
      if (pathOffsets.isNotEmpty) {
        setState(() {
          _navigationPath = pathOffsets;
          _currentShortestPath = pathOffsets;
        });
        
        debugPrint('✅ 네비게이션 경로 표시 완료: ${pathOffsets.length}개 좌표');
        
        // 경로의 시작점으로 카메라 이동
        _focusOnNavigationPath();
      }
    } catch (e) {
      debugPrint('❌ 네비게이션 경로 표시 오류: $e');
    }
  }

  // 🔥 네비게이션 경로에 포커스
  void _focusOnNavigationPath() {
    if (_navigationPath.isNotEmpty) {
      // 경로의 중심점 계산
      double centerX = _navigationPath.map((p) => p.dx).reduce((a, b) => a + b) / _navigationPath.length;
      double centerY = _navigationPath.map((p) => p.dy).reduce((a, b) => a + b) / _navigationPath.length;
      
      // 적절한 줌 레벨로 이동 (구현 필요)
      debugPrint('📍 네비게이션 경로 중심: ($centerX, $centerY)');
    }
  }

  // 🔥 노드 ID를 Offset으로 변환 (개선된 버전)
  List<Offset> _convertNodeIdsToOffsets(List<String> nodeIds, String floorNum, Map<String, Map<String, Offset>> floorNodesMap) {
  final floorNumStr = floorNum.toString();
  final nodeMap = floorNodesMap[floorNumStr] ?? {};
  if (nodeMap.isEmpty) {
    debugPrint('⚠️ 층 $floorNumStr의 노드 맵이 비어있음');
    return [];
  }

  final offsets = <Offset>[];
  for (String nodeId in nodeIds) {
    String simpleId = nodeId.contains('@') ? nodeId.split('@').last : nodeId;
    if (simpleId.startsWith('R')) {
      simpleId = simpleId.substring(1);
    }

    final offset = nodeMap[simpleId];
    if (offset != null) {
      offsets.add(offset);
      debugPrint('✅ 노드 변환: $nodeId -> $simpleId -> $offset');
    } else {
      debugPrint('❌ 노드 찾기 실패: $nodeId (simpleId: $simpleId)');
    }
  }

  debugPrint('📊 노드 변환 결과: ${nodeIds.length}개 중 ${offsets.length}개 성공');
  return offsets;
}

void _onFloorChanged(Map<String, dynamic> newFloor) {
  final newFloorNumber = newFloor['Floor_Number'].toString();

  if (_selectedFloor?['Floor_Id'] == newFloor['Floor_Id'] && _error == null) return;

  setState(() {
    _selectedFloor = newFloor;

    if (_isNavigationMode && widget.navigationNodeIds != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _displayNavigationPath(widget.navigationNodeIds!);
      });
    } else {
      if (_transitionInfo != null) {
        if (newFloorNumber == _transitionInfo!['from']) {
          _currentShortestPath = _departurePath;
        } else if (newFloorNumber == _transitionInfo!['to']) {
          _currentShortestPath = _arrivalPath;
        } else {
          _currentShortestPath = [];
        }
      } else {
        final bool shouldResetPath =
            _startPoint?['floorId'] != newFloor['Floor_Id'] ||
            _endPoint?['floorId'] != newFloor['Floor_Id'];
        if (shouldResetPath) _currentShortestPath = [];
      }
    }
  });

  _loadMapData(newFloor);

  if (_transitionInfo != null) {
    _showAndFadePrompt();
  }
}

  @override
  void dispose() {
    _transformationController.dispose();
    _resetTimer?.cancel();
    _promptTimer?.cancel();
    super.dispose();
  }

  // 🔥 기존 _findAndDrawPath를 통합 API 사용으로 수정
  Future<void> _findAndDrawPath() async {
    if (_startPoint == null || _endPoint == null) return;

    setState(() {
      _isMapLoading = true;
      _departurePath = [];
      _arrivalPath = [];
      _currentShortestPath = [];
      _transitionInfo = null;
    });

    try {
      // 🔥 통합 API 요청 준비
      final fromBuilding = widget.buildingName;
      final fromFloor = int.parse(_startPoint!['floorNumber'].toString());
      final fromRoom = (_startPoint!['roomId'] as String).replaceFirst('R', '');
      
      final toBuilding = _endPoint!['buildingName'] ?? widget.buildingName;
      final toFloor = int.parse(_endPoint!['floorNumber'].toString());
      final toRoom = (_endPoint!['roomId'] as String).replaceFirst('R', '');

      debugPrint('🚀 통합 API 경로 요청:');
      debugPrint('   출발: $fromBuilding $fromFloor층 $fromRoom호');
      debugPrint('   도착: $toBuilding $toFloor층 $toRoom호');

      // 🔥 통합 경로 API 호출
      final response = await UnifiedPathService.getPathBetweenRooms(
        fromBuilding: fromBuilding,
        fromFloor: fromFloor,
        fromRoom: fromRoom,
        toBuilding: toBuilding,
        toFloor: toFloor,
        toRoom: toRoom,
      );

      if (response == null) {
        throw Exception('통합 API에서 응답을 받지 못했습니다');
      }

      debugPrint('✅ 통합 API 응답: ${response.type}');

      // 🔥 통합 응답 처리
      await _processUnifiedPathResponse(response, fromFloor, toFloor);

    } catch (e) {
      _clearAllPathInfo();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('통합 길찾기 중 오류가 발생했습니다: $e')),
      );
      debugPrint('❌ 통합 길찾기 오류: $e');
    } finally {
      if (mounted) setState(() => _isMapLoading = false);
    }
  }

  // 🔥 통합 API 응답 처리 메서드
  Future<void> _processUnifiedPathResponse(
    UnifiedPathResponse response, 
    int fromFloor, 
    int toFloor
  ) async {
    final type = response.type;
    final result = response.result;

    debugPrint('📋 통합 응답 처리: $type');

    switch (type) {
      case 'room-room':
        await _handleRoomToRoomResponse(result, fromFloor, toFloor);
        break;
        
      case 'room-building':
        await _handleRoomToBuildingResponse(result, fromFloor);
        break;
        
      case 'building-room':
        await _handleBuildingToRoomResponse(result, toFloor);
        break;
        
      case 'building-building':
        _handleBuildingToBuildingResponse(result);
        break;
        
      default:
        debugPrint('❌ 지원하지 않는 응답 타입: $type');
        throw Exception('지원하지 않는 경로 타입: $type');
    }
  }

  // 🔥 호실 → 호실 응답 처리
  Future<void> _handleRoomToRoomResponse(
    PathResult result, 
    int fromFloor, 
    int toFloor
  ) async {
    final departureIndoor = result.departureIndoor;
    final arrivalIndoor = result.arrivalIndoor;
    final outdoor = result.outdoor;

    if (departureIndoor != null && outdoor != null && arrivalIndoor != null) {
      // 다른 건물 간 호실 이동
      debugPrint('🏢 다른 건물 간 호실 이동');
      
      final depNodeIds = UnifiedPathService.extractIndoorNodeIds(departureIndoor);
      await _processIndoorPath(depNodeIds, fromFloor, true); // 출발지 경로
      
      _showOutdoorTransitionMessage(outdoor);
      
    } else if (arrivalIndoor != null) {
      // 같은 건물 내 호실 이동
      debugPrint('🏠 같은 건물 내 호실 이동');
      
      final nodeIds = UnifiedPathService.extractIndoorNodeIds(arrivalIndoor);
      await _processSameBuildingPath(nodeIds, fromFloor, toFloor);
    }
  }

  // 🔥 호실 → 건물 응답 처리
  Future<void> _handleRoomToBuildingResponse(PathResult result, int fromFloor) async {
    final departureIndoor = result.departureIndoor;
    final outdoor = result.outdoor;

    if (departureIndoor != null) {
      debugPrint('🚪 호실에서 건물 출구까지');
      
      final nodeIds = UnifiedPathService.extractIndoorNodeIds(departureIndoor);
      await _processIndoorPath(nodeIds, fromFloor, true);
      
      if (outdoor != null) {
        _showOutdoorTransitionMessage(outdoor);
      }
    }
  }

  // 🔥 건물 → 호실 응답 처리
  Future<void> _handleBuildingToRoomResponse(PathResult result, int toFloor) async {
    final outdoor = result.outdoor;
    final arrivalIndoor = result.arrivalIndoor;

    debugPrint('🏢 건물 입구에서 호실까지');
    
    if (outdoor != null) {
      _showOutdoorTransitionMessage(outdoor);
    }
    
    if (arrivalIndoor != null) {
      final nodeIds = UnifiedPathService.extractIndoorNodeIds(arrivalIndoor);
      // 도착 후 실내 경로는 별도 처리 필요
      debugPrint('📝 도착 후 실내 경로 준비: ${nodeIds.length}개 노드');
    }
  }

  // 🔥 건물 → 건물 응답 처리
  void _handleBuildingToBuildingResponse(PathResult result) {
    final outdoor = result.outdoor;
    
    if (outdoor != null) {
      _showOutdoorTransitionMessage(outdoor);
    }
  }

  // 🔥 실내 경로 처리
  Future<void> _processIndoorPath(List<String> nodeIds, int floorNumber, bool isDeparture) async {
    debugPrint('🗺️ 실내 경로 처리: ${nodeIds.length}개 노드, 층: $floorNumber');
    
    final floorNumStr = floorNumber.toString();
    Map<String, Map<String, Offset>> floorNodesMap = {};
    await _loadNodesForFloor(floorNumStr, floorNodesMap);
    
    final pathOffsets = _convertNodeIdsToOffsets(nodeIds, floorNumStr, floorNodesMap);
    
    setState(() {
      if (isDeparture) {
        _departurePath = pathOffsets;
      } else {
        _arrivalPath = pathOffsets;
      }
      _currentShortestPath = pathOffsets;
    });
    
    debugPrint('✅ 실내 경로 표시: ${pathOffsets.length}개 좌표');
  }

  // 🔥 같은 건물 내 경로 처리
  Future<void> _processSameBuildingPath(List<String> nodeIds, int fromFloor, int toFloor) async {
    debugPrint('🏠 같은 건물 내 경로 처리');
    
    final fromFloorStr = fromFloor.toString();
    final toFloorStr = toFloor.toString();
    final isCrossFloor = fromFloorStr != toFloorStr;

    Map<String, Map<String, Offset>> floorNodesMap = {};
    await _loadNodesForFloor(fromFloorStr, floorNodesMap);
    
    if (isCrossFloor) {
      await _loadNodesForFloor(toFloorStr, floorNodesMap);
      
      // 층간 이동 경로 분리
      int splitIndex = nodeIds.indexWhere((id) => id.split('@')[1] != fromFloorStr);
      if (splitIndex == -1) splitIndex = nodeIds.length;
      
      final depOffsets = _convertNodeIdsToOffsets(
        nodeIds.sublist(0, splitIndex), fromFloorStr, floorNodesMap);
      final arrOffsets = _convertNodeIdsToOffsets(
        nodeIds.sublist(splitIndex), toFloorStr, floorNodesMap);
      
      setState(() {
        _departurePath = depOffsets;
        _arrivalPath = arrOffsets;
        _currentShortestPath = _selectedFloor?['Floor_Number'].toString() == fromFloorStr 
            ? depOffsets : arrOffsets;
        _transitionInfo = {"from": fromFloorStr, "to": toFloorStr};
      });
      
      _showAndFadePrompt();
    } else {
      // 같은 층 내 이동
      final sameFloorOffsets = _convertNodeIdsToOffsets(nodeIds, fromFloorStr, floorNodesMap);
      setState(() => _currentShortestPath = sameFloorOffsets);
    }
  }

  // 🔥 실외 전환 메시지 표시
  void _showOutdoorTransitionMessage(OutdoorPathData outdoorData) {
    final coordinates = UnifiedPathService.extractOutdoorCoordinates(outdoorData);
    final distance = outdoorData.path.distance;
    
    debugPrint('🌍 실외 경로 정보: ${coordinates.length}개 좌표, 거리: ${distance}m');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('실외 경로로 이동하세요 (거리: ${distance.toStringAsFixed(0)}m)'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // 🔥 네비게이션 완료 처리
  void _completeNavigation() {
    if (widget.navigationController != null) {
      // 통합 네비게이션 컨트롤러에 완료 신호
      widget.navigationController!.proceedToNextStep();
    }
    
    // 결과와 함께 페이지 종료
    Navigator.of(context).pop('completed');
  }

  // 기존 메서드들은 그대로 유지...
Future<void> _loadFloorList(String buildingName, {String? targetFloorNumber}) async {
  setState(() {
    _isFloorListLoading = true;
    _error = null;
  });

  try {
    final floors = await _apiService.fetchFloorList(buildingName);

    if (mounted) {
      // 🔥 navigationNodeIds에 포함된 층만 필터링
      final allowedFloors = widget.navigationNodeIds
          ?.map((id) => id.split('@')[1])
          .toSet();

      final filteredFloors = allowedFloors != null
          ? floors.where((f) => allowedFloors.contains(f['Floor_Number'].toString())).toList()
          : floors;

      setState(() {
        _floorList = filteredFloors;
        _isFloorListLoading = false;
      });

      if (_floorList.isNotEmpty) {
        final selectedFloor = targetFloorNumber != null
            ? _floorList.firstWhere(
                (f) => f['Floor_Number'].toString() == targetFloorNumber,
                orElse: () => _floorList.first,
              )
            : _floorList.first;

        selectedFloor['Floor_Number'] = selectedFloor['Floor_Number'].toString();
        _onFloorChanged(selectedFloor);
      } else {
        setState(() => _error = "이 건물의 층 정보를 찾을 수 없습니다.");
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isFloorListLoading = false;
        _error = '층 목록을 불러오는 데 실패했습니다: $e';
      });
    }
  }
}


  Future<void> _loadMapData(Map<String, dynamic> floorInfo) async {
  setState(() => _isMapLoading = true);

  try {
    final svgUrl = floorInfo['File'] as String?;
    if (svgUrl == null || svgUrl.isEmpty)
      throw Exception('SVG URL이 유효하지 않습니다.');

    final svgResponse = await http.get(Uri.parse(svgUrl));
    if (svgResponse.statusCode != 200)
      throw Exception('SVG 파일을 다운로드할 수 없습니다');

    final svgContent = svgResponse.body;
    final buttons = SvgDataParser.parseButtonData(svgContent);

    if (mounted) {
      setState(() {
        _svgUrl = svgUrl;
        _buttonData = buttons;
        _isMapLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isMapLoading = false;
        _error = '지도 데이터를 불러오는 데 실패했습니다: $e';
      });
    }
  }
}
  void _clearAllPathInfo() {
  _promptTimer?.cancel();
  setState(() {
    _startPoint = null;
    _endPoint = null;
    _departurePath = [];
    _arrivalPath = [];
    _currentShortestPath = [];
    _transitionInfo = null;
    _showTransitionPrompt = false;
    _transformationController.value = Matrix4.identity();
    _navigationPath = [];
  });
}

  Future<void> _loadNodesForFloor(
    String floorNumber,
    Map<String, Map<String, Offset>> targetMap,
  ) async {
    if (targetMap.containsKey(floorNumber)) return;

    final floorInfo = _floorList.firstWhere(
      (f) => f['Floor_Number'].toString() == floorNumber,
      orElse: () => null,
    );

    if (floorInfo != null) {
      final svgUrl = floorInfo['File'] as String?;
      if (svgUrl != null && svgUrl.isNotEmpty) {
        final svgResponse = await http.get(Uri.parse(svgUrl));
        if (svgResponse.statusCode == 200) {
          targetMap[floorNumber] = SvgDataParser.parseAllNodes(
            svgResponse.body,
          );
        }
      }
    }
  }

  void _setPoint(String type, String roomId) async {
    final pointData = {
      "floorId": _selectedFloor?['Floor_Id'],
      "floorNumber": _selectedFloor?['Floor_Number'],
      "roomId": roomId,
    };

    setState(() {
      if (type == 'start') {
        _startPoint = pointData;
      } else {
        _endPoint = pointData;
      }
    });

    if (mounted) Navigator.pop(context);

    if (_startPoint != null && _endPoint != null) {
      await _findAndDrawPath();

      final startFloorId = _startPoint!['floorId'];
      final currentFloorId = _selectedFloor?['Floor_Id'];

      if (startFloorId != null && startFloorId != currentFloorId) {
        final startingFloorInfo = _floorList.firstWhere(
          (floor) => floor['Floor_Id'] == startFloorId,
          orElse: () => null,
        );
        if (startingFloorInfo != null && mounted) {
          _onFloorChanged(startingFloorInfo);
        }
      }
    }
  }

  void _showRoomInfoSheet(BuildContext context, String roomId) async {
  // 네비게이션 모드에서는 호실 정보 시트를 다르게 표시
  if (_isNavigationMode) {
    _showNavigationRoomSheet(context, roomId);
    return;
  }

  setState(() => _selectedRoomId = roomId);
  String roomIdNoR = roomId.startsWith('R') ? roomId.substring(1) : roomId;
  String roomDesc = '';

  try {
    roomDesc = await _apiService.fetchRoomDescription(
      buildingName: widget.buildingName,
      floorNumber: _selectedFloor?['Floor_Number']?.toString() ?? '',
      roomName: roomIdNoR,
    );
  } catch (e) {
    debugPrint(e.toString());
    roomDesc = '설명을 불러오지 못했습니다.';
  }

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => RoomInfoSheet(
      roomInfo: RoomInfo(id: roomId, name: roomIdNoR, desc: roomDesc),
      onDeparture: () => _setPoint('start', roomId),
      onArrival: () => _setPoint('end', roomId),
      // 🔥 해결: 건물명과 층 정보 전달
      buildingName: widget.buildingName,
      floorNumber: _selectedFloor?['Floor_Number'],
    ),
  );

  if (mounted) setState(() => _selectedRoomId = null);
}

  // 🔥 네비게이션 모드용 호실 정보 시트
  void _showNavigationRoomSheet(BuildContext context, String roomId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '네비게이션 진행 중',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '현재 ${widget.isArrivalNavigation ? "목적지" : "출발지"} 건물의 실내 안내를 진행중입니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _completeNavigation();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('목적지 도착'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('계속 진행'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAndFadePrompt() {
    setState(() => _showTransitionPrompt = true);
    _promptTimer?.cancel();
    _promptTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showTransitionPrompt = false);
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(
        _isNavigationMode 
            ? '${widget.buildingName} 네비게이션'
            : '${widget.buildingName} 실내 안내도'
      ),
      backgroundColor: _isNavigationMode ? Colors.blue : Colors.indigo,
      actions: [
        if (_isNavigationMode) ...[
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: _completeNavigation,
            tooltip: '네비게이션 완료',
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearAllPathInfo,
            tooltip: '초기화',
          ),
        ],
      ],
    ),
    body: Stack(
      children: [
        Center(child: _buildBodyContent()),
        if (!_isFloorListLoading && _error == null)
          Positioned(left: 16, bottom: 120, child: _buildFloorSelector()),
        _buildPathInfo(),
        _buildTransitionPrompt(),
        if (_isNavigationMode) _buildNavigationStatus(),
      ],
    ),
  );
}
  // 🔥 네비게이션 상태 표시 위젯
  Widget _buildNavigationStatus() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              widget.isArrivalNavigation ? Icons.location_on : Icons.my_location,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.isArrivalNavigation 
                    ? '목적지 건물 내부 안내'
                    : '출발지에서 건물 출구까지',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: _completeNavigation,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
              ),
              child: const Text('완료'),
            ),
          ],
        ),
      ),
    );
  }

  // 기존 메서드들 계속...
  Widget _buildBodyContent() {
    if (_isFloorListLoading)
      return const Center(child: Text('층 목록을 불러오는 중...'));
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }
    if (_isMapLoading) return const Center(child: CircularProgressIndicator());
    if (_svgUrl == null) return const Center(child: Text('층을 선택해주세요.'));
    return _buildMapView();
  }

  Widget _buildMapView() {
    const double svgWidth = 210, svgHeight = 297;

    return LayoutBuilder(
      builder: (context, constraints) {
        final baseScale = min(
          constraints.maxWidth / svgWidth,
          constraints.maxHeight / svgHeight,
        );
        final totalScale = baseScale * 1.0;
        final svgDisplayWidth = svgWidth * totalScale * svgScale;
        final svgDisplayHeight = svgHeight * totalScale * svgScale;
        final leftOffset = (constraints.maxWidth - svgDisplayWidth) / 2;
        final topOffset = (constraints.maxHeight - svgDisplayHeight) / 2;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails details) {
            final Offset scenePoint = _transformationController.toScene(
              details.localPosition,
            );
            final Offset svgTapPosition = Offset(
              (scenePoint.dx - leftOffset) / (totalScale * svgScale),
              (scenePoint.dy - topOffset) / (totalScale * svgScale),
            );

            for (var button in _buttonData.reversed) {
              bool isHit = false;
              if (button['type'] == 'path') {
                isHit = (button['path'] as Path).contains(svgTapPosition);
              } else {
                isHit = (button['rect'] as Rect).contains(svgTapPosition);
              }
              if (isHit) {
                _showRoomInfoSheet(context, button['id']);
                break;
              }
            }
          },
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            onInteractionEnd: (details) => _resetScaleAfterDelay(),
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: leftOffset,
                    top: topOffset,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                      child: SvgPicture.network(
                        _svgUrl!,
                        width: svgDisplayWidth,
                        height: svgDisplayHeight,
                        placeholderBuilder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                  ..._buttonData.map((button) {
                    final Rect bounds = button['type'] == 'path'
                        ? (button['path'] as Path).getBounds()
                        : button['rect'];
                    final String id = button['id'];
                    final scaledRect = Rect.fromLTWH(
                      leftOffset + bounds.left * totalScale * svgScale,
                      topOffset + bounds.top * totalScale * svgScale,
                      bounds.width * totalScale * svgScale,
                      bounds.height * totalScale * svgScale,
                    );
                    return Positioned.fromRect(
                      rect: scaledRect,
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: RoomShapePainter(
                            isSelected: _selectedRoomId == id,
                            shape: button['path'] ?? button['rect'],
                          ),
                          size: scaledRect.size,
                        ),
                      ),
                    );
                  }).toList(),
                  
                  // 🔥 네비게이션 경로 또는 일반 경로 표시
                  if (_currentShortestPath.isNotEmpty || _navigationPath.isNotEmpty)
                    Positioned(
                      left: leftOffset,
                      top: topOffset,
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: Size(svgDisplayWidth, svgDisplayHeight),
                          painter: PathPainter(
                            pathPoints: _navigationPath.isNotEmpty 
                                ? _navigationPath 
                                : _currentShortestPath,
                            scale: totalScale * svgScale,
                            // 🔥 네비게이션 모드에서는 다른 색상 사용
                            pathColor: _isNavigationMode ? Colors.blue : null,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransitionPrompt() {
    String? promptText;
    if (_transitionInfo != null &&
        _selectedFloor?['Floor_Number'].toString() ==
            _transitionInfo!['from']) {
      promptText = '${_transitionInfo!['to']}층으로 이동하세요';
    }

    return AnimatedOpacity(
      opacity: _showTransitionPrompt && promptText != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: IgnorePointer(
        child: Positioned(
          bottom: 200,
          left: 0,
          right: 0,
          child: Center(
            child: Card(
              color: Colors.redAccent,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Text(
                  promptText ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloorSelector() {
  // 🔥 층이 하나뿐이면 버튼 숨김
  if (_floorList.length <= 1) return const SizedBox();

  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Column(
        children: _floorList.reversed.map((floor) {
          final bool isSelected =
              _selectedFloor?['Floor_Id'] == floor['Floor_Id'];
          return GestureDetector(
            onTap: () => _onFloorChanged(floor),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (_isNavigationMode ? Colors.blue.withOpacity(0.8) : Colors.indigo.withOpacity(0.8))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${floor['Floor_Number']}F',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}

@override
void didUpdateWidget(covariant BuildingMapPage oldWidget) {
  super.didUpdateWidget(oldWidget);

  if (widget.navigationNodeIds != null &&
      widget.navigationNodeIds != oldWidget.navigationNodeIds &&
      widget.navigationNodeIds!.isNotEmpty) {
    final firstNode = widget.navigationNodeIds!.firstWhere(
      (id) => id.contains('@'),
      orElse: () => '',
    );
    final floorNum = firstNode.split('@').length >= 2 ? firstNode.split('@')[1] : '1';

    _loadFloorList(widget.buildingName, targetFloorNumber: floorNum);
  }
}


  Widget _buildPathInfo() {
    // 🔥 네비게이션 모드에서는 다른 정보 표시
    if (_isNavigationMode) {
      return Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.navigation,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '네비게이션 진행 중',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isArrivalNavigation 
                      ? '목적지 건물 내부를 안내합니다'
                      : '건물 출구까지 안내합니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 기존 경로 정보 표시
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPointInfo("출발", _startPoint?['roomId'], Colors.green),
              const Icon(Icons.arrow_forward_rounded, color: Colors.grey),
              _buildPointInfo("도착", _endPoint?['roomId'], Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointInfo(String title, String? id, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          id ?? '미지정',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _resetScaleAfterDelay() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _transformationController.value = Matrix4.identity();
      }
    });
  }
}