// lib/managers/location_manager.dart - iOS 메인 스레드 블로킹 완전 해결

import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';

class LocationManager extends ChangeNotifier {
  loc.LocationData? currentLocation;
  loc.PermissionStatus? permissionStatus;
  final loc.Location _location = loc.Location();
  
  bool _isInitialized = false;
  bool _isLocationServiceEnabled = false;
  bool _isRequestingLocation = false;
  bool _hasLocationPermissionError = false;

  void Function(loc.LocationData)? onLocationFound;
  
  // 간단한 타임아웃 관리
  Timer? _requestTimer;
  
  // 권한 상태 주기적 확인용 타이머
  Timer? _permissionCheckTimer;

  // 위치 스트림 구독
  StreamSubscription<loc.LocationData>? _locationStreamSubscription;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  bool get isRequestingLocation => _isRequestingLocation;
  bool get hasValidLocation => currentLocation?.latitude != null && currentLocation?.longitude != null;
  bool get hasLocationPermissionError => _hasLocationPermissionError;

  LocationManager() {
    _initializeQuickly();
  }

  /// 빠른 초기화 - 즉시 실행
  Future<void> _initializeQuickly() async {
    try {
      debugPrint('🚀 LocationManager 빠른 초기화 시작...');
      
      // 위치 서비스 설정
      await _location.changeSettings(
        accuracy: loc.LocationAccuracy.balanced, // high는 너무 정확해서 시간이 오래 걸림
        interval: 5000, // 5초
        distanceFilter: 10, // 10m
      );
      
      _isInitialized = true;
      notifyListeners();
      
      // 백그라운드에서 권한 상태 확인
      _checkPermissionInBackground();
      
      debugPrint('✅ LocationManager 빠른 초기화 완료');
      
    } catch (e) {
      debugPrint('❌ 초기화 오류: $e');
      _isInitialized = false;
      notifyListeners();
    }
  }

  /// 백그라운드에서 권한 상태 확인 (비동기)
  void _checkPermissionInBackground() {
    // 메인 스레드를 블로킹하지 않도록 microtask 사용
    Future.microtask(() async {
      try {
        await Future.delayed(const Duration(milliseconds: 50));
        
        final status = await _location.hasPermission();
        final serviceEnabled = await _location.serviceEnabled();
        
        debugPrint('📍 권한 상태: $status');
        debugPrint('📍 서비스 상태: $serviceEnabled');
        
        // 메인 스레드에서 상태 업데이트
        if (mounted) {
          final previousStatus = permissionStatus;
          permissionStatus = status;
          _isLocationServiceEnabled = serviceEnabled;
          
          // 권한 상태가 변경되었을 때 알림
          if (previousStatus != status) {
            debugPrint('📍 권한 상태 변경 감지: $previousStatus → $status');
          }
          
          notifyListeners();
        }
        
      } catch (e) {
        debugPrint('❌ 백그라운드 권한 확인 오류: $e');
      }
    });
  }

  /// 스트림 기반 위치 요청 (iOS 최적화)
  Future<void> requestLocation() async {
    if (_isRequestingLocation) {
      debugPrint('⏳ 이미 위치 요청 중...');
      return;
    }

    _isRequestingLocation = true;
    _hasLocationPermissionError = false;
    notifyListeners();

    try {
      debugPrint('📍 위치 요청 시작...');
      
      // 1. 캐시된 위치 확인
      if (_isLocationRecent()) {
        debugPrint('⚡ 캐시된 위치 사용');
        return;
      }

      // 2. 권한 확인
      final hasPermission = await _ensureLocationPermissionStreamBased();
      if (!hasPermission) {
        _hasLocationPermissionError = true;
        return;
      }

      // 3. 스트림 기반 위치 요청
      await _requestLocationViaStream();

    } catch (e) {
      debugPrint('❌ 위치 요청 실패: $e');
      _hasLocationPermissionError = true;
    } finally {
      _isRequestingLocation = false;
      _requestTimer?.cancel();
      _requestTimer = null;
      notifyListeners();
    }
  }

