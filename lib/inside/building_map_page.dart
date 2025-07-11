// lib/page/building_map_page.dart (정밀 터치 감지 기능 최종 적용)

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

// 실제 프로젝트 경로에 맞게 수정해주세요.
import '../inside/api_service.dart';
import '../inside/svg_data_parser.dart';
import '../inside/room_info.dart';
import '../inside/room_info_sheet.dart';
import '../inside/room_shape_painter.dart';
import '../inside/path_painter.dart';

class BuildingMapPage extends StatefulWidget {
  final String buildingName;
  const BuildingMapPage({super.key, required this.buildingName});

  @override
  State<BuildingMapPage> createState() => _BuildingMapPageState();
}

class _BuildingMapPageState extends State<BuildingMapPage> {
  // --- 상태 변수: 모든 변수는 이전과 동일합니다 ---
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
  static const double svgScale = 0.7;
  bool _showTransitionPrompt = false;
  Timer? _promptTimer;

  // --- initState, dispose, 및 다른 모든 함수는 이전과 동일합니다 ---
  @override
  void initState() {
    super.initState();
    _loadFloorList(widget.buildingName);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _resetTimer?.cancel();
    _promptTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFloorList(String buildingName) async {
    setState(() {
      _isFloorListLoading = true;
      _error = null;
    });
    try {
      final floors = await _apiService.fetchFloorList(buildingName);
      if (mounted) {
        setState(() {
          _floorList = floors;
          _isFloorListLoading = false;
        });
        if (_floorList.isNotEmpty) {
          _onFloorChanged(_floorList.first);
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
      final allNodes = SvgDataParser.parseAllNodes(svgContent);
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

  void _onFloorChanged(Map<String, dynamic> newFloor) {
    if (_selectedFloor?['Floor_Id'] == newFloor['Floor_Id'] && _error == null)
      return;
    setState(() {
      _selectedFloor = newFloor;
      if (_transitionInfo != null) {
        if (newFloor['Floor_Number'].toString() == _transitionInfo!['from'])
          _currentShortestPath = _departurePath;
        else if (newFloor['Floor_Number'].toString() == _transitionInfo!['to'])
          _currentShortestPath = _arrivalPath;
        else
          _currentShortestPath = [];
      } else {
        final bool shouldResetPath =
            _startPoint?['floorId'] != newFloor['Floor_Id'] ||
            _endPoint?['floorId'] != newFloor['Floor_Id'];
        if (shouldResetPath) _currentShortestPath = [];
      }
    });
    _loadMapData(newFloor);
    if (_transitionInfo != null) {
      _showAndFadePrompt();
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
    });
  }

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
      final int fromFloor = int.parse(_startPoint!['floorNumber'].toString());
      final int toFloor = int.parse(_endPoint!['floorNumber'].toString());
      final String fromRoom = (_startPoint!['roomId'] as String).replaceFirst(
        'R',
        '',
      );
      final String toRoom = (_endPoint!['roomId'] as String).replaceFirst(
        'R',
        '',
      );
      final response = await _apiService.findPath(
        fromBuilding: widget.buildingName,
        fromFloor: fromFloor,
        fromRoom: fromRoom,
        toBuilding: widget.buildingName,
        toFloor: toFloor,
        toRoom: toRoom,
      );
      if (response['type'] == 'room-room' &&
          response['result']?['arrival_indoor']?['path']?['path'] != null) {
        final List<dynamic> pathNodeIds =
            response['result']['arrival_indoor']['path']['path'];
        final String fromFloorNumStr = fromFloor.toString();
        final String toFloorNumStr = toFloor.toString();
        final bool isCrossFloor = fromFloorNumStr != toFloorNumStr;
        Map<String, Map<String, Offset>> floorNodesMap = {};
        await Future.wait([
          _loadNodesForFloor(fromFloorNumStr, floorNodesMap),
          if (isCrossFloor) _loadNodesForFloor(toFloorNumStr, floorNodesMap),
        ]);
        List<Offset> convertIdsToOffsets(List<dynamic> ids, String floorNum) {
          final nodeMap = floorNodesMap[floorNum] ?? {};
          if (nodeMap.isEmpty) return [];
          return ids
              .map((nodeId) {
                String simpleId = (nodeId as String)
                    .split('@')
                    .last
                    .replaceFirst('R', '');
                return nodeMap[simpleId];
              })
              .where((offset) => offset != null)
              .cast<Offset>()
              .toList();
        }

        if (isCrossFloor) {
          int splitIndex = pathNodeIds.indexWhere(
            (id) => (id as String).split('@')[1] != fromFloorNumStr,
          );
          if (splitIndex == -1) splitIndex = pathNodeIds.length;
          final depOffsets = convertIdsToOffsets(
            pathNodeIds.sublist(0, splitIndex),
            fromFloorNumStr,
          );
          final arrOffsets = convertIdsToOffsets(
            pathNodeIds.sublist(splitIndex),
            toFloorNumStr,
          );
          setState(() {
            _departurePath = depOffsets;
            _arrivalPath = arrOffsets;
            _currentShortestPath =
                _selectedFloor?['Floor_Number'].toString() == fromFloorNumStr
                ? depOffsets
                : arrOffsets;
            _transitionInfo = {"from": fromFloorNumStr, "to": toFloorNumStr};
          });
          _showAndFadePrompt();
        } else {
          final sameFloorOffsets = convertIdsToOffsets(
            pathNodeIds,
            fromFloorNumStr,
          );
          setState(() => _currentShortestPath = sameFloorOffsets);
        }
      } else {
        _clearAllPathInfo();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('경로를 찾을 수 없습니다.')));
      }
    } catch (e) {
      _clearAllPathInfo();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('길찾기 중 오류가 발생했습니다: $e')));
    } finally {
      if (mounted) setState(() => _isMapLoading = false);
    }
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
      if (type == 'start')
        _startPoint = pointData;
      else
        _endPoint = pointData;
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

  /// 방 버튼 클릭 시 서버에서 설명 받아와서 RoomInfoSheet(모달)로 표시
  void _showRoomInfoSheet(BuildContext context, String roomId) async {
    setState(() => _selectedRoomId = roomId);

    // R이 앞에 붙어있으면 제거 (서버 요청과 화면 표시 모두에 사용)
    String roomIdNoR = roomId.startsWith('R') ? roomId.substring(1) : roomId;

    String roomDesc = '';
    try {
      // 서버에서 방 설명 받아오기 (GET)
      roomDesc = await _apiService.fetchRoomDescription(
        buildingName: widget.buildingName,
        floorNumber: _selectedFloor?['Floor_Number'],
        roomName: roomIdNoR, // 서버에도 R을 뺀 값으로 전달
      );
    } catch (e) {
      print(e);
      roomDesc = '설명을 불러오지 못했습니다.';
    }

    // RoomInfoSheet 모달로 방 정보 표시 (name에 R 뺀 값)
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => RoomInfoSheet(
        roomInfo: RoomInfo(id: roomId, name: roomIdNoR, desc: roomDesc),
        onDeparture: () {
          setState(
            () => _startPoint = {
              "floorId": _selectedFloor?['Floor_Id'],
              "floorNumber":
                  _selectedFloor?['Floor_Number'], // [수정] 이 줄을 추가하세요.
              "roomId": roomId,
            },
          );
          if (_endPoint != null) _findAndDrawPath();
          Navigator.pop(context);
        },
        onArrival: () {
          setState(
            () => _endPoint = {
              "floorId": _selectedFloor?['Floor_Id'],
              "floorNumber":
                  _selectedFloor?['Floor_Number'], // [수정] 이 줄을 추가하세요.
              "roomId": roomId,
            },
          );
          if (_startPoint != null) _findAndDrawPath();
          Navigator.pop(context);
        },
      ),
    );
    if (mounted) setState(() => _selectedRoomId = null);
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
        title: Text('${widget.buildingName} 실내 안내도'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearAllPathInfo,
            tooltip: '초기화',
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(child: _buildBodyContent()),
          if (!_isFloorListLoading && _error == null)
            Positioned(left: 16, bottom: 120, child: _buildFloorSelector()),
          _buildPathInfo(),
          _buildTransitionPrompt(),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isFloorListLoading)
      return const Center(child: Text('층 목록을 불러오는 중...'));
    if (_error != null)
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
    if (_isMapLoading) return const Center(child: CircularProgressIndicator());
    if (_svgUrl == null) return const Center(child: Text('층을 선택해주세요.'));
    return _buildMapView();
  }

  /// [핵심 최종 수정] 확대/축소를 지원하는 정밀 터치 및 정밀 테두리 그리기가 적용된 지도 위젯
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

        // [구조 변경] InteractiveViewer를 GestureDetector로 감싸서 탭 이벤트를 상위에서 관리
        return GestureDetector(
          behavior: HitTestBehavior.opaque, // 빈 공간도 탭을 감지하도록 설정
          onTapDown: (TapDownDetails details) {
            // [핵심 로직] InteractiveViewer의 현재 변형(줌, 이동) 상태를 반영하여 정확한 탭 좌표를 계산
            final Offset scenePoint = _transformationController.toScene(
              details.localPosition,
            );

            // 계산된 scene 좌표를 원본 SVG 내부의 상대 좌표로 다시 변환
            final Offset svgTapPosition = Offset(
              (scenePoint.dx - leftOffset) / (totalScale * svgScale),
              (scenePoint.dy - topOffset) / (totalScale * svgScale),
            );

            // 모든 버튼을 역순으로 확인하여 클릭된 버튼을 찾음
            for (var button in _buttonData.reversed) {
              bool isHit = false;
              // 버튼 타입에 따라 다른 방식으로 클릭 여부 판별
              if (button['type'] == 'path') {
                isHit = (button['path'] as Path).contains(svgTapPosition);
              } else {
                // 'rect'
                isHit = (button['rect'] as Rect).contains(svgTapPosition);
              }

              if (isHit) {
                _showRoomInfoSheet(context, button['id']);
                break; // 가장 위에 있는 버튼 하나만 처리
              }
            }
          },
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            onInteractionEnd: (details) => _resetScaleAfterDelay(),
            // [구조 변경] InteractiveViewer의 자식은 이제 터치 이벤트를 받지 않음
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 1. SVG 도면 그리기
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

                  // 2. 시각적 피드백(선택 테두리)을 위한 위젯
                  // 이 부분은 더 이상 클릭을 감지하지 않고, 오직 '보여주기' 역할만 함
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
                        // 이 위젯과 자식들이 터치 이벤트를 무시하도록 설정
                        child: CustomPaint(
                          // [연결] RoomShapePainter에 실제 모양 데이터를 전달하여 정밀한 테두리를 그리도록 함
                          painter: RoomShapePainter(
                            isSelected: _selectedRoomId == id,
                            // path가 있으면 path를, 없으면 rect를 전달
                            shape: button['path'] ?? button['rect'],
                          ),
                          size: scaledRect.size,
                        ),
                      ),
                    );
                  }).toList(),

                  // 3. 길찾기 경로 그리기
                  if (_currentShortestPath.isNotEmpty)
                    Positioned(
                      left: leftOffset,
                      top: topOffset,
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: Size(svgDisplayWidth, svgDisplayHeight),
                          painter: PathPainter(
                            pathPoints: _currentShortestPath,
                            scale: totalScale * svgScale,
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

  // --- 나머지 UI 빌드 함수들은 이전과 동일합니다 ---
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
                      ? Colors.indigo.withOpacity(0.8)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${floor['Floor_Number']}F',
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
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

  Widget _buildPathInfo() {
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
