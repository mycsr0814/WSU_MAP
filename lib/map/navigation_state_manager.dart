// lib/map/navigation_state_manager.dart - 통합 API 지원 버전

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/controllers/map_controller.dart';
import 'package:flutter_application_1/services/unified_path_service.dart';
import 'package:flutter_application_1/controllers/unified_navigation_controller.dart';
import 'package:provider/provider.dart';

class NavigationStateManager {
  bool _showNavigationStatus = false;
  String _estimatedDistance = '';
  String _estimatedTime = '';
  
  // 🔥 통합 네비게이션 관련 상태
  bool _isUnifiedNavigation = false;
  UnifiedNavigationController? _unifiedController;
  NavigationStep _currentStep = NavigationStep.completed;
  String? _currentInstruction;

  // Getters
  bool get showNavigationStatus => _showNavigationStatus;
  String get estimatedDistance => _estimatedDistance;
  String get estimatedTime => _estimatedTime;
  bool get isUnifiedNavigation => _isUnifiedNavigation;
  NavigationStep get currentStep => _currentStep;
  String? get currentInstruction => _currentInstruction;

  /// 🔥 DirectionsScreen 결과 처리 (통합 API 지원)
  void handleDirectionsResult(Map<String, dynamic> result, BuildContext context) {
    try {
      debugPrint('=== NavigationStateManager 결과 처리 시작 ===');
      debugPrint('받은 결과: $result');

      final type = result['type'] as String?;
      
      if (type == 'unified_navigation') {
        _handleUnifiedNavigationResult(result, context);
      } else {
        _handleLegacyNavigationResult(result, context);
      }
      
    } catch (e) {
      debugPrint('❌ NavigationStateManager 결과 처리 오류: $e');
      _showErrorMessage(context, '길찾기 처리 중 오류가 발생했습니다');
    }
  }

  /// 🔥 통합 네비게이션 결과 처리
void _handleUnifiedNavigationResult(Map<String, dynamic> result, BuildContext context) {
  debugPrint('🚀 통합 네비게이션 결과 처리 시작');

  final startBuilding = result['start'] as Building?;
  final endBuilding = result['end'] as Building?;
  final startRoomInfo = result['startRoomInfo'] as Map<String, dynamic>?;
  final endRoomInfo = result['endRoomInfo'] as Map<String, dynamic>?;
  final useCurrentLocation = result['useCurrentLocation'] as bool? ?? false;
  final pathResponse = result['pathResponse'] as UnifiedPathResponse?;

  _estimatedDistance = result['estimatedDistance'] as String? ?? '';
  _estimatedTime = result['estimatedTime'] as String? ?? '';

  debugPrint('📋 네비게이션 데이터:');
  debugPrint('   출발지: ${startBuilding?.name}');
  debugPrint('   도착지: ${endBuilding?.name}');
  debugPrint('   출발 호실: ${startRoomInfo?['roomName']}');
  debugPrint('   도착 호실: ${endRoomInfo?['roomName']}');
  debugPrint('   현재위치 사용: $useCurrentLocation');
  debugPrint('   경로 응답: ${pathResponse?.type}');

  if (startBuilding != null && endBuilding != null) {
    _isUnifiedNavigation = true;
    _showNavigationStatus = true;

    _startUnifiedNavigationInMapController(
      context: context,
      startBuilding: startBuilding,
      endBuilding: endBuilding,
      startRoomInfo: startRoomInfo,
      endRoomInfo: endRoomInfo,
      useCurrentLocation: useCurrentLocation,
      pathResponse: pathResponse,
    );
  } else {
    debugPrint('❌ 출발지 또는 도착지가 null입니다');
    _showErrorMessage(context, '출발지 또는 도착지 정보가 없습니다');
  }
}

Future<void> _startUnifiedNavigationInMapController({
  required BuildContext context,
  required Building startBuilding,
  required Building endBuilding,
  Map<String, dynamic>? startRoomInfo,
  Map<String, dynamic>? endRoomInfo,
  bool useCurrentLocation = false,
  UnifiedPathResponse? pathResponse,
}) async {
  try {
    debugPrint('🎯 MapController에서 통합 네비게이션 시작');

    final mapController = _getMapController(context);
    if (mapController == null) {
      debugPrint('❌ MapController를 찾을 수 없습니다');
      _showSuccessMessage(context, '통합 길찾기가 시작되었습니다 (디버그 모드)');
      return;
    }

    debugPrint('✅ MapController 발견: ${mapController.runtimeType}');

    bool success = false;

    if (startRoomInfo != null && endRoomInfo != null) {
      debugPrint('🏠 호실 간 네비게이션 시작');
      try {
        success = await mapController.startUnifiedNavigationBetweenRooms(
          fromBuilding: startRoomInfo['buildingName'] ?? '',
          fromFloor: int.tryParse(startRoomInfo['floorNumber'] ?? '1') ?? 1,
          fromRoom: startRoomInfo['roomName'] ?? '',
          toBuilding: endRoomInfo['buildingName'] ?? '',
          toFloor: int.tryParse(endRoomInfo['floorNumber'] ?? '1') ?? 1,
          toRoom: endRoomInfo['roomName'] ?? '',
        );
      } catch (e) {
        debugPrint('❌ startUnifiedNavigationBetweenRooms 오류: $e');
      }
    } else if (useCurrentLocation) {
      debugPrint('📍 현재 위치에서 네비게이션 시작');
      try {
        success = await mapController.startUnifiedNavigationFromCurrentLocation(
          toBuilding: endBuilding,
        );
      } catch (e) {
        debugPrint('❌ startUnifiedNavigationFromCurrentLocation 오류: $e');
      }
    } else {
      debugPrint('🏢 건물 간 네비게이션 시작');
      try {
        success = await mapController.startUnifiedNavigationBetweenBuildings(
          fromBuilding: startBuilding,
          toBuilding: endBuilding,
        );
      } catch (e) {
        debugPrint('❌ startUnifiedNavigationBetweenBuildings 오류: $e');
      }
    }

    if (success) {
      _unifiedController = mapController.navigationController;
      _updateStateFromController();
      _showSuccessMessage(context, '통합 길찾기가 시작되었습니다');
      debugPrint('✅ 통합 네비게이션 시작 성공');
    } else {
      debugPrint('❌ 통합 네비게이션 시작 실패');
      _showErrorMessage(context, '길찾기를 시작할 수 없습니다');
    }
  } catch (e, stack) {
    debugPrint('❌ 통합 네비게이션 처리 중 예외 발생: $e');
    debugPrint('❌ 스택트레이스: $stack');
    _showErrorMessage(context, '길찾기 시작 중 오류가 발생했습니다: $e');
  }
}


