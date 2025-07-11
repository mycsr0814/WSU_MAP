// lib/services/location_service.dart
// 핵심 위치 획득 서비스 - 단순하고 안정적

import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'dart:async';

/// 위치 획득 결과
class LocationResult {
  final loc.LocationData? locationData;
  final LocationError? error;
  final bool isFromCache;
  
  const LocationResult({
    this.locationData,
    this.error,
    this.isFromCache = false,
  });
  
  bool get isSuccess => locationData != null && error == null;
  bool get hasValidLocation => locationData?.latitude != null && locationData?.longitude != null;
}

/// 위치 관련 에러
enum LocationError {
  permissionDenied,
  serviceDisabled,
  timeout,
  unknown,
  noLocationFound,
}

/// 핵심 위치 서비스 - 위치 획득만 담당
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final loc.Location _location = loc.Location();
  loc.LocationData? _cachedLocation;
  DateTime? _cacheTime;
  
  // 위치 요청 상태
  bool _isRequesting = false;
  Timer? _requestTimer;
  
  // 캐시 유효 시간 (기본 30초)
  static const Duration _cacheValidDuration = Duration(seconds: 30);
  
  /// 위치 서비스 초기화
  Future<void> initialize() async {
    try {
      debugPrint('🚀 LocationService 초기화...');
      
      // 위치 서비스 설정
      await _location.changeSettings(
        accuracy: loc.LocationAccuracy.balanced,
        interval: 5000, // 5초
        distanceFilter: 10, // 10m
      );
      
      debugPrint('✅ LocationService 초기화 완료');
    } catch (e) {
      debugPrint('❌ LocationService 초기화 실패: $e');
      rethrow;
    }
  }

  /// 현재 위치 획득 (메인 메서드)
  Future<LocationResult> getCurrentLocation({
    bool forceRefresh = false,
    Duration? timeout,
  }) async {
    debugPrint('📍 위치 획득 요청 - forceRefresh: $forceRefresh');
    
    // 중복 요청 방지
    if (_isRequesting) {
      debugPrint('⏳ 이미 위치 요청 중...');
      await _waitForCurrentRequest();
      return LocationResult(locationData: _cachedLocation);
    }
    
    // 캐시된 위치 확인
    if (!forceRefresh && _isCacheValid()) {
      debugPrint('⚡ 캐시된 위치 사용');
      return LocationResult(
        locationData: _cachedLocation,
        isFromCache: true,
      );
    }
    
    return await _requestLocationWithRetry(timeout: timeout);
  }

  /// 재시도가 포함된 위치 요청
  Future<LocationResult> _requestLocationWithRetry({
    Duration? timeout,
    int maxRetries = 3,
  }) async {
    _isRequesting = true;
    
    try {
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        debugPrint('🔄 위치 요청 시도 $attempt/$maxRetries');
        
        final timeoutDuration = timeout ?? Duration(seconds: attempt == 1 ? 8 : 12);
        
        try {
          final locationData = await _location.getLocation().timeout(
            timeoutDuration,
            onTimeout: () {
              debugPrint('⏰ 위치 요청 타임아웃 (시도 $attempt)');
              throw TimeoutException('위치 획득 타임아웃', timeoutDuration);
            },
          );

          if (_isLocationDataValid(locationData)) {
            _updateCache(locationData);
            debugPrint('✅ 위치 획득 성공 (시도 $attempt): ${locationData.latitude}, ${locationData.longitude}');
            debugPrint('📊 정확도: ${locationData.accuracy?.toStringAsFixed(1)}m');
            
            return LocationResult(locationData: locationData);
          }
          
          debugPrint('⚠️ 유효하지 않은 위치 데이터 (시도 $attempt)');
          
        } catch (e) {
          debugPrint('❌ 위치 요청 시도 $attempt 실패: $e');
          
          if (attempt < maxRetries) {
            // 재시도 전 잠시 대기
            await Future.delayed(Duration(seconds: attempt));
            continue;
          }
          
          // 마지막 시도에서 실패
          return LocationResult(error: _mapExceptionToError(e));
        }
      }
      
      return const LocationResult(error: LocationError.noLocationFound);
      
    } finally {
      _isRequesting = false;
      _requestTimer?.cancel();
      _requestTimer = null;
    }
  }

  /// 기본 위치 제공 (우송대학교)
  LocationResult getFallbackLocation() {
    debugPrint('🏫 기본 위치 제공: 우송대학교');
    
    final fallbackLocation = loc.LocationData.fromMap({
      'latitude': 36.3370,
      'longitude': 127.4450,
      'accuracy': 50.0,
      'altitude': 0.0,
      'speed': 0.0,
      'speedAccuracy': 0.0,
      'heading': 0.0,
      'time': DateTime.now().millisecondsSinceEpoch.toDouble(),
      'isMock': false,
    });
    
    _updateCache(fallbackLocation);
    
    return LocationResult(locationData: fallbackLocation);
  }

  /// 위치 데이터 유효성 검증
  bool _isLocationDataValid(loc.LocationData? data) {
    if (data == null) return false;
    if (data.latitude == null || data.longitude == null) return false;
    
    // 위도/경도 범위 검증
    final lat = data.latitude!;
    final lng = data.longitude!;
    
    if (lat < -90 || lat > 90) return false;
    if (lng < -180 || lng > 180) return false;
    
    return true;
  }

  /// 캐시 유효성 확인
  bool _isCacheValid() {
    if (_cachedLocation == null || _cacheTime == null) return false;
    
    final now = DateTime.now();
    final timeDiff = now.difference(_cacheTime!);
    
    return timeDiff <= _cacheValidDuration;
  }

  /// 캐시 업데이트
  void _updateCache(loc.LocationData locationData) {
    _cachedLocation = locationData;
    _cacheTime = DateTime.now();
  }

  /// 현재 요청 완료까지 대기
  Future<void> _waitForCurrentRequest() async {
    int waitCount = 0;
    const maxWait = 50; // 최대 5초 대기
    
    while (_isRequesting && waitCount < maxWait) {
      await Future.delayed(const Duration(milliseconds: 100));
      waitCount++;
    }
  }

  /// 예외를 LocationError로 변환
  LocationError _mapExceptionToError(dynamic exception) {
    if (exception is TimeoutException) {
      return LocationError.timeout;
    }
    
    final errorString = exception.toString().toLowerCase();
    
    if (errorString.contains('permission')) {
      return LocationError.permissionDenied;
    }
    
    if (errorString.contains('service') || errorString.contains('disabled')) {
      return LocationError.serviceDisabled;
    }
    
    return LocationError.unknown;
  }

  /// 캐시된 위치 반환 (있는 경우)
  loc.LocationData? get cachedLocation => _cachedLocation;
  
  /// 캐시 유효 여부
  bool get hasCachedLocation => _isCacheValid();
  
  /// 현재 요청 중 여부
  bool get isRequesting => _isRequesting;

  /// 캐시 무효화
  void invalidateCache() {
    debugPrint('🗑️ 위치 캐시 무효화');
    _cachedLocation = null;
    _cacheTime = null;
  }

  /// 서비스 정리
  void dispose() {
    _requestTimer?.cancel();
    _requestTimer = null;
    _isRequesting = false;
    debugPrint('🧹 LocationService 정리 완료');
  }
}