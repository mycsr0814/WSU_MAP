// lib/page/building_map_page.dart - Stack 최소화 + Column 기반 UI 구조

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter/foundation.dart';

// 기존 imports
import '../inside/api_service.dart';
import '../inside/svg_data_parser.dart';
import '../inside/room_info.dart';
import '../inside/room_info_sheet.dart';
import '../inside/room_shape_painter.dart';
import '../inside/path_painter.dart';

// 새로 추가된 imports
import '../services/unified_path_service.dart';
import '../controllers/unified_navigation_controller.dart';

class BuildingMapPage extends StatefulWidget {
  final String buildingName;
  
  // 통합 네비게이션을 위한 새로운 파라미터들
  final List<String>? navigationNodeIds;
  final bool isArrivalNavigation;
  final UnifiedNavigationController? navigationController;
  
  // 검색 결과에서 호실 자동 선택을 위한 새로운 파라미터들
  final String? targetRoomId;  // 자동으로 선택할 호실 ID
  final int? targetFloorNumber;  // 해당 호실이 있는 층 번호

  const BuildingMapPage({
    super.key,
    required this.buildingName,
    this.navigationNodeIds,
    this.isArrivalNavigation = false,
    this.navigationController,
    this.targetRoomId,
    this.targetFloorNumber,
  });

  @override
  State<BuildingMapPage> createState() => _BuildingMapPageState();
}

class _BuildingMapPageState extends State<BuildingMapPage> {
  // 기존 상태 변수들
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
  final TransformationController _transformationController =
      TransformationController();
  Timer? _resetTimer;
  static const double svgScale = 0.9;
  bool _showTransitionPrompt = false;
  Timer? _promptTimer;

  // 통합 네비게이션 관련 새로운 상태
  bool _isNavigationMode = false;
  List<Offset> _navigationPath = [];
  
  // 검색 결과 자동 선택 관련 상태
  bool _shouldAutoSelectRoom = false;
  String? _autoSelectRoomId;

  // 디버깅 정보를 UI에 표시하기 위한 변수들
  String _debugInfo = '';
  bool _showDebugInfo = true;