  /// 🔥 레거시 네비게이션 결과 처리 (기존 호환성)
void _handleLegacyNavigationResult(Map<String, dynamic> result, BuildContext context) {
  debugPrint('🔄 레거시 네비게이션 결과 처리');

  final startBuilding = result['start'] as Building?;
  final endBuilding = result['end'] as Building?;
  final useCurrentLocation = result['useCurrentLocation'] as bool? ?? false;

  _estimatedDistance = result['estimatedDistance'] as String? ?? '';
  _estimatedTime = result['estimatedTime'] as String? ?? '';

  if (startBuilding != null && endBuilding != null) {
    _isUnifiedNavigation = false;
    _showNavigationStatus = true;

    final mapController = _getMapController(context);
    if (mapController != null) {
      try {
        if (useCurrentLocation) {
          mapController.navigateFromCurrentLocation(endBuilding);
        } else {
          mapController.setStartBuilding(startBuilding);
          mapController.setEndBuilding(endBuilding);
          mapController.calculateRoute();
        }
        _showSuccessMessage(context, '길찾기가 시작되었습니다');
      } catch (e) {
        debugPrint('❌ 레거시 길찾기 오류: $e');
        _showErrorMessage(context, '기존 길찾기 시작 중 오류 발생');
      }
    } else {
      debugPrint('❌ MapController가 없습니다 (레거시)');
    }
  } else {
    debugPrint('❌ 레거시 네비게이션: 출발지 또는 도착지 정보가 누락됨');
    _showErrorMessage(context, '길찾기 시작을 위한 정보가 부족합니다');
  }
}

  /// 🔥 통합 네비게이션 컨트롤러에서 상태 업데이트
  void _updateStateFromController() {
    if (_unifiedController != null) {
      final state = _unifiedController!.state;
      _currentStep = state.currentStep;
      _currentInstruction = state.instruction;
      
      debugPrint('📍 네비게이션 상태 업데이트: $_currentStep - $_currentInstruction');
    }
  }

  /// 실제 네비게이션 시작 (기존 메서드 - 통합 API 지원으로 개선)
  void startActualNavigation(MapScreenController controller, BuildContext context) {
    try {
      debugPrint('🚀 실제 네비게이션 시작');
      
      if (_isUnifiedNavigation && _unifiedController != null) {
        // 통합 네비게이션은 이미 시작됨 - 다음 단계로 진행
        _unifiedController!.proceedToNextStep();
        _updateStateFromController();
        
        _showInfoMessage(context, '네비게이션이 진행됩니다');
      } else {
        // 레거시 네비게이션 - 기존 로직 유지
        _showInfoMessage(context, '길 안내를 시작합니다');
      }
      
    } catch (e) {
      debugPrint('❌ 실제 네비게이션 시작 오류: $e');
      _showErrorMessage(context, '네비게이션 시작 중 오류가 발생했습니다');
    }
  }

