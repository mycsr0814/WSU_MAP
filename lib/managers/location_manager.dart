// lib/managers/location_manager.dart - 단순하고 확실한 버전

import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'dart:async';
import 'dart:io';

class LocationManager extends ChangeNotifier {
  loc.LocationData? currentLocation;
  loc.PermissionStatus? permissionStatus;
  final loc.Location _location = loc.Location();
  
  bool _isInitialized = false;
  bool _isLocationServiceEnabled = false;
  bool _isRequestingLocation = false;
  bool _hasLocationPermissionError = false;

  void Function(loc.LocationData)? onLocationFound;
  
  // 🔥 단순화: 최소한의 타이머만 사용
  Timer? _requestTimer;
  StreamSubscription<loc.LocationData>? _trackingSubscription;

  // 캐시 관리
  DateTime? _lastLocationTime;
  static const Duration _cacheValidDuration = Duration(seconds: 30);

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  bool get isRequestingLocation => _isRequestingLocation;
  bool get hasValidLocation => currentLocation?.latitude != null && currentLocation?.longitude != null;
  bool get hasLocationPermissionError => _hasLocationPermissionError;

  LocationManager() {
    _initializeSimple();
  }

  /// 🔥 매우 단순한 초기화
  Future<void> _initializeSimple() async {
    debugPrint('🚀 LocationManager 단순 초기화...');
    
    try {
      // 🔥 iOS에서는 설정 변경을 최소화
      if (Platform.isIOS) {
        // iOS는 기본 설정 사용
        _isInitialized = true;
      } else {
        // Android만 설정 변경
        await _location.changeSettings(
          accuracy: loc.LocationAccuracy.balanced,
          interval: 5000,
          distanceFilter: 10,
        );
        _isInitialized = true;
      }
      
      notifyListeners();
      debugPrint('✅ LocationManager 단순 초기화 완료');
      
    } catch (e) {
      debugPrint('❌ 초기화 오류: $e');
      _isInitialized = true; // 오류가 있어도 계속 진행
      notifyListeners();
    }
  }

  /// 🔥 조용한 권한 확인 (팝업 없음)
  Future<bool> checkPermissionQuietly() async {
    try {
      debugPrint('🔍 조용한 권한 확인...');
      
      // 🔥 iOS에서는 더 간단하게
      final status = await _location.hasPermission().timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          debugPrint('⏰ 권한 확인 타임아웃');
          return loc.PermissionStatus.denied;
        },
      );

      debugPrint('📋 권한 상태: $status');

      if (status == loc.PermissionStatus.granted) {
        // 서비스 상태는 빠르게 확인
        try {
          final serviceEnabled = await _location.serviceEnabled().timeout(
            const Duration(milliseconds: 500),
            onTimeout: () => true, // 타임아웃 시 true로 가정
          );
          debugPrint('📋 서비스 상태: $serviceEnabled');
          return serviceEnabled;
        } catch (e) {
          debugPrint('⚠️ 서비스 확인 실패, true로 가정: $e');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ 조용한 권한 확인 실패: $e');
      return false;
    }
  }

  /// 🔥 실제 GPS 위치인지 확인
  bool isActualGPSLocation(loc.LocationData locationData) {
    const fallbackLat = 36.3370;
    const fallbackLng = 127.4450;
    
    if (locationData.latitude == null || locationData.longitude == null) {
      return false;
    }
    
    final lat = locationData.latitude!;
    final lng = locationData.longitude!;
    
    // fallback 위치와 정확히 같으면 실제 위치가 아님
    if ((lat - fallbackLat).abs() < 0.0001 && (lng - fallbackLng).abs() < 0.0001) {
      return false;
    }
    
    return true;
  }

