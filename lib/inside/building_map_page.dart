// lib/page/building_map_page.dart (경로 생성 후 출발 층 자동 전환 기능만 적용)

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
  // --- 상태 변수 (기존과 모두 동일) ---
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
        if (newFloor['Floor_Number'].toString() == _transitionInfo!['from']) {
          _currentShortestPath = _departurePath;
        } else if (newFloor['Floor_Number'].toString() ==
            _transitionInfo!['to']) {
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

  // [핵심 수정 1] 출발/도착 지점 설정을 위한 통합 함수
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

    if (mounted) Navigator.pop(context); // 모달 닫기

    // 출발지와 도착지가 모두 설정되면 경로 탐색 실행
    if (_startPoint != null && _endPoint != null) {
      await _findAndDrawPath();

      // [핵심 수정 2] 경로 탐색 후, 현재 층이 출발 층이 아니면 출발 층으로 자동 전환
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

  // [핵심 수정 3] _setPoint 함수를 호출하도록 변경된 모달 표시 함수
  void _showRoomInfoSheet(BuildContext context, String roomId) async {
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
      print(e);
      roomDesc = '설명을 불러오지 못했습니다.';
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => RoomInfoSheet(
        roomInfo: RoomInfo(id: roomId, name: roomIdNoR, desc: roomDesc),
        onDeparture: () => _setPoint('start', roomId),
        onArrival: () => _setPoint('end', roomId),
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
