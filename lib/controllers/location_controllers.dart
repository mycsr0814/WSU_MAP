// lib/controllers/location_controller.dart
// 위치 상태 관리 컨트롤러 - UI와 서비스 연결

import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/location_permission_manager.dart';
import 'package:flutter_application_1/services/location_service.dart';
import 'package:location/location.dart' as loc;
import 'dart:async';

/// 위치 상태
enum LocationState {
  initial,        // 초기 상태
  loading,        // 위치 요청 중
  success,        // 위치 획득 성공
  permissionDenied, // 권한 거부
  serviceDisabled,  // 서비스 비활성화
  error,          // 오류 발생
  fallback,       // 기본 위치 사용
}

/// 위치 관련 UI 상태 관리
class LocationController extends ChangeNotifier {
  final LocationService _locationService;
  final LocationPermissionManager _permissionManager;
  
  // 현재 상태
  LocationState _state = LocationState.initial;
  loc.LocationData? _currentLocation;
  String? _errorMessage;
  bool _isFromCache = false;
  
  // 위치 추적 관련
  StreamSubscription<loc.LocationData>? _trackingSubscription;
  bool _isTracking = false;
  
  // 콜백들
  Function(loc.LocationData)? _onLocationChanged;
  Function(LocationState)? _onStateChanged;

  LocationController({
    LocationService? locationService,
    LocationPermissionManager? permissionManager,
  }) : _locationService = locationService ?? LocationService(),
       _permissionManager = permissionManager ?? LocationPermissionManager() {
    
    _initialize();
  }

  // Getters
  LocationState get state => _state;
  loc.LocationData? get currentLocation => _currentLocation;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == LocationState.loading;
  bool get hasValidLocation => _currentLocation?.latitude != null && _currentLocation?.longitude != null;
  bool get hasLocationPermissionError => _state == LocationState.permissionDenied;
  bool get isFromCache => _isFromCache;
  bool get isTracking => _isTracking;

  /// 초기화
  Future<void> _initialize() async {
    try {
      debugPrint('🚀 LocationController 초기화...');
      
      // 서비스 초기화
      await _locationService.initialize();
      
      // 권한 상태 리스너 등록
      _permissionManager.addPermissionListener(_onPermissionChanged);
      
      debugPrint('✅ LocationController 초기화 완료');
    } catch (e) {
      debugPrint('❌ LocationController 초기화 실패: $e');
      _updateState(LocationState.error, errorMessage: e.toString());
    }
  }

  /// 권한 상태 변경 콜백
  void _onPermissionChanged(PermissionResult result) {
    debugPrint('📱 권한 상태 변경: $result');
    
    switch (result) {
      case PermissionResult.granted:
        if (_state == LocationState.permissionDenied || _state == LocationState.serviceDisabled) {
          // 권한이 복구되면 위치 재요청
          _requestLocationIfNeeded();
        }
        break;
      case PermissionResult.denied:
      case PermissionResult.deniedForever:
        _updateState(LocationState.permissionDenied);
        break;
      case PermissionResult.serviceDisabled:
        _updateState(LocationState.serviceDisabled);
        break;
      default:
        break;
    }
  }