  /// 스트림 기반 권한 확인
  Future<bool> _ensureLocationPermissionStreamBased() async {
    try {
      debugPrint('🔍 스트림 기반 권한 확인 시작...');
      
      // 현재 권한 상태 확인
      final currentStatus = await _location.hasPermission();
      permissionStatus = currentStatus;
      
      debugPrint('🔍 현재 권한 상태: $currentStatus');
      
      if (currentStatus == loc.PermissionStatus.granted) {
        // 서비스 상태 확인
        final serviceEnabled = await _location.serviceEnabled();
        _isLocationServiceEnabled = serviceEnabled;
        
        if (!serviceEnabled) {
          debugPrint('🔧 위치 서비스 요청...');
          try {
            final serviceRequested = await _location.requestService();
            _isLocationServiceEnabled = serviceRequested;
            return serviceRequested;
          } catch (e) {
            debugPrint('❌ 위치 서비스 요청 실패: $e');
            return false;
          }
        }
        
        return true;
      }

      // 권한 요청
      if (currentStatus == loc.PermissionStatus.denied || currentStatus == null) {
        debugPrint('🔐 권한 요청 중...');
        
        final requestedStatus = await _location.requestPermission();
        permissionStatus = requestedStatus;
        
        if (requestedStatus == loc.PermissionStatus.granted) {
          final serviceEnabled = await _location.serviceEnabled();
          if (!serviceEnabled) {
            final serviceRequested = await _location.requestService();
            _isLocationServiceEnabled = serviceRequested;
            return serviceRequested;
          }
          _isLocationServiceEnabled = true;
          return true;
        }
        
        return false;
      }

      return currentStatus == loc.PermissionStatus.granted;
      
    } catch (e) {
      debugPrint('❌ 권한 확인 실패: $e');
      return false;
    }
  }

  /// 스트림 기반 위치 요청 (iOS 최적화)
  Future<void> _requestLocationViaStream() async {
    debugPrint('📍 스트림 기반 위치 요청 시작...');
    
    // 타임아웃 설정
    _requestTimer = Timer(const Duration(seconds: 10), () {
      debugPrint('⏰ 스트림 위치 요청 타임아웃');
      _locationStreamSubscription?.cancel();
      _locationStreamSubscription = null;
    });

    try {
      // 기존 스트림 정리
      await _locationStreamSubscription?.cancel();
      _locationStreamSubscription = null;
      
      // 새로운 스트림 구독
      _locationStreamSubscription = _location.onLocationChanged.listen(
        (loc.LocationData locationData) {
          debugPrint('📍 스트림에서 위치 수신: ${locationData.latitude}, ${locationData.longitude}');
          
          if (locationData.latitude != null && locationData.longitude != null) {
            // 위치 업데이트
            currentLocation = locationData;
            _hasLocationPermissionError = false;
            
            debugPrint('✅ 스트림 위치 획득 성공: ${locationData.latitude}, ${locationData.longitude}');
            debugPrint('📊 정확도: ${locationData.accuracy?.toStringAsFixed(1)}m');
            
            // 콜백 호출
            onLocationFound?.call(locationData);
            
            // 스트림 정리
            _locationStreamSubscription?.cancel();
            _locationStreamSubscription = null;
            _requestTimer?.cancel();
            _requestTimer = null;
            
            if (mounted) {
              notifyListeners();
            }
          }
        },
        onError: (error) {
          debugPrint('❌ 스트림 위치 오류: $error');
          _hasLocationPermissionError = true;
          
          // 스트림 정리
          _locationStreamSubscription?.cancel();
          _locationStreamSubscription = null;
          _requestTimer?.cancel();
          _requestTimer = null;
          
          if (mounted) {
            notifyListeners();
          }
        },
      );
      
      // 스트림 시작 후 잠시 대기
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      debugPrint('❌ 스트림 위치 요청 실패: $e');
      _hasLocationPermissionError = true;
      
      // 스트림 정리
      _locationStreamSubscription?.cancel();
      _locationStreamSubscription = null;
    }
  }