  /// 🔥 매우 단순한 위치 요청
  Future<void> requestLocation() async {
    if (_isRequestingLocation) {
      debugPrint('⏳ 이미 위치 요청 중...');
      return;
    }

    debugPrint('📍 단순 위치 요청 시작...');
    
    _isRequestingLocation = true;
    _hasLocationPermissionError = false;
    notifyListeners();

    try {
      // 1. 캐시 확인
      if (_isCacheValid()) {
        debugPrint('⚡ 캐시된 위치 사용');
        if (isActualGPSLocation(currentLocation!)) {
          _scheduleLocationCallback(currentLocation!);
          return;
        } else {
          debugPrint('🗑️ 캐시된 위치가 fallback, 새로 요청');
        }
      }

      // 2. 🔥 권한 확인 (간단하게)
      debugPrint('🔍 권한 확인 중...');
      final hasPermission = await _simplePermissionCheck();
      if (!hasPermission) {
        debugPrint('❌ 위치 권한 없음');
        _hasLocationPermissionError = true;
        return;
      }

      // 3. 🔥 실제 위치 요청 (단순하게)
      debugPrint('📍 실제 위치 요청...');
      await _simpleLocationRequest();

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

  /// 🔥 단순한 권한 확인
  Future<bool> _simplePermissionCheck() async {
    try {
      // 현재 권한 확인
      final status = await _location.hasPermission().timeout(
        const Duration(seconds: 2),
        onTimeout: () => loc.PermissionStatus.denied,
      );

      if (status == loc.PermissionStatus.granted) {
        // 서비스 확인
        final serviceEnabled = await _location.serviceEnabled().timeout(
          const Duration(seconds: 1),
          onTimeout: () => true,
        );

        if (!serviceEnabled) {
          debugPrint('🔧 위치 서비스 요청...');
          try {
            await _location.requestService().timeout(
              const Duration(seconds: 3),
              onTimeout: () => false,
            );
          } catch (e) {
            debugPrint('⚠️ 서비스 요청 실패: $e');
          }
        }

        return true;
      }

      // 권한 요청
      if (status == loc.PermissionStatus.denied) {
        debugPrint('🔐 권한 요청...');
        
        final requestedStatus = await _location.requestPermission().timeout(
          const Duration(seconds: 8),
          onTimeout: () => loc.PermissionStatus.denied,
        );

        if (requestedStatus == loc.PermissionStatus.granted) {
          // 서비스도 요청
          try {
            await _location.requestService().timeout(
              const Duration(seconds: 3),
              onTimeout: () => false,
            );
          } catch (e) {
            debugPrint('⚠️ 서비스 요청 실패: $e');
          }
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ 권한 확인 실패: $e');
      return false;
    }
  }

  /// 🔥 단순한 위치 요청
  Future<void> _simpleLocationRequest() async {
    try {
      debugPrint('🎯 GPS 위치 획득 시도...');
      
      // 🔥 더 긴 타임아웃으로 실제 위치 기다리기
      final locationData = await _location.getLocation().timeout(
        const Duration(seconds: 10), // iOS는 시간이 더 걸릴 수 있음
        onTimeout: () {
          debugPrint('⏰ 위치 획득 타임아웃');
          throw TimeoutException('위치 획득 타임아웃', const Duration(seconds: 10));
        },
      );

      debugPrint('📍 위치 데이터 수신: ${locationData.latitude}, ${locationData.longitude}');
      debugPrint('📊 정확도: ${locationData.accuracy}m');

      if (_isLocationDataValid(locationData)) {
        // 🔥 실제 GPS 위치인지 확인
        if (isActualGPSLocation(locationData)) {
          currentLocation = locationData;
          _lastLocationTime = DateTime.now();
          _hasLocationPermissionError = false;
          
          debugPrint('✅ 실제 GPS 위치 획득 성공!');
          _scheduleLocationCallback(locationData);
        } else {
          debugPrint('⚠️ Fallback 위치 감지됨, 실제 위치 재시도...');
          
          // 🔥 한 번 더 시도
          await Future.delayed(const Duration(seconds: 2));
          await _retryLocationRequest();
        }
      } else {
        debugPrint('⚠️ 유효하지 않은 위치 데이터');
        _hasLocationPermissionError = true;
      }
      
    } catch (e) {
      debugPrint('❌ 위치 요청 실패: $e');
      _hasLocationPermissionError = true;
    }
  }

  /// 🔥 위치 재시도 (한 번만)
  Future<void> _retryLocationRequest() async {
    try {
      debugPrint('🔄 위치 재시도...');
      
      final locationData = await _location.getLocation().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏰ 재시도 타임아웃');
          throw TimeoutException('재시도 타임아웃', const Duration(seconds: 5));
        },
      );

      if (_isLocationDataValid(locationData) && isActualGPSLocation(locationData)) {
        currentLocation = locationData;
        _lastLocationTime = DateTime.now();
        _hasLocationPermissionError = false;
        
        debugPrint('✅ 재시도로 실제 GPS 위치 획득!');
        _scheduleLocationCallback(locationData);
      } else {
        debugPrint('❌ 재시도에도 실제 위치 못 받음');
        _hasLocationPermissionError = true;
      }
      
    } catch (e) {
      debugPrint('❌ 위치 재시도 실패: $e');
      _hasLocationPermissionError = true;
    }
  }

  /// 위치 데이터 유효성 검증
  bool _isLocationDataValid(loc.LocationData? data) {
    if (data == null) return false;
    if (data.latitude == null || data.longitude == null) return false;
    
    final lat = data.latitude!;
    final lng = data.longitude!;
    
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    
    return true;
  }

  /// 캐시 유효성 확인
  bool _isCacheValid() {
    if (currentLocation == null || _lastLocationTime == null) return false;
    
    final now = DateTime.now();
    final timeDiff = now.difference(_lastLocationTime!);
    
    return timeDiff <= _cacheValidDuration;
  }

  /// 즉시 콜백 호출
  void _scheduleLocationCallback(loc.LocationData locationData) {
    try {
      onLocationFound?.call(locationData);
      debugPrint('✅ 위치 콜백 호출 완료');
    } catch (e) {
      debugPrint('❌ 위치 콜백 실행 오류: $e');
    }
  }

  /// 위치 새로고침
  Future<void> refreshLocation() async {
    debugPrint('🔄 위치 새로고침...');
    
    currentLocation = null;
    _lastLocationTime = null;
    _hasLocationPermissionError = false;
    
    await requestLocation();
  }

  /// 실시간 위치 추적
  void startLocationTracking({Function(loc.LocationData)? onLocationChanged}) {
    debugPrint('🔄 실시간 위치 추적 시작...');
    
    _trackingSubscription?.cancel();
    
    _trackingSubscription = _location.onLocationChanged.listen(
      (loc.LocationData locationData) {
        if (_isLocationDataValid(locationData) && isActualGPSLocation(locationData)) {
          currentLocation = locationData;
          _lastLocationTime = DateTime.now();
          _hasLocationPermissionError = false;
          
          if (mounted) {
            notifyListeners();
          }
          
          try {
            onLocationChanged?.call(locationData);
          } catch (e) {
            debugPrint('❌ 위치 추적 콜백 오류: $e');
          }
          
          debugPrint('📍 실제 위치 업데이트: ${locationData.latitude}, ${locationData.longitude}');
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
    _lastLocationTime = null;
    _hasLocationPermissionError = false;
    notifyListeners();
  }

  /// 앱 라이프사이클 변경 처리
  void handleAppLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 앱 복귀');
      Future.delayed(const Duration(seconds: 1), () {
        if (!_isCacheValid() && !_isRequestingLocation) {
          requestLocation();
        }
      });
    }
  }

  /// 권한 상태 재확인
  Future<void> recheckPermissionStatus() async {
    debugPrint('🔄 권한 상태 재확인...');
    // 단순하게 처리
  }

  /// mounted 상태 확인
  bool get mounted => hasListeners;

  @override
  void dispose() {
    _requestTimer?.cancel();
    _trackingSubscription?.cancel();
    super.dispose();
  }
}