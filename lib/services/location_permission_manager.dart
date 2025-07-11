// lib/services/location/location_permission_manager.dart
// 위치 권한 관리 전용 서비스

import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'dart:async';
import 'dart:io';

/// 권한 상태
enum PermissionResult {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  unknown,
}

/// 권한 관리 전용 서비스
class LocationPermissionManager {
  static final LocationPermissionManager _instance = LocationPermissionManager._internal();
  factory LocationPermissionManager() => _instance;
  LocationPermissionManager._internal();

  final loc.Location _location = loc.Location();
  
  // 권한 상태 캐시
  loc.PermissionStatus? _lastPermissionStatus;
  bool? _lastServiceStatus;
  DateTime? _lastCheckTime;
  
  // 권한 상태 변경 리스너
  final List<Function(PermissionResult)> _listeners = [];
  
  // 상태 확인 주기 (1분)
  static const Duration _checkInterval = Duration(minutes: 1);
  Timer? _periodicCheckTimer;
  
  /// 권한 상태 변경 리스너 추가
  void addPermissionListener(Function(PermissionResult) listener) {
    _listeners.add(listener);
  }
  
  /// 권한 상태 변경 리스너 제거
  void removePermissionListener(Function(PermissionResult) listener) {
    _listeners.remove(listener);
  }
  
  /// 모든 리스너에게 권한 상태 변경 알림
  void _notifyListeners(PermissionResult result) {
    for (final listener in _listeners) {
      try {
        listener(result);
      } catch (e) {
        debugPrint('❌ 권한 리스너 호출 오류: $e');
      }
    }
  }

  /// 현재 권한 상태 확인 (캐시 포함)
  Future<PermissionResult> checkPermissionStatus({bool forceRefresh = false}) async {
    debugPrint('🔍 권한 상태 확인 - forceRefresh: $forceRefresh');
    
    // 캐시된 결과 사용 (5분 이내)
    if (!forceRefresh && _isCacheValid()) {
      final cachedResult = _getCachedResult();
      if (cachedResult != null) {
        debugPrint('⚡ 캐시된 권한 상태: $cachedResult');
        return cachedResult;
      }
    }
    
    return await _checkPermissionStatusFresh();
  }

  /// 실제 권한 상태 확인
  Future<PermissionResult> _checkPermissionStatusFresh() async {
    try {
      debugPrint('🔍 실제 권한 상태 확인 시작...');
      
      // 플랫폼별 최적화된 지연
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      // 권한 상태 확인 (타임아웃 적용)
      final permissionStatus = await _location.hasPermission().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏰ 권한 상태 확인 타임아웃');
          return loc.PermissionStatus.denied;
        },
      );
      