  /// 네비게이션 초기화
  void clearNavigation() {
    debugPrint('🗑️ NavigationStateManager 초기화');
    
    _showNavigationStatus = false;
    _estimatedDistance = '';
    _estimatedTime = '';
    _isUnifiedNavigation = false;
    _unifiedController = null;
    _currentStep = NavigationStep.completed;
    _currentInstruction = null;
  }

  /// 🔥 네비게이션 상태 업데이트 (외부에서 호출용)
  void updateNavigationState({
    NavigationStep? step,
    String? instruction,
    String? distance,
    String? time,
  }) {
    if (step != null) _currentStep = step;
    if (instruction != null) _currentInstruction = instruction;
    if (distance != null) _estimatedDistance = distance;
    if (time != null) _estimatedTime = time;
    
    debugPrint('📍 외부 상태 업데이트: $_currentStep - $_currentInstruction');
  }

  /// 🔥 네비게이션 단계 완료 처리
  void completeCurrentStep() {
    if (_unifiedController != null) {
      _unifiedController!.proceedToNextStep();
      _updateStateFromController();
    }
  }

  /// 🔥 특정 단계로 이동
  void moveToStep(NavigationStep step) {
    _currentStep = step;
    
    switch (step) {
      case NavigationStep.departureIndoor:
        _currentInstruction = '출발지 건물에서 출구까지 이동하세요';
        break;
      case NavigationStep.outdoor:
        _currentInstruction = '목적지 건물까지 이동하세요';
        break;
      case NavigationStep.arrivalIndoor:
        _currentInstruction = '목적지 건물에서 최종 목적지까지 이동하세요';
        break;
      case NavigationStep.completed:
        _currentInstruction = '목적지에 도착했습니다!';
        _showNavigationStatus = false;
        break;
    }
    
    debugPrint('📍 단계 이동: $step - $_currentInstruction');
  }

  /// MapController 가져오기 (Provider 등을 통해)
MapScreenController? _getMapController(BuildContext context) {
  try {
    debugPrint('🔍 MapController 검색 시작');

    try {
      final controller = Provider.of<MapScreenController>(context, listen: false);
      debugPrint('✅ Provider로 MapController 발견');
      return controller;
    } catch (e) {
      debugPrint('❌ Provider 접근 실패: $e');
    }

    // 👇 이 부분은 제거해도 좋습니다.
    // dependOnInheritedWidgetOfExactType은 Flutter Provider와 무관합니다.
    /*
    try {
      final inheritedController = context.dependOnInheritedWidgetOfExactType<SomeInheritedWidget>();
      if (inheritedController?.controller != null) {
        debugPrint('✅ InheritedWidget으로 MapController 발견');
        return inheritedController!.controller;
      }
    } catch (e) {
      debugPrint('❌ InheritedWidget 접근 실패: $e');
    }
    */

    debugPrint('❌ 모든 방법으로 MapController를 찾을 수 없음');
    return null;
  } catch (e) {
    debugPrint('❌ MapController 접근 중 예외 발생: $e');
    return null;
  }
}

  /// 성공 메시지 표시
  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 오류 메시지 표시
  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 정보 메시지 표시
  void _showInfoMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 🔥 네비게이션 진행률 계산
  double getNavigationProgress() {
    switch (_currentStep) {
      case NavigationStep.departureIndoor:
        return 0.25;
      case NavigationStep.outdoor:
        return 0.5;
      case NavigationStep.arrivalIndoor:
        return 0.75;
      case NavigationStep.completed:
        return 1.0;
    }
  }

  /// 🔥 현재 단계의 설명 가져오기
  String getCurrentStepDescription() {
    switch (_currentStep) {
      case NavigationStep.departureIndoor:
        return '출발지 실내 안내';
      case NavigationStep.outdoor:
        return '실외 경로 안내';
      case NavigationStep.arrivalIndoor:
        return '도착지 실내 안내';
      case NavigationStep.completed:
        return '네비게이션 완료';
    }
  }

  /// 🔥 네비게이션 타입 확인
  bool get isDepartureIndoorStep => _currentStep == NavigationStep.departureIndoor;
  bool get isOutdoorStep => _currentStep == NavigationStep.outdoor;
  bool get isArrivalIndoorStep => _currentStep == NavigationStep.arrivalIndoor;
  bool get isCompleted => _currentStep == NavigationStep.completed;

  /// 리소스 정리
  void dispose() {
    clearNavigation();
    _unifiedController?.dispose();
    debugPrint('🗑️ NavigationStateManager 리소스 정리 완료');
  }
}