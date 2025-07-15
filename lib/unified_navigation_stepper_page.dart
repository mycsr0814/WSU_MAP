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

    // 출발 실내 경로가 있다면 층별로 분리하여 단계 추가 (높은 층 → 낮은 층)
    if (widget.departureNodeIds.isNotEmpty) {
      final depFloors = _splitNodeIdsByFloor(widget.departureNodeIds);
      final sortedFloors = depFloors.keys.toList()..sort((a, b) => int.parse(b).compareTo(int.parse(a)));
      for (final floor in sortedFloors) {
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

    // 도착 실내 경로가 있다면 층별로 분리하여 단계 추가 (낮은 층 → 높은 층)
    if (widget.arrivalNodeIds.isNotEmpty) {
      final arrFloors = _splitNodeIdsByFloor(widget.arrivalNodeIds);
      final sortedFloors = arrFloors.keys.toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      for (final floor in sortedFloors) {
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
      content = OutdoorMapPage(
        path: convertToNLatLngList(currentStep.outdoorPath!),
        distance: currentStep.outdoorDistance!,
      );
    }

    return Scaffold(
      body: content,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 항상 이전 버튼 표시 (첫 단계만 비활성화)
            ElevatedButton(
              onPressed: _currentStepIndex > 0 ? _goToPreviousStep : null,
              child: const Text('이전'),
            ),
            if (!isLastStep)
              ElevatedButton(
                onPressed: _goToNextStep,
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