  /// 단발성 위치 요청 (fallback)
  Future<void> _requestSingleLocation() async {
    debugPrint('📍 단발성 위치 요청 시작...');
    
    try {
      // 타임아웃을 짧게 설정
      final locationData = await _location.getLocation().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('⏰ 단발성 위치 요청 타임아웃');
          throw TimeoutException('위치 획득 타임아웃', const Duration(seconds: 8));
        },
      );

      if (locationData.latitude != null && locationData.longitude != null) {
        currentLocation = locationData;
        _hasLocationPermissionError = false;
        
        debugPrint('✅ 단발성 위치 획득 성공: ${locationData.latitude}, ${locationData.longitude}');
        
        // 콜백 호출
        onLocationFound?.call(locationData);
        
        return;
      }

      debugPrint('⚠️ 유효하지 않은 위치 데이터');
      _hasLocationPermissionError = true;
      
    } catch (e) {
      debugPrint('❌ 단발성 위치 획득 실패: $e');
      _hasLocationPermissionError = true;
    }
  }

  /// 권한 상태 재확인
  Future<void> recheckPermissionStatus() async {
    _checkPermissionInBackground();
  }

  /// 위치 새로고침
  Future<void> refreshLocation() async {
    debugPrint('🔄 위치 새로고침...');
    
    // 권한 상태 다시 확인
    _checkPermissionInBackground();
    
    // 기존 위치 무효화
    currentLocation = null;
    
    // 새로운 위치 요청
    await requestLocation();
  }

  /// 현재 위치가 최근 것인지 확인
  bool _isLocationRecent() {
    if (currentLocation?.time == null) return false;
    
    final locationTime = DateTime.fromMillisecondsSinceEpoch(
      currentLocation!.time!.toInt()
    );
    final now = DateTime.now();
    final difference = now.difference(locationTime);
    
    return difference.inSeconds < 30; // 30초
  }

  /// 앱 라이프사이클 변경 처리
  void handleAppLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 앱 복귀 - 권한 재확인');
      _checkPermissionInBackground();
    }
  }

  /// 실시간 위치 추적
  StreamSubscription<loc.LocationData>? _trackingSubscription;
  
  void startLocationTracking({Function(loc.LocationData)? onLocationChanged}) {
    if (permissionStatus != loc.PermissionStatus.granted) {
      debugPrint('❌ 위치 추적 불가: 권한 없음');
      return;
    }
    
    debugPrint('🔄 실시간 위치 추적 시작...');
    
    // 기존 추적 중지
    _trackingSubscription?.cancel();
    
    _trackingSubscription = _location.onLocationChanged.listen(
      (loc.LocationData locationData) {
        if (locationData.latitude != null && locationData.longitude != null) {
          
          currentLocation = locationData;
          _hasLocationPermissionError = false;
          
          if (mounted) {
            notifyListeners();
          }
          
          onLocationChanged?.call(locationData);
          
          debugPrint('📍 위치 업데이트: ${locationData.latitude}, ${locationData.longitude}');
        }
      },
      onError: (error) {
        debugPrint('❌ 위치 추적 오류: $error');
        _hasLocationPermissionError = true;
        if (mounted) {
          notifyListeners();
        }
      },
    );
  }

  /// 위치 추적 중지
  void stopLocationTracking() {
    debugPrint('⏹️ 위치 추적 중지');
    _trackingSubscription?.cancel();
    _trackingSubscription = null;
  }

  /// 위치 초기화
  void clearLocation() {
    currentLocation = null;
    _hasLocationPermissionError = false;
    notifyListeners();
  }

  /// mounted 상태 확인
  bool get mounted => hasListeners;

  @override
  void dispose() {
    _requestTimer?.cancel();
    _permissionCheckTimer?.cancel();
    _locationStreamSubscription?.cancel();
    _trackingSubscription?.cancel();
    super.dispose();
  }
}