  /// 현재 위치 요청 (메인 API)
  Future<void> requestCurrentLocation({
    bool forceRefresh = false,
    bool shouldMoveCamera = true,
  }) async {
    try {
      debugPrint('📍 현재 위치 요청 - forceRefresh: $forceRefresh');
      
      _updateState(LocationState.loading);
      
      // 1. 권한 확인 및 요청
      final permissionResult = await _ensurePermissions();
      if (permissionResult != PermissionResult.granted) {
        _handlePermissionError(permissionResult);
        return;
      }
      
      // 2. 위치 획득
      final locationResult = await _locationService.getCurrentLocation(
        forceRefresh: forceRefresh,
        timeout: const Duration(seconds: 15),
      );
      
      if (locationResult.isSuccess && locationResult.hasValidLocation) {
        // 성공
        _currentLocation = locationResult.locationData;
        _isFromCache = locationResult.isFromCache;
        _updateState(LocationState.success);
        
        // 콜백 호출
        _notifyLocationChanged(locationResult.locationData!, shouldMoveCamera);
        
        debugPrint('✅ 위치 획득 성공: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
        
      } else {
        // 실패 시 fallback 위치 사용
        debugPrint('⚠️ 위치 획득 실패, fallback 사용');
        await _useFallbackLocation();
      }
      
    } catch (e) {
      debugPrint('❌ 위치 요청 실패: $e');
      await _useFallbackLocation(errorMessage: e.toString());
    }
  }

  /// 권한 확인 및 요청
  Future<PermissionResult> _ensurePermissions() async {
    debugPrint('🔍 권한 확인...');
    
    // 현재 권한 상태 확인
    var permissionResult = await _permissionManager.checkPermissionStatus();
    
    if (permissionResult == PermissionResult.granted) {
      return PermissionResult.granted;
    }
    
    // 권한 요청
    if (permissionResult == PermissionResult.denied || permissionResult == PermissionResult.unknown) {
      debugPrint('🔐 권한 요청...');
      permissionResult = await _permissionManager.requestPermission();
    }
    
    return permissionResult;
  }

  /// 권한 오류 처리
  void _handlePermissionError(PermissionResult result) {
    switch (result) {
      case PermissionResult.denied:
        _updateState(LocationState.permissionDenied, 
          errorMessage: '위치 권한이 필요합니다');
        break;
      case PermissionResult.deniedForever:
        _updateState(LocationState.permissionDenied, 
          errorMessage: '설정에서 위치 권한을 허용해주세요');
        break;
      case PermissionResult.serviceDisabled:
        _updateState(LocationState.serviceDisabled,
          errorMessage: '위치 서비스를 활성화해주세요');
        break;
      default:
        _updateState(LocationState.error,
          errorMessage: '위치 권한 확인 중 오류가 발생했습니다');
        break;
    }
  }

  /// fallback 위치 사용
  Future<void> _useFallbackLocation({String? errorMessage}) async {
    debugPrint('🏫 fallback 위치 사용');
    
    final fallbackResult = _locationService.getFallbackLocation();
    
    if (fallbackResult.isSuccess) {
      _currentLocation = fallbackResult.locationData;
      _isFromCache = false;
      _updateState(LocationState.fallback);
      
      // 콜백 호출
      _notifyLocationChanged(fallbackResult.locationData!, true);
      
      debugPrint('✅ fallback 위치 설정 완료');
    } else {
      _updateState(LocationState.error, 
        errorMessage: errorMessage ?? '위치를 가져올 수 없습니다');
    }
  }

  /// 필요한 경우 위치 재요청
  void _requestLocationIfNeeded() {
    if (_state == LocationState.permissionDenied || 
        _state == LocationState.serviceDisabled ||
        _state == LocationState.error) {
      
      debugPrint('🔄 권한 복구됨, 위치 재요청...');
      Future.delayed(const Duration(milliseconds: 500), () {
        requestCurrentLocation();
      });
    }
  }

  /// 위치 추적 시작
  Future<void> startLocationTracking({
    Function(loc.LocationData)? onLocationChanged,
  }) async {
    try {
      debugPrint('🔄 위치 추적 시작...');
      
      if (_isTracking) {
        debugPrint('⚠️ 이미 위치 추적 중');
        return;
      }
      
      // 권한 확인
      final permissionResult = await _ensurePermissions();
      if (permissionResult != PermissionResult.granted) {
        _handlePermissionError(permissionResult);
        return;
      }
      
      // 위치 추적 시작
      await _startLocationStream(onLocationChanged);
      
    } catch (e) {
      debugPrint('❌ 위치 추적 시작 실패: $e');
      _updateState(LocationState.error, errorMessage: e.toString());
    }
  }

  /// 위치 스트림 시작
  Future<void> _startLocationStream(Function(loc.LocationData)? onLocationChanged) async {
    try {
      final location = loc.Location();
      
      // 기존 구독 정리
      await _trackingSubscription?.cancel();
      
      _trackingSubscription = location.onLocationChanged.listen(
        (loc.LocationData locationData) {
          if (locationData.latitude != null && locationData.longitude != null) {
            debugPrint('📍 위치 업데이트: ${locationData.latitude}, ${locationData.longitude}');
            
            _currentLocation = locationData;
            _isFromCache = false;
            
            // 상태가 추적 중이 아니면 성공으로 변경
            if (_state != LocationState.success) {
              _updateState(LocationState.success);
            }
            
            // 콜백 호출 (카메라 이동 없이)
            _notifyLocationChanged(locationData, false);
            
            // 추가 콜백
            onLocationChanged?.call(locationData);
            
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('❌ 위치 추적 오류: $error');
          _updateState(LocationState.error, errorMessage: error.toString());
          _isTracking = false;
        },
      );
      
      _isTracking = true;
      debugPrint('✅ 위치 추적 시작됨');
      
    } catch (e) {
      debugPrint('❌ 위치 스트림 시작 실패: $e');
      _isTracking = false;
      rethrow;
    }
  }

  /// 위치 추적 중지
  void stopLocationTracking() {
    debugPrint('⏹️ 위치 추적 중지');
    
    _trackingSubscription?.cancel();
    _trackingSubscription = null;
    _isTracking = false;
    
    notifyListeners();
  }

  /// 위치 변경 알림
  void _notifyLocationChanged(loc.LocationData locationData, bool shouldMoveCamera) {
    try {
      _onLocationChanged?.call(locationData);
      
      // 추가적인 위치 변경 처리가 필요한 경우 여기에 추가
      // 예: 지도 카메라 이동, 마커 업데이트 등
      
    } catch (e) {
      debugPrint('❌ 위치 변경 콜백 오류: $e');
    }
  }

  /// 상태 업데이트
  void _updateState(LocationState newState, {String? errorMessage}) {
    if (_state != newState) {
      final oldState = _state;
      _state = newState;
      _errorMessage = errorMessage;
      
      debugPrint('🔄 위치 상태 변경: $oldState → $newState${errorMessage != null ? ' ($errorMessage)' : ''}');
      
      // 상태 변경 콜백
      _onStateChanged?.call(newState);
      
      notifyListeners();
    }
  }

  /// 위치 권한 재요청 (UI에서 호출)
  Future<void> retryLocationPermission() async {
    debugPrint('🔄 위치 권한 재요청...');
    
    // 권한 캐시 무효화
    _permissionManager.invalidateCache();
    
    // 위치 재요청
    await requestCurrentLocation(forceRefresh: true);
  }

  /// 앱 설정 열기 (권한이 영구 거부된 경우)
  Future<void> openAppSettings() async {
    await _permissionManager.openAppSettings();
  }

  /// 위치 새로고침
  Future<void> refreshLocation() async {
    debugPrint('🔄 위치 새로고침...');
    
    // 캐시 무효화
    _locationService.invalidateCache();
    _permissionManager.invalidateCache();
    
    // 위치 재요청
    await requestCurrentLocation(forceRefresh: true);
  }

  /// 위치 초기화
  void clearLocation() {
    debugPrint('🗑️ 위치 초기화');
    
    _currentLocation = null;
    _errorMessage = null;
    _isFromCache = false;
    _updateState(LocationState.initial);
    
    // 캐시 무효화
    _locationService.invalidateCache();
  }

  /// 앱 라이프사이클 변경 처리
  void handleAppLifecycleChange(AppLifecycleState state) {
    debugPrint('📱 앱 라이프사이클 변경: $state');
    
    _permissionManager.handleAppLifecycleChange(state);
    
    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아오면 권한 상태 재확인
      Future.delayed(const Duration(milliseconds: 1000), () {
        _permissionManager.checkPermissionStatus(forceRefresh: true);
      });
    }
  }

  /// 콜백 설정
  void setOnLocationChanged(Function(loc.LocationData) callback) {
    _onLocationChanged = callback;
  }
  
  void setOnStateChanged(Function(LocationState) callback) {
    _onStateChanged = callback;
  }

  /// 현재 위치가 최근 것인지 확인
  bool isLocationRecent({Duration maxAge = const Duration(minutes: 5)}) {
    if (_currentLocation?.time == null) return false;
    
    final locationTime = DateTime.fromMillisecondsSinceEpoch(
      _currentLocation!.time!.toInt()
    );
    final now = DateTime.now();
    final difference = now.difference(locationTime);
    
    return difference <= maxAge;
  }

  /// 위치 정확도 확인
  double? get locationAccuracy => _currentLocation?.accuracy;
  
  /// 위치 시간
  DateTime? get locationTime {
    if (_currentLocation?.time == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(_currentLocation!.time!.toInt());
  }

  /// 위치 서비스 상태 문자열
  String get statusMessage {
    switch (_state) {
      case LocationState.initial:
        return '위치 서비스 준비 중...';
      case LocationState.loading:
        return '현재 위치 확인 중...';
      case LocationState.success:
        return _isFromCache ? '위치 확인됨 (캐시)' : '위치 확인됨';
      case LocationState.permissionDenied:
        return _errorMessage ?? '위치 권한이 필요합니다';
      case LocationState.serviceDisabled:
        return '위치 서비스가 비활성화되어 있습니다';
      case LocationState.error:
        return _errorMessage ?? '위치를 가져올 수 없습니다';
      case LocationState.fallback:
        return '기본 위치를 사용합니다';
    }
  }

  @override
  void dispose() {
    debugPrint('🧹 LocationController 정리');
    
    // 위치 추적 중지
    stopLocationTracking();
    
    // 권한 리스너 제거
    _permissionManager.removePermissionListener(_onPermissionChanged);
    
    // 서비스 정리
    _locationService.dispose();
    _permissionManager.dispose();
    
    // 콜백 초기화
    _onLocationChanged = null;
    _onStateChanged = null;
    
    super.dispose();
  }
}