  // Release 모드 체크
  bool get isReleaseMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return !inDebugMode;
  }

  // 디버깅 정보 추가 메서드
  void _addDebugInfo(String info) {
    if (_showDebugInfo) {
      setState(() {
        _debugInfo += '${DateTime.now().toString().substring(11, 19)}: $info\n';
      });
      // 너무 길어지면 앞부분 삭제
      if (_debugInfo.length > 2000) {
        _debugInfo = _debugInfo.substring(1000);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _isNavigationMode = widget.navigationNodeIds != null;
    
    // 검색 결과에서 온 경우 자동 선택 준비
    _shouldAutoSelectRoom = widget.targetRoomId != null;
    _autoSelectRoomId = widget.targetRoomId;
    
    // 로딩 시작 알림
    if (_shouldAutoSelectRoom && widget.targetRoomId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${widget.targetRoomId} 호실 지도를 불러오는 중...'),
                ],
              ),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.indigo,
            ),
          );
        }
      });
    }
    
    if (_isNavigationMode && widget.navigationNodeIds!.isNotEmpty) {
      // 네비게이션 모드: 첫 번째 층만 지목해서 로드
      final firstNode = widget.navigationNodeIds!.firstWhere((id) => id.contains('@'), orElse: () => '');
      final floorNum = firstNode.split('@').length >= 2 ? firstNode.split('@')[1] : '1';
      _loadFloorList(widget.buildingName, targetFloorNumber: floorNum);
    } else {
      // 일반 모드: 타겟 층이 있으면 해당 층, 없으면 첫 번째 층 자동 로드
      final targetFloor = widget.targetFloorNumber?.toString();
      _loadFloorList(widget.buildingName, targetFloorNumber: targetFloor);
    }
    
    if (_isNavigationMode) {
      _setupNavigationMode();
    }
  }

  // 검색 결과 호실 자동 선택 처리
  void _handleAutoRoomSelection() {
    if (!_shouldAutoSelectRoom || _autoSelectRoomId == null || _buttonData.isEmpty) {
      return;
    }

    debugPrint('🎯 자동 호실 선택 시도: $_autoSelectRoomId');
    _addDebugInfo('🎯 자동 호실 선택 시도: $_autoSelectRoomId');

    // 'R' 접두사 확인 및 추가
    final targetRoomId = _autoSelectRoomId!.startsWith('R') 
        ? _autoSelectRoomId! 
        : 'R$_autoSelectRoomId';
    // 'R' 접두사 확인 및 추가
    final targetRoomId = _autoSelectRoomId!.startsWith('R') 
        ? _autoSelectRoomId! 
        : 'R$_autoSelectRoomId';

    // 버튼 데이터에서 해당 호실 찾기
    final targetButton = _buttonData.firstWhere(
      (button) => button['id'] == targetRoomId,
      orElse: () => <String, dynamic>{},
    );

    if (targetButton.isNotEmpty) {
      debugPrint('✅ 자동 선택할 호실 찾음: $targetRoomId');
      _addDebugInfo('✅ 자동 선택할 호실 찾음: $targetRoomId');
      
      // 즉시 호실 하이라이트 (포커스 전에)
      setState(() {
        _selectedRoomId = targetRoomId;
      });
      
      // 로딩 표시 추가
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text('$_autoSelectRoomId 호실을 찾는 중...'),
            ],
          ),
          duration: const Duration(milliseconds: 1500),
          backgroundColor: Colors.blue,
        ),
      );
      
      // 포커스를 더 빨리, 더 부드럽게
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _focusOnRoom(targetButton);
        }
      });
      
      // 호실 정보 시트는 포커스 완료 후
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showRoomInfoSheet(context, targetRoomId);
        }
      });
      
      // 자동 선택 완료 처리
      _shouldAutoSelectRoom = false;
      _autoSelectRoomId = null;
    } else {
      debugPrint('❌ 자동 선택할 호실을 찾지 못함: $targetRoomId');
      _addDebugInfo('❌ 자동 선택할 호실을 찾지 못함: $targetRoomId');
      
      // 호실을 찾지 못한 경우 사용자에게 알림
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('호실 $_autoSelectRoomId을(를) 찾을 수 없습니다.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
      
      _shouldAutoSelectRoom = false;
      _autoSelectRoomId = null;
    }
  }

  // 더 부드러운 포커스
  void _focusOnRoom(Map<String, dynamic> roomButton) {
    try {
      // 호실의 중심점 계산
      Rect bounds;
      if (roomButton['type'] == 'path') {
        bounds = (roomButton['path'] as Path).getBounds();
      } else {
        bounds = roomButton['rect'] as Rect;
      }
      
      final centerX = bounds.center.dx;
      final centerY = bounds.center.dy;
      
      debugPrint('📍 호실 중심점: ($centerX, $centerY)');
      _addDebugInfo('📍 호실 중심점: ($centerX, $centerY)');
      
      // 즉시 적용
      final targetScale = 1.8; // 줌 레벨 살짝 줄임
      final translation = Matrix4.identity()
        ..scale(targetScale)
        ..translate(-centerX + 150, -centerY + 150); // 오프셋 조정
      
      _transformationController.value = translation;
      
      // 리셋 시간 단축
      _resetScaleAfterDelay(duration: 2000); // 2초로 단축
      
    } catch (e) {
      debugPrint('❌ 호실 포커스 오류: $e');
      _addDebugInfo('❌ 호실 포커스 오류: $e');
    }
  }

  // 기존 네비게이션 모드 설정
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

  // 네비게이션 경로 표시
  Future<void> _displayNavigationPath(List<String> nodeIds) async {
    try {
      debugPrint('🗺️ 네비게이션 경로 표시 시작: ${nodeIds.length}개 노드');

      // 현재 층의 노드 맵 로드
      final currentFloorNum = _selectedFloor?['Floor_Number'].toString() ?? '1';
      Map<String, Map<String, Offset>> floorNodesMap = {};
      await _loadNodesForFloor(currentFloorNum, floorNodesMap);

      // 노드 ID를 좌표로 변환
      final pathOffsets = _convertNodeIdsToOffsets(
        nodeIds,
        currentFloorNum,
        floorNodesMap,
      );

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

  // 네비게이션 경로에 포커스
  void _focusOnNavigationPath() {
    if (_navigationPath.isNotEmpty) {
      // 경로의 중심점 계산
      double centerX =
          _navigationPath.map((p) => p.dx).reduce((a, b) => a + b) /
          _navigationPath.length;
      double centerY =
          _navigationPath.map((p) => p.dy).reduce((a, b) => a + b) /
          _navigationPath.length;

      // 적절한 줌 레벨로 이동 (구현 필요)
      debugPrint('📍 네비게이션 경로 중심: ($centerX, $centerY)');
    }
  }

  // 노드 ID를 Offset으로 변환 (개선된 버전)
  List<Offset> _convertNodeIdsToOffsets(List<String> nodeIds, String floorNum, Map<String, Map<String, Offset>> floorNodesMap) {
  try {
    // 🔥 입력 값 검증
    if (nodeIds.isEmpty) {
      debugPrint('⚠️ nodeIds가 비어있음');
      return [];
    }
    
    if (floorNum.isEmpty) {
      debugPrint('⚠️ floorNum이 비어있음');
      return [];
    }

    final floorNumStr = floorNum.toString();
    final nodeMap = floorNodesMap[floorNumStr];
    
    if (nodeMap == null || nodeMap.isEmpty) {
      debugPrint('⚠️ 층 $floorNumStr의 노드 맵이 비어있음 또는 null');
      return [];
    }

    final offsets = <Offset>[];
    for (String nodeId in nodeIds) {
      try {
        if (nodeId.isEmpty) {
          debugPrint('⚠️ 빈 nodeId 건너뛰기');
          continue;
        }

        String simpleId = nodeId.contains('@') ? nodeId.split('@').last : nodeId;
        if (simpleId.startsWith('R')) {
          simpleId = simpleId.substring(1);
        }

        if (simpleId.isEmpty) {
          debugPrint('⚠️ simpleId가 비어있음: $nodeId');
          continue;
        }

        final offset = nodeMap[simpleId];
        if (offset != null) {
          offsets.add(offset);
          debugPrint('✅ 노드 변환: $nodeId -> $simpleId -> $offset');
        } else {
          debugPrint('❌ 노드 찾기 실패: $nodeId (simpleId: $simpleId)');
        }
      } catch (e) {
        debugPrint('❌ 개별 노드 처리 오류: $nodeId - $e');
        continue;
      }
    }

    debugPrint('📊 노드 변환 결과: ${nodeIds.length}개 중 ${offsets.length}개 성공');
    return offsets;
  } catch (e) {
    debugPrint('❌ _convertNodeIdsToOffsets 전체 오류: $e');
    return [];
  }
}

  void _onFloorChanged(Map<String, dynamic> newFloor) {
    final newFloorNumber = newFloor['Floor_Number'].toString();

    if (_selectedFloor?['Floor_Id'] == newFloor['Floor_Id'] && _error == null)
      return;

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

  // 기존 _findAndDrawPath를 통합 API 사용으로 수정
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
      // 통합 API 요청 준비
      final fromBuilding = widget.buildingName;
      final fromFloor = int.parse(_startPoint!['floorNumber'].toString());
      final fromRoom = (_startPoint!['roomId'] as String).replaceFirst('R', '');

      final toBuilding = _endPoint!['buildingName'] ?? widget.buildingName;
      final toFloor = int.parse(_endPoint!['floorNumber'].toString());
      final toRoom = (_endPoint!['roomId'] as String).replaceFirst('R', '');

      debugPrint('🚀 통합 API 경로 요청:');
      debugPrint('   출발: $fromBuilding $fromFloor층 $fromRoom호');
      debugPrint('   도착: $toBuilding $toFloor층 $toRoom호');

      // 통합 경로 API 호출
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

      // 통합 응답 처리
      await _processUnifiedPathResponse(response, fromFloor, toFloor);
    } catch (e) {
      _clearAllPathInfo();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('통합 길찾기 중 오류가 발생했습니다: $e')));
      debugPrint('❌ 통합 길찾기 오류: $e');
    } finally {
      if (mounted) setState(() => _isMapLoading = false);
    }
  }

  // 통합 API 응답 처리 메서드
  Future<void> _processUnifiedPathResponse(
    UnifiedPathResponse response,
    int fromFloor,
    int toFloor,
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

  // 호실 → 호실 응답 처리
  Future<void> _handleRoomToRoomResponse(
    PathResult result,
    int fromFloor,
    int toFloor,
  ) async {
    final departureIndoor = result.departureIndoor;
    final arrivalIndoor = result.arrivalIndoor;
    final outdoor = result.outdoor;

    if (departureIndoor != null && outdoor != null && arrivalIndoor != null) {
      // 다른 건물 간 호실 이동
      debugPrint('🏢 다른 건물 간 호실 이동');

      final depNodeIds = UnifiedPathService.extractIndoorNodeIds(
        departureIndoor,
      );
      await _processIndoorPath(depNodeIds, fromFloor, true); // 출발지 경로

      _showOutdoorTransitionMessage(outdoor);
    } else if (arrivalIndoor != null) {
      // 같은 건물 내 호실 이동
      debugPrint('🏠 같은 건물 내 호실 이동');

      final nodeIds = UnifiedPathService.extractIndoorNodeIds(arrivalIndoor);
      await _processSameBuildingPath(nodeIds, fromFloor, toFloor);
    }
  }

  // 호실 → 건물 응답 처리
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

  // 건물 → 호실 응답 처리
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

  // 건물 → 건물 응답 처리
  void _handleBuildingToBuildingResponse(PathResult result) {
    final outdoor = result.outdoor;

    if (outdoor != null) {
      _showOutdoorTransitionMessage(outdoor);
    }
  }

  // 실내 경로 처리
  Future<void> _processIndoorPath(List<String> nodeIds, int floorNumber, bool isDeparture) async {
    debugPrint('🗺️ 실내 경로 처리: ${nodeIds.length}개 노드, 층: $floorNumber');

    final floorNumStr = floorNumber.toString();
    Map<String, Map<String, Offset>> floorNodesMap = {};
    await _loadNodesForFloor(floorNumStr, floorNodesMap);

    final pathOffsets = _convertNodeIdsToOffsets(
      nodeIds,
      floorNumStr,
      floorNodesMap,
    );

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

  // 같은 건물 내 경로 처리
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
      int splitIndex = nodeIds.indexWhere(
        (id) => id.split('@')[1] != fromFloorStr,
      );
      if (splitIndex == -1) splitIndex = nodeIds.length;

      final depOffsets = _convertNodeIdsToOffsets(
        nodeIds.sublist(0, splitIndex),
        fromFloorStr,
        floorNodesMap,
      );
      final arrOffsets = _convertNodeIdsToOffsets(
        nodeIds.sublist(splitIndex),
        toFloorStr,
        floorNodesMap,
      );

      setState(() {
        _departurePath = depOffsets;
        _arrivalPath = arrOffsets;
        _currentShortestPath =
            _selectedFloor?['Floor_Number'].toString() == fromFloorStr
            ? depOffsets
            : arrOffsets;
        _transitionInfo = {"from": fromFloorStr, "to": toFloorStr};
      });

      _showAndFadePrompt();
    } else {
      // 같은 층 내 이동
      final sameFloorOffsets = _convertNodeIdsToOffsets(
        nodeIds,
        fromFloorStr,
        floorNodesMap,
      );
      setState(() => _currentShortestPath = sameFloorOffsets);
    }
  }

  // 실외 전환 메시지 표시
  void _showOutdoorTransitionMessage(OutdoorPathData outdoorData) {
    final coordinates = UnifiedPathService.extractOutdoorCoordinates(
      outdoorData,
    );
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

  // 네비게이션 완료 처리
  void _completeNavigation() {
    if (widget.navigationController != null) {
      // 통합 네비게이션 컨트롤러에 완료 신호
      widget.navigationController!.proceedToNextStep();
    }

    // 결과와 함께 페이지 종료
    Navigator.of(context).pop('completed');
  }

  Future<void> _loadFloorList(
    String buildingName, {
    String? targetFloorNumber,
  }) async {
    setState(() {
      _isFloorListLoading = true;
      _error = null;
    });

    try {
      final floors = await _apiService.fetchFloorList(buildingName);

      if (mounted) {
        // navigationNodeIds에 포함된 층만 필터링
        final allowedFloors = widget.navigationNodeIds
            ?.map((id) => id.split('@')[1])
            .toSet();

        final filteredFloors = allowedFloors != null
            ? floors
                  .where(
                    (f) => allowedFloors.contains(f['Floor_Number'].toString()),
                  )
                  .toList()
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

          selectedFloor['Floor_Number'] = selectedFloor['Floor_Number']
              .toString();
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

  // Release 모드 최적화된 _loadMapData
  Future<void> _loadMapData(Map<String, dynamic> floorInfo) async {
    setState(() => _isMapLoading = true);
    _addDebugInfo('🔥 지도 로딩 시작 (${isReleaseMode ? "Release" : "Debug"} 모드)');

    try {
      final svgUrl = floorInfo['File'] as String?;
      if (svgUrl == null || svgUrl.isEmpty) {
        throw Exception('SVG URL이 유효하지 않습니다.');
      }

      _addDebugInfo('📍 URL: ${svgUrl.substring(0, 50)}...');

      // Release 모드에서 캐시 무효화
      final urlWithCache = isReleaseMode 
          ? '$svgUrl?release=${DateTime.now().millisecondsSinceEpoch}'
          : svgUrl;

      final svgResponse = await http.get(
        Uri.parse(urlWithCache),
        headers: {
          'Accept': 'image/svg+xml,*/*',
          'User-Agent': 'FlutterApp/1.0 ${isReleaseMode ? "Release" : "Debug"}',
          'Cache-Control': isReleaseMode 
              ? 'no-cache, no-store, must-revalidate, max-age=0'
              : 'no-cache',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      ).timeout(const Duration(seconds: 15));
      
      _addDebugInfo('📊 상태코드: ${svgResponse.statusCode}');
      _addDebugInfo('📏 콘텐츠 길이: ${svgResponse.body.length}');
      
      if (svgResponse.statusCode == 200) {
        final svgContent = svgResponse.body;
        
        if (svgContent.isEmpty) {
          _addDebugInfo('❌ 빈 SVG 응답');
          throw Exception('빈 SVG 응답');
        }
        
        if (!svgContent.contains('<svg')) {
          _addDebugInfo('❌ SVG 태그 없음');
          throw Exception('올바르지 않은 SVG 형식');
        }
        
        final buttons = SvgDataParser.parseButtonData(svgContent);
        _addDebugInfo('🔥 버튼 파싱: ${buttons.length}개');

        if (mounted) {
          setState(() {
            _svgUrl = urlWithCache; // 캐시 무효화된 URL 사용
            _buttonData = buttons;
            _isMapLoading = false;
          });
          
          _addDebugInfo('✅ SVG 로딩 성공! (${isReleaseMode ? "Release" : "Debug"} 모드)');
          
          if (_shouldAutoSelectRoom) {
            _handleAutoRoomSelection();
          }
        }
      } else {
        _addDebugInfo('❌ HTTP 에러: ${svgResponse.statusCode}');
        throw Exception('HTTP ${svgResponse.statusCode}: ${svgResponse.reasonPhrase}');
      }
      
    } catch (e) {
      _addDebugInfo('❌ 에러: $e');
      
      if (mounted) {
        setState(() {
          _isMapLoading = false;
          _error = '지도 로딩 실패: $e';
        });
      }
    }
  }

  // CORS 문제 해결을 위한 강화된 _loadNodesForFloor
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
        try {
          // CORS 문제 해결을 위한 헤더 추가
          final svgResponse = await http.get(
            Uri.parse(svgUrl),
            headers: {
              'Accept': '*/*',
              'User-Agent': 'FlutterApp/1.0',
              'Cache-Control': 'no-cache',
              'Origin': 'https://flutter-app',
              'Access-Control-Request-Method': 'GET',
            },
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('노드 로딩 시간 초과');
            },
          );
          
          if (svgResponse.statusCode == 200) {
            targetMap[floorNumber] = SvgDataParser.parseAllNodes(
              svgResponse.body,
            );
            debugPrint('✅ 층 $floorNumber 노드 로딩 성공');
          } else {
            debugPrint('❌ 층 $floorNumber 노드 로딩 실패: ${svgResponse.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ 층 $floorNumber 노드 로딩 오류: $e');
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
        buildingName: widget.buildingName,
        floorNumber: _selectedFloor?['Floor_Number'],
      ),
    );

    if (mounted) setState(() => _selectedRoomId = null);
  }

  // 네비게이션 모드용 호실 정보 시트
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
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
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

  // 경로 정보 초기화 메서드
  void _clearAllPathInfo() {
    setState(() {
      _startPoint = null;
      _endPoint = null;
      _departurePath = [];
      _arrivalPath = [];
      _currentShortestPath = [];
      _navigationPath = [];
      _transitionInfo = null;
      _selectedRoomId = null;
    });
    
    // 변환 컨트롤러 초기화
    _transformationController.value = Matrix4.identity();
    
    debugPrint('🧹 모든 경로 정보가 초기화되었습니다');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('경로가 초기화되었습니다'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.buildingName} 실내 안내도'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.bug_report),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('디버깅 정보'),
                  content: Container(
                    width: double.maxFinite,
                    height: 400,
                    child: SingleChildScrollView(
                      child: Text(_debugInfo.isEmpty ? '로그 없음' : _debugInfo),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('닫기'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 메인 콘텐츠 영역
          Positioned.fill(
            child: _buildBodyContentWithRealButtons(),
          ),
          
          // 층 선택 버튼 (왼쪽 하단, 세로 배치)
          if (_floorList.length > 1)
            Positioned(
              left: 16,
              bottom: 120,
              child: Card(
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
              ),
            ),
        ],
      ),
    );
  }

  // Stack 최소화된 메인 콘텐츠
  Widget _buildBodyContentWithRealButtons() {
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

        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          onInteractionEnd: (details) => _resetScaleAfterDelay(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails details) {
              final Offset scenePoint = _transformationController.toScene(
                details.localPosition,
              );
              final Offset svgTapPosition = Offset(
                (scenePoint.dx - leftOffset) / (totalScale * svgScale),
                (scenePoint.dy - topOffset) / (totalScale * svgScale),
              );

              _addDebugInfo('👆 터치: ${svgTapPosition.dx.toInt()}, ${svgTapPosition.dy.toInt()}');

              for (var button in _buttonData.reversed) {
                bool isHit = false;
                if (button['type'] == 'path') {
                  isHit = (button['path'] as Path).contains(svgTapPosition);
                } else {
                  isHit = (button['rect'] as Rect).contains(svgTapPosition);
                }
                
                if (isHit) {
                  _addDebugInfo('✅ 터치된 호실: ${button['id']}');
                  _showRoomInfoSheet(context, button['id']);
                  break;
                }
              }
            },
            child: Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              color: Colors.grey.shade100,
              child: Center(
                child: Container(
                  width: svgDisplayWidth,
                  height: svgDisplayHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        // SVG 렌더링 (Stack 안에서만)
                        Positioned.fill(
                          child: SvgPicture.network(
                            _svgUrl!,
                            fit: BoxFit.contain,
                            headers: {
                              'Accept': 'image/svg+xml,*/*',
                              'User-Agent': 'FlutterApp/1.0',
                            },
                            placeholderBuilder: (context) => Container(
                              color: Colors.yellow.shade100,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(color: Colors.blue),
                                    SizedBox(height: 8),
                                    Text('지도 로딩중...', style: TextStyle(color: Colors.blue)),
                                  ],
                                ),
                              ),
                            ),
                            errorBuilder: (context, error, stackTrace) {
                              _addDebugInfo('❌ SVG 에러: $error');
                              return Container(
                                color: Colors.red.shade100,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error, color: Colors.red, size: 32),
                                      SizedBox(height: 8),
                                      Text('SVG 로딩 실패', style: TextStyle(color: Colors.red)),
                                      SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: () => _loadMapData(_selectedFloor!),
                                        child: Text('재시도'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // 경로 표시 (단순화)
                        if (_currentShortestPath.isNotEmpty || _navigationPath.isNotEmpty)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: PathPainter(
                                pathPoints: _navigationPath.isNotEmpty 
                                    ? _navigationPath 
                                    : _currentShortestPath,
                                scale: totalScale * svgScale,
                                pathColor: _isNavigationMode ? Colors.blue : Colors.red,
                              ),
                            ),
                          ),
                        
                        // 선택된 호실 하이라이트
                        if (_selectedRoomId != null)
                          ..._buttonData.where((button) => button['id'] == _selectedRoomId).map((button) {
                            final Rect bounds = button['type'] == 'path'
                                ? (button['path'] as Path).getBounds()
                                : button['rect'];
                            final scaledRect = Rect.fromLTWH(
                              bounds.left * totalScale * svgScale,
                              bounds.top * totalScale * svgScale,
                              bounds.width * totalScale * svgScale,
                              bounds.height * totalScale * svgScale,
                            );
                            
                            return Positioned.fromRect(
                              rect: scaledRect,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.3),
                                  border: Border.all(color: Colors.blue, width: 2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 시간 조정 가능한 _resetScaleAfterDelay
  void _resetScaleAfterDelay({int duration = 3000}) {
    _resetTimer?.cancel();
    _resetTimer = Timer(Duration(milliseconds: duration), () {
      if (mounted) {
        _transformationController.value = Matrix4.identity();
      }
    });
  }
}
