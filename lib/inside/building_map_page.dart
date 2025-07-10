// lib/page/building_map_page.dart (자동 경로 재탐색 및 출발지 복귀 기능 최종 적용)

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
  // --- 상태 변수: UI와 데이터 관리를 위한 변수들 ---
  List<dynamic> _floorList = []; // 건물 전체 층 목록
  Map<String, dynamic>? _selectedFloor; // 현재 선택된 층 정보
  String? _svgUrl; // 현재 층의 SVG 도면 URL
  List<Map<String, dynamic>> _buttonData = []; // SVG에서 파싱한 버튼(강의실) 데이터
  Map<String, Offset> _navNodes = {}; // 현재 층의 길찾기 노드 좌표 데이터

  // --- 길찾기 관련 상태 변수 ---
  Map<String, dynamic>? _startPoint; // 출발지 정보
  Map<String, dynamic>? _endPoint; // 도착지 정보
  List<Offset> _departurePath = []; // 층간 이동 시 출발층의 경로
  List<Offset> _arrivalPath = []; // 층간 이동 시 도착층의 경로
  List<Offset> _currentShortestPath = []; // 현재 화면에 그려질 최종 경로
  Map<String, String>? _transitionInfo; // 층간 이동 정보 (예: {"from": "1", "to": "2"})

  // --- UI 제어 및 기타 변수 ---
  bool _isFloorListLoading = true; // 층 목록 로딩 상태
  bool _isMapLoading = false; // 지도 데이터(SVG) 로딩 상태
  String? _error; // 오류 메시지
  String? _selectedRoomId; // 사용자가 선택한 방 ID (테두리 표시용)
  final ApiService _apiService = ApiService(); // 서버 통신 서비스
  final TransformationController _transformationController = TransformationController(); // 지도 확대/축소 제어
  Timer? _resetTimer; // 지도 자동 복귀 타이머
  static const double svgScale = 0.7; // SVG 기본 스케일

  // --- 애니메이션 관련 상태 변수 ---
  bool _showTransitionPrompt = false; // 층간 이동 안내 메시지 표시 여부
  Timer? _promptTimer; // 안내 메시지 자동 숨김 타이머

  /// 위젯이 처음 생성될 때 호출
  @override
  void initState() {
    super.initState();
    _loadFloorList(widget.buildingName); // 페이지에 진입하면 층 목록을 불러옵니다.
  }

  /// 위젯이 화면에서 사라질 때 호출
  @override
  void dispose() {
    _transformationController.dispose();
    _resetTimer?.cancel();
    _promptTimer?.cancel(); // 위젯이 종료될 때 모든 타이머를 안전하게 정리합니다.
    super.dispose();
  }

  /// 서버에서 해당 건물의 모든 층 목록을 비동기적으로 불러옵니다.
  Future<void> _loadFloorList(String buildingName) async {
    setState(() { _isFloorListLoading = true; _error = null; });
    try {
      final floors = await _apiService.fetchFloorList(buildingName);
      if (mounted) {
        setState(() { _floorList = floors; _isFloorListLoading = false; });
        if (_floorList.isNotEmpty) {
          _onFloorChanged(_floorList.first); // 성공 시 첫 번째 층을 자동으로 선택합니다.
        } else {
          setState(() => _error = "이 건물의 층 정보를 찾을 수 없습니다.");
        }
      }
    } catch (e) {
      if (mounted) { setState(() { _isFloorListLoading = false; _error = '층 목록을 불러오는 데 실패했습니다: $e'; }); }
    }
  }

  /// 특정 층의 SVG 도면과 내부 노드 데이터를 불러옵니다.
  Future<void> _loadMapData(Map<String, dynamic> floorInfo) async {
    setState(() => _isMapLoading = true);
    try {
      final svgUrl = floorInfo['File'] as String?;
      if (svgUrl == null || svgUrl.isEmpty) throw Exception('SVG URL이 유효하지 않습니다.');
      final svgResponse = await http.get(Uri.parse(svgUrl));
      if (svgResponse.statusCode != 200) throw Exception('SVG 파일을 다운로드할 수 없습니다');
      final svgContent = svgResponse.body;
      final buttons = SvgDataParser.parseButtonData(svgContent); // 클릭 가능한 버튼 영역 파싱
      final allNodes = SvgDataParser.parseAllNodes(svgContent); // 길찾기용 모든 노드 좌표 파싱
      if (mounted) {
        setState(() { _svgUrl = svgUrl; _buttonData = buttons; _navNodes = allNodes; _isMapLoading = false; });
      }
    } catch (e) {
      if (mounted) { setState(() { _isMapLoading = false; _error = '지도 데이터를 불러오는 데 실패했습니다: $e'; }); }
    }
  }
  
  /// 사용자가 층 선택 버튼을 눌렀을 때 호출되는 함수
  void _onFloorChanged(Map<String, dynamic> newFloor) {
    // 이미 선택된 층이면 아무것도 하지 않음
    if (_selectedFloor?['Floor_Id'] == newFloor['Floor_Id'] && _error == null) return;
    
    setState(() {
      _selectedFloor = newFloor;
      // 층간 길찾기 중인 경우, 현재 층에 맞는 경로를 화면에 표시
      if (_transitionInfo != null) {
        if (newFloor['Floor_Number'].toString() == _transitionInfo!['from']) _currentShortestPath = _departurePath;
        else if (newFloor['Floor_Number'].toString() == _transitionInfo!['to']) _currentShortestPath = _arrivalPath;
        else _currentShortestPath = [];
      } else {
        // 길찾기 중이 아닐 때, 다른 층으로 이동하면 기존 경로를 지움
        final bool shouldResetPath = _startPoint?['floorId'] != newFloor['Floor_Id'] || _endPoint?['floorId'] != newFloor['Floor_Id'];
        if (shouldResetPath) _currentShortestPath = [];
      }
    });
    
    _loadMapData(newFloor); // 새롭게 선택된 층의 지도 데이터를 불러옵니다.

    // 층간 이동 중에 층을 바꾸면 안내 메시지를 다시 띄워줍니다.
    if (_transitionInfo != null) {
      _showAndFadePrompt();
    }
  }

  /// 모든 길찾기 관련 정보를 초기화하는 함수 (새로고침 버튼용)
  void _clearAllPathInfo() {
    _promptTimer?.cancel();
    setState(() {
      _startPoint = null; _endPoint = null; _departurePath = []; _arrivalPath = [];
      _currentShortestPath = []; _transitionInfo = null;
      _showTransitionPrompt = false; // 안내 메시지 숨기기
      _transformationController.value = Matrix4.identity(); // 지도 줌/이동 상태 초기화
    });
  }

  /// 출발/도착 지점이 모두 설정되면 서버에 길찾기를 요청하는 핵심 함수
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

  /// 길찾기에 필요한 특정 층의 노드 데이터를 동적으로 로드하는 헬퍼 함수
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
  
  /// [핵심 개선] 출발지/도착지 설정을 통합하여 처리하고 자동 경로 재탐색을 지원하는 함수
  void _setPoint(String type, String roomId) async {
    // 1. 현재 선택된 지점(강의실)의 정보를 Map 형태로 준비합니다.
    final pointData = {
      "floorId": _selectedFloor?['Floor_Id'],
      "floorNumber": _selectedFloor?['Floor_Number'],
      "roomId": roomId
    };

    // 2. '출발' 또는 '도착' 상태를 업데이트하여 하단 정보 UI에 즉시 반영합니다.
    setState(() {
      if (type == 'start') {
        _startPoint = pointData;
      } else { // type == 'end'
        _endPoint = pointData;
      }
    });

    // 3. 사용자 경험을 위해 BottomSheet를 즉시 닫아줍니다.
    if(mounted) Navigator.pop(context);

    // 4. 출발지와 도착지가 모두 설정되었다면, 자동으로 길찾기를 실행합니다.
    //    (예: 기존 경로가 있는 상태에서 출발지만 바꿔도 바로 재탐색)
    if (_startPoint != null && _endPoint != null) {
      // 길찾기 기능이 완료될 때까지 기다립니다.
      await _findAndDrawPath();

      // 5. [사용자 경험 개선] 길찾기 완료 후, 현재 화면이 출발지 층이 아니라면 출발지 층으로 자동 전환합니다.
      final startFloorId = _startPoint!['floorId'];
      final currentFloorId = _selectedFloor?['Floor_Id'];

      if (startFloorId != null && startFloorId != currentFloorId) {
        // 전체 층 목록에서 출발지 층 정보를 찾습니다.
        final startingFloorInfo = _floorList.firstWhere(
          (floor) => floor['Floor_Id'] == startFloorId,
          orElse: () => null,
        );
        
        // 해당 층으로 지도를 전환합니다.
        if (startingFloorInfo != null && mounted) {
          _onFloorChanged(startingFloorInfo);
        }
      }
    }
  }

  /// 사용자가 지도 위의 방(버튼)을 눌렀을 때 정보 시트를 표시하는 함수
  void _showRoomInfoSheet(BuildContext context, String roomId) async {
    setState(() => _selectedRoomId = roomId); // 선택된 방 테두리 표시
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
        // [핵심 개선] 출발/도착 모두 _setPoint 함수를 호출하여 로직을 일관되게 처리합니다.
        onDeparture: () => _setPoint('start', roomId),
        onArrival: () => _setPoint('end', roomId),
      ),
    ).whenComplete(() => { if (mounted) setState(() => _selectedRoomId = null) });

    try {
      // 비동기적으로 방 설명을 불러옵니다 (UI는 이미 표시된 상태).
      final fetchedDesc = await _apiService.fetchRoomDescription(
        buildingName: widget.buildingName,
        floorNumber: _selectedFloor!['Floor_Number'].toString(),
        roomName: roomIdNoR,
      );
      // TODO: 받아온 설명으로 BottomSheet UI를 업데이트하는 로직 (필요 시)
    } catch (e) { /* 오류 처리 */ }
  }

  /// 층간 이동 안내 메시지를 표시하고, 몇 초 뒤 자동으로 사라지게 하는 함수
  void _showAndFadePrompt() {
    setState(() => _showTransitionPrompt = true); // 메시지 보이기
    _promptTimer?.cancel(); // 기존 타이머가 있다면 취소
    _promptTimer = Timer(const Duration(seconds: 3), () { // 3초 타이머 설정
      if (mounted) {
        setState(() => _showTransitionPrompt = false); // 3초 후 메시지 숨기기
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
          _buildTransitionPrompt(),
        ],
      ),
    );
  }

  /// 층 목록, 에러, 로딩 등 상태에 따라 본문 위젯을 결정
  Widget _buildBodyContent() {
    if (_isFloorListLoading) return const Center(child: Text('층 목록을 불러오는 중...'));
    if (_error != null) return Center(child: Padding( padding: const EdgeInsets.all(16.0), child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16),),));
    if (_isMapLoading) return const Center(child: CircularProgressIndicator());
    if (_svgUrl == null) return const Center(child: Text('층을 선택해주세요.'));
    return _buildMapView();
  }

  /// SVG 도면, 방 버튼, 경로 등 실제 지도 UI를 그리는 위젯
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

  /// 층간 이동 안내 메시지를 부드럽게 나타나고 사라지게 하는 위젯
  Widget _buildTransitionPrompt() {
    String? promptText;
    if (_transitionInfo != null && _selectedFloor?['Floor_Number'].toString() == _transitionInfo!['from']) {
      promptText = '${_transitionInfo!['to']}층으로 이동하세요';
    }
    return AnimatedOpacity(
      opacity: _showTransitionPrompt && promptText != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: IgnorePointer(
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

  /// 층 선택 버튼 UI를 그리는 위젯
  Widget _buildFloorSelector() {
    return Card( elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding( padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          children: _floorList.reversed.map((floor) {
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

  /// 화면 하단의 출발/도착 정보 표시 UI
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

  /// 출발 또는 도착 지점의 정보를 표시하는 작은 위젯
  Widget _buildPointInfo(String title, String? id, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(id ?? '미지정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
  
  /// 사용자가 지도를 확대/축소한 후, 3초가 지나면 원래 크기로 복귀시키는 함수
  void _resetScaleAfterDelay() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), () { if (mounted) { _transformationController.value = Matrix4.identity(); } });
  }
}
