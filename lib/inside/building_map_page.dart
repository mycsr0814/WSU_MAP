// lib/page/building_map_page.dart (페이드아웃 애니메이션 최종 적용)

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
  // --- 기존 상태 변수 ---
  List<dynamic> _floorList = [];
  Map<String, dynamic>? _selectedFloor;
  String? _svgUrl;
  List<Map<String, dynamic>> _buttonData = [];
  Map<String, Offset> _navNodes = {};
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

  // [추가] --- 페이드아웃 애니메이션을 위한 상태 변수 ---
  bool _showTransitionPrompt = false; // 안내 메시지 표시 여부
  Timer? _promptTimer; // 자동으로 메시지를 숨기기 위한 타이머

  @override
  void initState() {
    super.initState();
    _loadFloorList(widget.buildingName);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _resetTimer?.cancel();
    _promptTimer?.cancel(); // [추가] 위젯이 사라질 때 타이머도 정리
    super.dispose();
  }

  Future<void> _loadFloorList(String buildingName) async {
    setState(() { _isFloorListLoading = true; _error = null; });
    try {
      final floors = await _apiService.fetchFloorList(buildingName);
      if (mounted) {
        setState(() { _floorList = floors; _isFloorListLoading = false; });
        if (_floorList.isNotEmpty) {
          _onFloorChanged(_floorList.first);
        } else {
          setState(() => _error = "이 건물의 층 정보를 찾을 수 없습니다.");
        }
      }
    } catch (e) {
      if (mounted) { setState(() { _isFloorListLoading = false; _error = '층 목록을 불러오는 데 실패했습니다: $e'; }); }
    }
  }

  Future<void> _loadMapData(Map<String, dynamic> floorInfo) async {
    setState(() => _isMapLoading = true);
    try {
      final svgUrl = floorInfo['File'] as String?;
      if (svgUrl == null || svgUrl.isEmpty) throw Exception('SVG URL이 유효하지 않습니다.');
      final svgResponse = await http.get(Uri.parse(svgUrl));
      if (svgResponse.statusCode != 200) throw Exception('SVG 파일을 다운로드할 수 없습니다');
      final svgContent = svgResponse.body;
      final buttons = SvgDataParser.parseButtonData(svgContent);
      final allNodes = SvgDataParser.parseAllNodes(svgContent);
      if (mounted) {
        setState(() { _svgUrl = svgUrl; _buttonData = buttons; _navNodes = allNodes; _isMapLoading = false; });
      }
    } catch (e) {
      if (mounted) { setState(() { _isMapLoading = false; _error = '지도 데이터를 불러오는 데 실패했습니다: $e'; }); }
    }
  }

  void _onFloorChanged(Map<String, dynamic> newFloor) {
    if (_selectedFloor?['Floor_Id'] == newFloor['Floor_Id'] && _error == null) return;
    setState(() {
      _selectedFloor = newFloor;
      if (_transitionInfo != null) {
        if (newFloor['Floor_Number'].toString() == _transitionInfo!['from']) _currentShortestPath = _departurePath;
        else if (newFloor['Floor_Number'].toString() == _transitionInfo!['to']) _currentShortestPath = _arrivalPath;
        else _currentShortestPath = [];
      } else {
        final bool shouldResetPath = _startPoint?['floorId'] != newFloor['Floor_Id'] || _endPoint?['floorId'] != newFloor['Floor_Id'];
        if (shouldResetPath) _currentShortestPath = [];
      }
    });
    _loadMapData(newFloor);

    // [수정] 층간 이동 중에 층을 바꾸면 안내 메시지를 다시 띄워줌
    if (_transitionInfo != null) {
      _showAndFadePrompt();
    }
  }

  void _clearAllPathInfo() {
    _promptTimer?.cancel();
    setState(() {
      _startPoint = null; _endPoint = null; _departurePath = []; _arrivalPath = [];
      _currentShortestPath = []; _transitionInfo = null;
      _showTransitionPrompt = false; // 안내 메시지 숨기기
      _transformationController.value = Matrix4.identity();
    });
  }

  Future<void> _findAndDrawPath() async {
    if (_startPoint == null || _endPoint == null) return;
    setState(() { _isMapLoading = true; _departurePath = []; _arrivalPath = []; _currentShortestPath = []; _transitionInfo = null; });

    try {
      final int fromFloor = int.parse(_startPoint!['floorNumber'].toString());
      final int toFloor = int.parse(_endPoint!['floorNumber'].toString());
      final String fromRoom = (_startPoint!['roomId'] as String).replaceFirst('R', '');
      final String toRoom = (_endPoint!['roomId'] as String).replaceFirst('R', '');

      final response = await _apiService.findPath(
        fromBuilding: widget.buildingName, fromFloor: fromFloor, fromRoom: fromRoom,
        toBuilding: widget.buildingName, toFloor: toFloor, toRoom: toRoom,
      );
      
      if (response['type'] == 'room-room' && response['result']?['arrival_indoor']?['path']?['path'] != null) {
        final List<dynamic> pathNodeIds = response['result']['arrival_indoor']['path']['path'];
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
          return ids.map((nodeId) {
            String simpleId = (nodeId as String).split('@').last.replaceFirst('R', '');
            return nodeMap[simpleId];
          }).where((offset) => offset != null).cast<Offset>().toList();
        }

        if (isCrossFloor) {
          int splitIndex = pathNodeIds.indexWhere((id) => (id as String).split('@')[1] != fromFloorNumStr);
          if (splitIndex == -1) splitIndex = pathNodeIds.length;
          final depOffsets = convertIdsToOffsets(pathNodeIds.sublist(0, splitIndex), fromFloorNumStr);
          final arrOffsets = convertIdsToOffsets(pathNodeIds.sublist(splitIndex), toFloorNumStr);
          setState(() {
            _departurePath = depOffsets; _arrivalPath = arrOffsets;
            _currentShortestPath = _selectedFloor?['Floor_Number'].toString() == fromFloorNumStr ? depOffsets : arrOffsets;
            _transitionInfo = {"from": fromFloorNumStr, "to": toFloorNumStr};
          });
          // [수정] 층간 길찾기 성공 시, 안내 메시지 표시 함수 호출
          _showAndFadePrompt();
        } else {
          final sameFloorOffsets = convertIdsToOffsets(pathNodeIds, fromFloorNumStr);
          setState(() => _currentShortestPath = sameFloorOffsets);
        }
      } else {
        _clearAllPathInfo();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('경로를 찾을 수 없습니다.')));
      }
    } catch (e) {
      _clearAllPathInfo();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('길찾기 중 오류가 발생했습니다: $e')));
    } finally {
      if(mounted) setState(() => _isMapLoading = false);
    }
  }

  Future<void> _loadNodesForFloor(String floorNumber, Map<String, Map<String, Offset>> targetMap) async {
    if (targetMap.containsKey(floorNumber)) return;
    final floorInfo = _floorList.firstWhere((f) => f['Floor_Number'].toString() == floorNumber, orElse: () => null);
    if (floorInfo != null) {
      final svgUrl = floorInfo['File'] as String?;
      if (svgUrl != null && svgUrl.isNotEmpty) {
        final svgResponse = await http.get(Uri.parse(svgUrl));
        if (svgResponse.statusCode == 200) {
          targetMap[floorNumber] = SvgDataParser.parseAllNodes(svgResponse.body);
        }
      }
    }
  }
  
  void _showRoomInfoSheet(BuildContext context, String roomId) async {
    setState(() => _selectedRoomId = roomId);
    if (_selectedFloor == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('오류: 층 정보가 선택되지 않았습니다.')));
      return;
    }
    String roomIdNoR = roomId.startsWith('R') ? roomId.substring(1) : roomId;
    String roomDesc = '설명을 불러오는 중...';

    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (context) => RoomInfoSheet(
        roomInfo: RoomInfo(id: roomId, name: roomIdNoR, desc: roomDesc),
        onDeparture: () => _setPoint('start', roomId), onArrival: () => _setPoint('end', roomId),
      ),
    ).whenComplete(() => { if (mounted) setState(() => _selectedRoomId = null) });

    try {
      final fetchedDesc = await _apiService.fetchRoomDescription(
        buildingName: widget.buildingName,
        floorNumber: _selectedFloor!['Floor_Number'].toString(),
        roomName: roomIdNoR,
      );
      // TODO: 받아온 설명으로 BottomSheet UI 업데이트
    } catch (e) { /* 오류 처리 */ }
  }
  
  void _setPoint(String type, String roomId) {
    final pointData = { "floorId": _selectedFloor?['Floor_Id'], "floorNumber": _selectedFloor?['Floor_Number'], "roomId": roomId };
    setState(() {
      if (type == 'start') _startPoint = pointData;
      else _endPoint = pointData;
    });
    if (_startPoint != null && _endPoint != null) _findAndDrawPath();
    Navigator.pop(context);
  }

  // [추가] 안내 메시지를 표시하고, 몇 초 뒤에 자동으로 사라지게 하는 함수
  void _showAndFadePrompt() {
    setState(() => _showTransitionPrompt = true);

    _promptTimer?.cancel();
    _promptTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showTransitionPrompt = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.buildingName} 실내 안내도'),
        backgroundColor: Colors.indigo,
        actions: [ IconButton(icon: const Icon(Icons.refresh), onPressed: _clearAllPathInfo, tooltip: '초기화'), ],
      ),
      body: Stack(
        children: [
          Center(child: _buildBodyContent()),
          if (!_isFloorListLoading && _error == null) Positioned(left: 16, bottom: 120, child: _buildFloorSelector()),
          _buildPathInfo(),
          _buildTransitionPrompt(), // 애니메이션 위젯 호출
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isFloorListLoading) return const Center(child: Text('층 목록을 불러오는 중...'));
    if (_error != null) return Center(child: Padding( padding: const EdgeInsets.all(16.0), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16),),));
    if (_isMapLoading) return const Center(child: CircularProgressIndicator());
    if (_svgUrl == null) return const Center(child: Text('층을 선택해주세요.'));
    return _buildMapView();
  }

  Widget _buildMapView() {
    const double svgWidth = 210, svgHeight = 297;
    return LayoutBuilder(builder: (context, constraints) {
      final baseScale = min(constraints.maxWidth / svgWidth, constraints.maxHeight / svgHeight);
      final totalScale = baseScale * 1.0;
      final svgDisplayWidth = svgWidth * totalScale * svgScale;
      final svgDisplayHeight = svgHeight * totalScale * svgScale;
      final leftOffset = (constraints.maxWidth - svgDisplayWidth) / 2;
      final topOffset = (constraints.maxHeight - svgDisplayHeight) / 2;

      return InteractiveViewer(
        transformationController: _transformationController, minScale: 0.5, maxScale: 4.0,
        onInteractionEnd: (details) => _resetScaleAfterDelay(),
        child: SizedBox(
          width: constraints.maxWidth, height: constraints.maxHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: leftOffset, top: topOffset,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                  child: SvgPicture.network(_svgUrl!, width: svgDisplayWidth, height: svgDisplayHeight, placeholderBuilder: (context) => const Center(child: CircularProgressIndicator())),
                ),
              ),
              ..._buttonData.map((button) {
                final Rect rect = button['rect']; final String id = button['id'];
                final scaledRect = Rect.fromLTWH(leftOffset + rect.left * totalScale * svgScale, topOffset + rect.top * totalScale * svgScale, rect.width * totalScale * svgScale, rect.height * totalScale * svgScale);
                return Positioned.fromRect( rect: scaledRect,
                  child: GestureDetector( onTap: () => _showRoomInfoSheet(context, id),
                    child: CustomPaint(painter: RoomShapePainter(isSelected: _selectedRoomId == id), child: Container(color: Colors.transparent)),
                  ),
                );
              }).toList(),
              if (_currentShortestPath.isNotEmpty)
                Positioned( left: leftOffset, top: topOffset,
                  child: IgnorePointer(
                    child: CustomPaint(size: Size(svgDisplayWidth, svgDisplayHeight),
                      painter: PathPainter(pathPoints: _currentShortestPath, scale: totalScale * svgScale),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  // [핵심 수정] AnimatedOpacity를 사용하여 페이드 인/아웃 효과 적용
  Widget _buildTransitionPrompt() {
    String? promptText;
    if (_transitionInfo != null && _selectedFloor?['Floor_Number'].toString() == _transitionInfo!['from']) {
      promptText = '${_transitionInfo!['to']}층으로 이동하세요';
    }

    return AnimatedOpacity(
      opacity: _showTransitionPrompt && promptText != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: IgnorePointer( // 애니메이션 중 터치 방지
        child: Positioned(
          bottom: 200, left: 0, right: 0,
          child: Center(
            child: Card(
              color: Colors.redAccent, elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(promptText ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloorSelector() {
    return Card( elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding( padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          children: _floorList.map((floor) {
            final bool isSelected = _selectedFloor?['Floor_Id'] == floor['Floor_Id'];
            return GestureDetector( onTap: () => _onFloorChanged(floor),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: isSelected ? Colors.indigo.withOpacity(0.8) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                child: Text('${floor['Floor_Number']}F', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : Colors.black87, fontSize: 16)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPathInfo() {
    return Positioned( bottom: 16, left: 16, right: 16,
      child: Card( elevation: 6, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding( padding: const EdgeInsets.all(12.0),
          child: Row( mainAxisAlignment: MainAxisAlignment.spaceAround,
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
        Text(id ?? '미지정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
  
  void _resetScaleAfterDelay() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), () { if (mounted) { _transformationController.value = Matrix4.identity(); } });
  }
}