      // 서비스 상태 확인 (권한이 있는 경우에만)
      bool serviceEnabled = false;
      if (permissionStatus == loc.PermissionStatus.granted) {
        serviceEnabled = await _location.serviceEnabled().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint('⏰ 서비스 상태 확인 타임아웃');
            return false;
          },
        );
      }
      
      // 캐시 업데이트
      _lastPermissionStatus = permissionStatus;
      _lastServiceStatus = serviceEnabled;
      _lastCheckTime = DateTime.now();
      
      final result = _mapToPermissionResult(permissionStatus, serviceEnabled);
      
      debugPrint('✅ 권한 상태 확인 완료: $result');
      debugPrint('   권한: $permissionStatus, 서비스: $serviceEnabled');
      
      return result;
      
    } catch (e) {
      debugPrint('❌ 권한 상태 확인 실패: $e');
      return PermissionResult.unknown;
    }
  }

  /// 권한 요청
  Future<PermissionResult> requestPermission() async {
    try {
      debugPrint('🔐 위치 권한 요청 시작...');
      
      // 현재 상태 먼저 확인
      final currentStatus = await checkPermissionStatus(forceRefresh: true);
      
      // 이미 권한이 있고 서비스도 활성화된 경우
      if (currentStatus == PermissionResult.granted) {
        debugPrint('✅ 이미 권한이 부여됨');
        return PermissionResult.granted;
      }
      
      // 영구 거부된 경우
      if (currentStatus == PermissionResult.deniedForever) {
        debugPrint('❌ 권한이 영구 거부됨');
        return PermissionResult.deniedForever;
      }
      
      // 플랫폼별 최적화된 지연
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      // 권한 요청
      final requestedStatus = await _location.requestPermission().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⏰ 권한 요청 타임아웃');
          return loc.PermissionStatus.denied;
        },
      );
      
      debugPrint('📋 권한 요청 결과: $requestedStatus');
      
      // 권한이 승인된 경우 서비스 상태도 확인
      bool serviceEnabled = false;
      if (requestedStatus == loc.PermissionStatus.granted) {
        serviceEnabled = await _ensureLocationServiceEnabled();
      }
      
      // 캐시 업데이트
      _lastPermissionStatus = requestedStatus;
      _lastServiceStatus = serviceEnabled;
      _lastCheckTime = DateTime.now();
      
      final result = _mapToPermissionResult(requestedStatus, serviceEnabled);
      
      // 리스너들에게 알림
      _notifyListeners(result);
      
      debugPrint('✅ 권한 요청 완료: $result');
      return result;
      
    } catch (e) {
      debugPrint('❌ 권한 요청 실패: $e');
      return PermissionResult.unknown;
    }
  }

  /// 위치 서비스 활성화 확인
  Future<bool> _ensureLocationServiceEnabled() async {
    try {
      debugPrint('🔧 위치 서비스 상태 확인...');
      
      final isEnabled = await _location.serviceEnabled().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
      
      if (isEnabled) {
        debugPrint('✅ 위치 서비스 이미 활성화됨');
        return true;
      }
      
      debugPrint('🔧 위치 서비스 활성화 요청...');
      
      final serviceRequested = await _location.requestService().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏰ 위치 서비스 요청 타임아웃');
          return false;
        },
      );
      
      debugPrint('📋 위치 서비스 요청 결과: $serviceRequested');
      return serviceRequested;
      
    } catch (e) {
      debugPrint('❌ 위치 서비스 확인/요청 실패: $e');
      return false;
    }
  }

  /// 앱 설정 화면으로 이동 (권한이 영구 거부된 경우)
  Future<void> openAppSettings() async {
    try {
      debugPrint('⚙️ 앱 설정 화면 열기...');
      // location 패키지의 앱 설정 기능은 제한적이므로
      // 필요에 따라 permission_handler 패키지 사용 고려
      debugPrint('ℹ️ 사용자가 수동으로 설정에서 권한을 허용해야 합니다');
    } catch (e) {
      debugPrint('❌ 앱 설정 열기 실패: $e');
    }
  }

  /// 권한 상태를 PermissionResult로 변환
  PermissionResult _mapToPermissionResult(loc.PermissionStatus status, bool serviceEnabled) {
    switch (status) {
      case loc.PermissionStatus.granted:
        return serviceEnabled ? PermissionResult.granted : PermissionResult.serviceDisabled;
      case loc.PermissionStatus.denied:
        return PermissionResult.denied;
      case loc.PermissionStatus.deniedForever:
        return PermissionResult.deniedForever;
      default:
        return PermissionResult.unknown;
    }
  }

  /// 캐시 유효성 확인
  bool _isCacheValid() {
    if (_lastCheckTime == null) return false;
    
    final now = DateTime.now();
    final timeDiff = now.difference(_lastCheckTime!);
    
    return timeDiff <= const Duration(minutes: 5);
  }

  /// 캐시된 결과 반환
  PermissionResult? _getCachedResult() {
    if (_lastPermissionStatus == null) return null;
    
    return _mapToPermissionResult(_lastPermissionStatus!, _lastServiceStatus ?? false);
  }

  /// 주기적 권한 상태 확인 시작
  void startPeriodicCheck() {
    debugPrint('🔄 주기적 권한 상태 확인 시작');
    
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(_checkInterval, (timer) async {
      try {
        final result = await checkPermissionStatus(forceRefresh: true);
        debugPrint('🔍 주기적 권한 확인 결과: $result');
      } catch (e) {
        debugPrint('❌ 주기적 권한 확인 실패: $e');
      }
    });
  }

  /// 주기적 권한 상태 확인 중지
  void stopPeriodicCheck() {
    debugPrint('⏹️ 주기적 권한 상태 확인 중지');
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
  }

  /// 앱 라이프사이클 변경 처리
  void handleAppLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 앱 복귀 - 권한 상태 재확인');
      // 앱이 포그라운드로 돌아오면 권한 상태 재확인
      Future.delayed(const Duration(milliseconds: 500), () {
        checkPermissionStatus(forceRefresh: true);
      });
    }
  }

  /// 권한 상태 캐시 무효화
  void invalidateCache() {
    debugPrint('🗑️ 권한 상태 캐시 무효화');
    _lastPermissionStatus = null;
    _lastServiceStatus = null;
    _lastCheckTime = null;
  }

  /// 현재 캐시된 권한 상태
  PermissionResult? get cachedPermissionResult => _getCachedResult();
  
  /// 마지막 권한 확인 시간
  DateTime? get lastCheckTime => _lastCheckTime;

  /// 서비스 정리
  void dispose() {
    debugPrint('🧹 LocationPermissionManager 정리');
    stopPeriodicCheck();
    _listeners.clear();
    invalidateCache();
  }
}