import 'package:flutter/material.dart';
import 'package:flutter_application_1/inside/building_map_page.dart';
import 'package:flutter_application_1/outdoor_map_page.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

List<NLatLng> convertToNLatLngList(List<Map<String, dynamic>> path) {
  return path.map((point) {
    final lat = point['x'] ?? point['lat'];
    final lng = point['y'] ?? point['lng'];
    return NLatLng((lat as num).toDouble(), (lng as num).toDouble());
  }).toList();
}

class UnifiedNavigationStepperPage extends StatefulWidget {
  final String departureBuilding;
  final List<String> departureNodeIds;
  final List<Map<String, dynamic>> outdoorPath;
  final double outdoorDistance;
  final String arrivalBuilding;
  final List<String> arrivalNodeIds;

  const UnifiedNavigationStepperPage({
    required this.departureBuilding,
    required this.departureNodeIds,
    required this.outdoorPath,
    required this.outdoorDistance,
    required this.arrivalBuilding,
    required this.arrivalNodeIds,
    super.key,
  });

  @override
  State<UnifiedNavigationStepperPage> createState() => _UnifiedNavigationStepperPageState();
}

class _UnifiedNavigationStepperPageState extends State<UnifiedNavigationStepperPage> {
  final List<_StepData> _steps = [];
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();

    // 출발 실내 경로가 있다면 층별로 분리하여 단계 추가 (서버 순서대로)
    if (widget.departureNodeIds.isNotEmpty) {
      final depFloors = _splitNodeIdsByFloor(widget.departureNodeIds);
      for (final floor in depFloors.keys) {
        _steps.add(_StepData(
          type: StepType.indoor,
          building: widget.departureBuilding,
          nodeIds: depFloors[floor]!,
          isArrival: false,
        ));
      }
    }

    // 실외 경로가 있다면 단계 추가
    if (widget.outdoorPath.isNotEmpty) {
      _steps.add(_StepData(
        type: StepType.outdoor,
        outdoorPath: widget.outdoorPath,
        outdoorDistance: widget.outdoorDistance,
      ));
    }

    // 도착 실내 경로가 있다면 층별로 분리하여 단계 추가 (서버 순서대로)
    if (widget.arrivalNodeIds.isNotEmpty) {
      final arrFloors = _splitNodeIdsByFloor(widget.arrivalNodeIds);
      for (final floor in arrFloors.keys) {
        _steps.add(_StepData(
          type: StepType.indoor,
          building: widget.arrivalBuilding,
          nodeIds: arrFloors[floor]!,
          isArrival: true,
        ));
      }
    }
  }

  void _goToPreviousStep() {
    setState(() {
      if (_currentStepIndex > 0) _currentStepIndex--;
    });
  }

  void _goToNextStep() {
    setState(() {
      if (_currentStepIndex < _steps.length - 1) {
        _currentStepIndex++;
      }
    });
  } 

  void _finishNavigation() {
    Navigator.of(context).pop();
  }

  Map<String, List<String>> _splitNodeIdsByFloor(List<String> nodeIds) {
    final Map<String, List<String>> floorMap = {};
    for (final id in nodeIds) {
      final parts = id.split('@');
      if (parts.length >= 3) {
        final floor = parts[1];
        floorMap.putIfAbsent(floor, () => []).add(id);
      }
    }
    return floorMap;
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_currentStepIndex];
    final isLastStep = _currentStepIndex == _steps.length - 1;

    Widget content;
    if (currentStep.type == StepType.indoor) {
      content = BuildingMapPage(
        buildingName: currentStep.building,
        navigationNodeIds: currentStep.nodeIds,
        isArrivalNavigation: currentStep.isArrival,
      );
    } else {
      String startLabel = '내 위치';
      String endLabel = widget.arrivalBuilding;
      
      if (widget.departureBuilding.isNotEmpty) {
        startLabel = widget.departureBuilding;
      }
      
      content = OutdoorMapPage(
        path: convertToNLatLngList(currentStep.outdoorPath!),
        distance: currentStep.outdoorDistance!,
        showMarkers: true,
        startLabel: startLabel,
        endLabel: endLabel,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getCurrentStepTitle()),
        backgroundColor: currentStep.type == StepType.indoor ? Colors.indigo : Colors.blue,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentStepIndex + 1}/${_steps.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: content,
      bottomNavigationBar: _buildSimpleBottomBar(currentStep, isLastStep),
    );
  }

  String _getCurrentStepTitle() {
    final currentStep = _steps[_currentStepIndex];
    
    if (currentStep.type == StepType.indoor) {
      if (currentStep.isArrival) {
        return '${currentStep.building} 실내 도착';
      } else {
        return '${currentStep.building} 실내 출발';
      }
    } else {
      return '길찾기'; // 🔥 실외에서는 단순하게 "길찾기"만 표시
    }
  }

  // 🔥 실외에서는 버튼만, 실내에서는 기존 방식
  Widget _buildSimpleBottomBar(_StepData currentStep, bool isLastStep) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🔥 이전 버튼
          ElevatedButton(
            onPressed: _currentStepIndex > 0 ? _goToPreviousStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('이전'),
          ),
          
          // 🔥 다음/완료 버튼
          if (!isLastStep)
            ElevatedButton(
              onPressed: _goToNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: currentStep.type == StepType.indoor 
                    ? Colors.indigo 
                    : Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('다음'),
            ),
          if (isLastStep)
            ElevatedButton(
              onPressed: _finishNavigation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('완료'),
            ),
        ],
      ),
    );
  }
}

enum StepType { indoor, outdoor }

class _StepData {
  final StepType type;
  final String building;
  final List<String> nodeIds;
  final bool isArrival;
  final List<Map<String, dynamic>>? outdoorPath;
  final double? outdoorDistance;

  _StepData({
    required this.type,
    this.building = '',
    this.nodeIds = const [],
    this.isArrival = false,
    this.outdoorPath,
    this.outdoorDistance,
  });
}