// lib/map/map_screen.dart - 네비게이션 상태 UI가 포함된 지도 화면

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/friends/friends_screen.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/services/path_api_service.dart';
import 'package:flutter_application_1/timetable/timetable_screen.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/map/widgets/map_view.dart';
import 'package:flutter_application_1/map/widgets/building_info_window.dart';
import 'package:flutter_application_1/map/widgets/building_detail_sheet.dart';
import 'package:flutter_application_1/map/widgets/building_search_bar.dart';
import 'package:flutter_application_1/controllers/map_controller.dart';
import 'package:flutter_application_1/managers/location_manager.dart';
import 'package:flutter_application_1/profile/profile_screen.dart';
import '../generated/app_localizations.dart';
import 'package:app_settings/app_settings.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter_application_1/map/widgets/directions_screen.dart';
import 'package:flutter_application_1/widgets/category_chips.dart';
import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/services/category_api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  late MapScreenController _controller;
  final OverlayPortalController _infoWindowController = OverlayPortalController();
  int _currentNavIndex = 0;
  bool _hasFoundInitialLocation = false;
  bool _isMapReady = false;
  bool _hasTriedAutoMove = false;

    // 🔥 자동 이동 강화를 위한 추가 변수들
  bool _autoMoveScheduled = false;
  Timer? _autoMoveTimer;
  Timer? _forceAutoMoveTimer;
  int _autoMoveRetryCount = 0;
  static const int _maxAutoMoveRetries = 3;
  
  // 🔥 중복 요청 방지를 위한 플래그들 추가
  bool _isRequestingLocation = false;
  bool _isInitializing = false;
  
  // 🔥 네비게이션 상태 관련 변수들 추가
  bool _showNavigationStatus = false;
  String _estimatedDistance = '';
  String _estimatedTime = '';
  Building? _navigationStart;
  Building? _navigationEnd;

  @override
  void initState() {
    super.initState();
    _controller = MapScreenController();
    WidgetsBinding.instance.addObserver(this);
    _initializeController();
  }
  
  // 8. dispose 메서드에 타이머 정리 추가:
  @override
  void dispose() {
    _autoMoveTimer?.cancel();
    _forceAutoMoveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  String? _selectedCategory;
  List<CategoryBuilding> _categoryBuildings = [];
  bool _isCategoryLoading = false;

  
  // 🔥 안전한 위치 권한 체크 및 요청
  Future<void> _checkAndRequestLocation() async {
    if (_isRequestingLocation) {
      debugPrint('⚠️ 이미 위치 요청 중입니다.');
      return;
    }

    try {
      _isRequestingLocation = true;
      debugPrint('🔄 권한 상태 재확인 중...');
      
      final locationManager = Provider.of<LocationManager>(context, listen: false);
      
      // LocationManager가 초기화되지 않았으면 잠시 대기
      if (!locationManager.isInitialized) {
        debugPrint('⏳ LocationManager 초기화 대기 중...');
        await Future.delayed(const Duration(milliseconds: 500));
        if (!locationManager.isInitialized) {
          debugPrint('❌ LocationManager 초기화 실패');
          return;
        }
      }

      // 권한 상태 재확인
      await locationManager.recheckPermissionStatus();
      
      // 권한이 없다면 요청
      if (locationManager.permissionStatus != loc.PermissionStatus.granted) {
        debugPrint('🔐 위치 권한 요청 중...');
        await locationManager.requestLocation();
      } else {
        debugPrint('✅ 권한 허용됨 - 위치 요청 시작');
        await locationManager.requestLocation();
      }
    } catch (e) {
      debugPrint('❌ 위치 권한 체크 실패: $e');
    } finally {
      _isRequestingLocation = false;
    }
  }

    Future<void> _initializeController() async {
    if (_isInitializing) return;

    try {
      _isInitializing = true;
      debugPrint('🚀 MapScreen 초기화 시작...');

      final locationManager = Provider.of<LocationManager>(context, listen: false);
      _controller.setLocationManager(locationManager);

      // 🔥 위치 발견 콜백 - 즉시 자동 이동 예약
      locationManager.onLocationFound = (loc.LocationData locationData) {
        debugPrint('📍 위치 발견! 자동 이동 즉시 예약');
        _scheduleImmediateAutoMove();
      };

      await _controller.initialize();
      _requestInitialLocationSafely(locationManager);

      debugPrint('✅ MapScreen 초기화 완료');
    } catch (e) {
      debugPrint('❌ MapScreen 초기화 오류: $e');
    } finally {
      _isInitializing = false;
    }
  }

   // 🔥 즉시 자동 이동 예약 (위치 발견 즉시)
  void _scheduleImmediateAutoMove() {
    if (_autoMoveScheduled) return;
    
    _autoMoveScheduled = true;
    debugPrint('⚡ 즉시 자동 이동 예약됨');
    
    // 아주 짧은 지연 후 실행 (지도 렌더링 완료 대기)
    _autoMoveTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && !_hasTriedAutoMove) {
        _executeRobustAutoMove();
      }
    });
    
    // 추가 안전 장치: 2초 후에도 강제 실행
    _forceAutoMoveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_hasTriedAutoMove) {
        debugPrint('🚨 강제 자동 이동 실행');
        _executeRobustAutoMove();
      }
    });
  }

  // 🔥 강건한 자동 이동 실행
  Future<void> _executeRobustAutoMove() async {
    if (_hasTriedAutoMove) return;
    
    try {
      _hasTriedAutoMove = true;
      _autoMoveRetryCount = 0;
      debugPrint('🎯 강건한 자동 이동 시작! (시도 ${_autoMoveRetryCount + 1}/${_maxAutoMoveRetries})');
      
      // 위치가 있는지 확인
      final locationManager = Provider.of<LocationManager>(context, listen: false);
      if (!locationManager.hasValidLocation) {
        debugPrint('❌ 유효한 위치 없음, 자동 이동 실패');
        return;
      }
      
      // 더 오래 기다린 후 실행
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        bool success = await _tryMoveToLocation();
        
        if (!success && _autoMoveRetryCount < _maxAutoMoveRetries) {
          // 재시도
          _autoMoveRetryCount++;
          _hasTriedAutoMove = false; // 재시도를 위해 플래그 재설정
          debugPrint('🔄 자동 이동 재시도 예약 (${_autoMoveRetryCount}/${_maxAutoMoveRetries})');
          
          Timer(const Duration(seconds: 1), () {
            if (mounted && !_hasTriedAutoMove) {
              _executeRobustAutoMove();
            }
          });
        } else if (success) {
          debugPrint('✅ 자동 이동 성공!');
          _showLocationMoveSuccess();
        } else {
          debugPrint('❌ 자동 이동 최대 재시도 실패');
        }
      }
    } catch (e) {
      debugPrint('❌ 자동 이동 실행 오류: $e');
      _hasTriedAutoMove = false; // 실패 시 재시도 가능하도록
    }
  }

// 🔥 위치 이동 시도 (성공/실패 반환)
  Future<bool> _tryMoveToLocation() async {
    try {
      debugPrint('📍 위치 이동 시도 시작...');
      
      // 타임아웃을 더 길게 설정하여 이동 시도
      await _controller.moveToMyLocation().timeout(
        const Duration(seconds: 8), // 타임아웃을 8초로 증가
        onTimeout: () {
          debugPrint('⏰ 위치 이동 타임아웃');
          throw TimeoutException('위치 이동 타임아웃', const Duration(seconds: 8));
        },
      );
      
      debugPrint('✅ 위치 이동 성공');
      return true;
    } catch (e) {
      debugPrint('❌ 위치 이동 실패: $e');
      return false;
    }
  }

  // 3. 새로운 자동 이동 예약 메서드 추가:
  void _scheduleAutoMove() {
    if (_autoMoveScheduled) return;
    
    _autoMoveScheduled = true;
    debugPrint('⏰ 자동 이동 예약됨');
    
    // 지도가 준비될 때까지 주기적으로 체크
    _autoMoveTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_isMapReady && !_hasTriedAutoMove && mounted) {
        timer.cancel();
        _executeAutoMove();
      } else if (!mounted) {
        timer.cancel();
      }
    });
    
    // 최대 5초 후에는 강제로 시도
    Timer(const Duration(seconds: 5), () {
      if (!_hasTriedAutoMove && mounted && _isMapReady) {
        _autoMoveTimer?.cancel();
        _executeAutoMove();
      }
    });
  }

   // 4. 실제 자동 이동 실행 메서드:
  Future<void> _executeAutoMove() async {
    if (_hasTriedAutoMove) return;
    
    try {
      _hasTriedAutoMove = true;
      debugPrint('🎯 자동 이동 실행!');
      
      // 약간의 지연을 두어 지도가 완전히 로드되도록 함
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        await _controller.moveToMyLocation();
        debugPrint('✅ 자동 이동 완료!');
        
        // 성공 시 사용자에게 알림
        _showLocationMoveSuccess();
      }
    } catch (e) {
      debugPrint('❌ 자동 이동 실패: $e');
      // 실패 시에도 사용자가 수동으로 버튼을 눌러 시도할 수 있도록 플래그 재설정
      _hasTriedAutoMove = false;
    }
  }

 // 🔥 개선된 성공 알림
  void _showLocationMoveSuccess() {
    if (!mounted) return;
    
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.my_location, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(l10n.moved_to_my_location ?? '내 위치로 이동했습니다'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981), // 성공 색상으로 변경
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// 🔥 안전한 초기 위치 요청 (Future already completed 오류 방지)
  Future<void> _requestInitialLocationSafely(LocationManager locationManager) async {
    // 이미 요청 중이거나 찾았으면 리턴
    if (_isRequestingLocation || _hasFoundInitialLocation) {
      return;
    }

  try {
    _isRequestingLocation = true;
    debugPrint('📍 안전한 초기 위치 요청 시작...');
    
    // UI 블로킹 방지를 위한 지연
    await Future.delayed(const Duration(milliseconds: 100));
    
    // LocationManager 초기화 대기
    int retries = 0;
    while (!locationManager.isInitialized && retries < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      retries++;
    }

    if (!locationManager.isInitialized) {
      debugPrint('⚠️ LocationManager 초기화 타임아웃');
      setState(() {
        _hasFoundInitialLocation = true;
      });
      return;
    }

    debugPrint('✅ LocationManager 초기화 완료');

    // 🔥 Welcome에서 미리 준비된 위치가 있는지 더 정확하게 확인
    debugPrint('🔍 Welcome 위치 준비 상태 확인...');
    debugPrint('   hasValidLocation: ${locationManager.hasValidLocation}');
    debugPrint('   currentLocation: ${locationManager.currentLocation}');
    debugPrint('   permissionStatus: ${locationManager.permissionStatus}');
    
    if (locationManager.hasValidLocation && locationManager.currentLocation != null) {
      debugPrint('🎯 Welcome에서 미리 준비된 위치 발견! 즉시 사용');
      debugPrint('   위도: ${locationManager.currentLocation!.latitude}');
      debugPrint('   경도: ${locationManager.currentLocation!.longitude}');
      
      if (mounted) {
        setState(() {
          _hasFoundInitialLocation = true;
        });
        
        // 🔥 즉시 자동 이동 체크 (약간의 지연 후)
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            _checkAndAutoMove();
          }
        });
        return; // 미리 준비된 위치가 있으면 여기서 종료
      }
    }

    // 🔥 미리 준비된 위치가 없는 경우에만 새로 요청
    debugPrint('🔄 미리 준비된 위치가 없음, 새로 위치 요청 시작...');
    
    // 위치 요청 실행
    await locationManager.requestLocation();
    
    debugPrint('🔍 위치 요청 완료, 결과 확인...');
    debugPrint('hasValidLocation: ${locationManager.hasValidLocation}');
    
    if (locationManager.hasValidLocation && mounted) {
      debugPrint('✅ 새로운 위치 획득 성공!');
      setState(() {
        _hasFoundInitialLocation = true;
      });
      
      // 🔥 위치 획득 후 자동 이동 체크
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _checkAndAutoMove();
        }
      });
    } else {
      debugPrint('❌ 위치 획득 실패');
      setState(() {
        _hasFoundInitialLocation = true;
      });
    }
  } catch (e) {
    debugPrint('❌ 초기 위치 요청 실패: $e');
    if (mounted) {
      setState(() {
        _hasFoundInitialLocation = true;
      });
    }
  } finally {
    _isRequestingLocation = false;
  }
}

  /// 지도와 위치가 모두 준비되면 자동 이동
  void _checkAndAutoMove() {
    debugPrint('🎯 자동 이동 조건 체크...');
    debugPrint('_isMapReady: $_isMapReady');
    debugPrint('_hasFoundInitialLocation: $_hasFoundInitialLocation');
    debugPrint('_hasTriedAutoMove: $_hasTriedAutoMove');
    
    if (_isMapReady && _hasFoundInitialLocation && !_hasTriedAutoMove && !_isRequestingLocation) {
      debugPrint('🎯 조건 충족, 자동 이동 예약');
      _scheduleAutoMove();
    } else {
      debugPrint('⏳ 자동 이동 조건 미충족');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<MapScreenController>(
        builder: (context, controller, child) {
          return Scaffold(
            body: IndexedStack(
              index: _currentNavIndex,
              children: [
                _buildMapScreen(controller),
                const ScheduleScreen(),
                Container(
                  color: Colors.white,
                  child: Center(child: Text(AppLocalizations.of(context)!.friends_screen_bottom_sheet)),
                ),
                const ProfileScreen(),
              ],
            ),
            bottomNavigationBar: _buildBottomNavigationBar(),
            floatingActionButton: null,
          );
        },
      ),
    );
  }

  // MapScreen(_MapScreenState)에서는 selectCategory 메서드를 제거하고
// 오직 _buildMapScreen 메서드만 유지해야 합니다.

 // 🔥 지도 준비 완료 시 즉시 체크
  Widget _buildMapScreen(MapScreenController controller) {
    if (controller.selectedBuilding != null &&
        !_infoWindowController.isShowing &&
        mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_infoWindowController.isShowing) {
          _infoWindowController.show();
        }
      });
    }

    return Stack(
      children: [
        MapView(
          onMapReady: (mapController) async {
            await _controller.onMapReady(mapController);
            debugPrint('🗺️ 지도 준비 완료!');
            setState(() {
              _isMapReady = true;
            });
            
            // 🔥 지도 준비 즉시 자동 이동 트리거
            if (!_hasTriedAutoMove) {
              final locationManager = Provider.of<LocationManager>(context, listen: false);
              if (locationManager.hasValidLocation) {
                debugPrint('🚀 지도 준비 완료, 즉시 자동 이동 시작');
                _scheduleImmediateAutoMove();
              } else {
                debugPrint('⏳ 지도 준비 완료, 위치 대기 중...');
              }
            }
          },
          onTap: () => _controller.closeInfoWindow(_infoWindowController),
        ),

     if (!_hasFoundInitialLocation) _buildInitialLocationLoading(),
        if (_controller.isCategoryLoading) _buildCategoryLoadingIndicator(),

        // 검색바와 카테고리 칩들
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Column(
            children: [
              BuildingSearchBar(
                onBuildingSelected: (building) {
                  if (_controller.selectedCategory != null) {
                    _controller.clearCategorySelection();
                  }
                  _controller.selectBuilding(building);
                  if (mounted) _infoWindowController.show();
                },
                onSearchFocused: () => _controller.closeInfoWindow(_infoWindowController),
              ),
              const SizedBox(height: 12),
              CategoryChips(
                selectedCategory: _controller.selectedCategory,
                onCategorySelected: (category, buildings) {
                  debugPrint('카테고리 선택: $category, 건물 수: ${buildings.length}');
                  _controller.closeInfoWindow(_infoWindowController);
                  _controller.selectCategory(category, buildings);
                },
              ),
            ],
          ),
        ),

        // 나머지 UI 요소들...
        if (_showNavigationStatus) ...[
          Positioned(
            left: 0,
            right: 0,
            bottom: 27,
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                child: _buildNavigationStatusCard(),
              ),
            ),
          ),
        ],

        if (controller.isLoading &&
            controller.startBuilding != null &&
            controller.endBuilding != null)
          _buildRouteLoadingIndicator(),

        if (controller.hasLocationPermissionError)
          _buildLocationError(),

        if (controller.hasActiveRoute && !_showNavigationStatus)
          Positioned(
            left: 16,
            right: 100,
            bottom: 30,
            child: _buildClearNavigationButton(controller),
          ),

        Positioned(
          right: 16,
          bottom: 27,
          child: _buildRightControls(controller),
        ),

        _buildBuildingInfoWindow(controller),
      ],
    );
  }

// 3. _buildCategoryLoadingIndicator 메서드를 _buildInitialLocationLoading 바로 뒤에 추가:

  /// 초기 위치 로딩 인디케이터
  Widget _buildInitialLocationLoading() {
    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 120,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.finding_current_location,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 카테고리 로딩 인디케이터 - _buildInitialLocationLoading 바로 뒤에 추가
  Widget _buildCategoryLoadingIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 170,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2196F3).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_controller.selectedCategory} 위치를 검색 중...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }



  // 우측 컨트롤 버튼들 - 내 위치 버튼 색상 수정
  Widget _buildRightControls(MapScreenController controller) {
    return Consumer<LocationManager>(
      builder: (context, locationManager, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCompactControlButton(
              onPressed: () => _controller.toggleBuildingMarkers(),
              icon: controller.buildingMarkersVisible ? Icons.location_on : Icons.location_off,
              color: controller.buildingMarkersVisible
                  ? const Color(0xFF1E3A8A)
                  : Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            _buildMyLocationButton(locationManager),
          ],
        );
      },
    );
  }

  /// 🔥 안전한 내 위치로 이동
   // 9. 내 위치 버튼도 개선하여 더 확실한 동작 보장:
 // 🔥 개선된 수동 내 위치 이동 (더 안정적)
  Future<void> _moveToMyLocationSafely() async {
    if (_isRequestingLocation) {
      debugPrint('⚠️ 이미 위치 요청 중입니다.');
      return;
    }

    try {
      _isRequestingLocation = true;
      debugPrint('📍 수동 내 위치 이동 요청...');
      
      final locationManager = Provider.of<LocationManager>(context, listen: false);
      
      // LocationManager 초기화 확인 및 대기
      if (!locationManager.isInitialized) {
        debugPrint('⏳ LocationManager 초기화 대기...');
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (locationManager.isInitialized) break;
        }
        
        if (!locationManager.isInitialized) {
          _showLocationError('위치 서비스를 초기화할 수 없습니다.');
          return;
        }
      }

      // 위치 권한 확인
      await locationManager.recheckPermissionStatus();
      
      if (locationManager.permissionStatus != loc.PermissionStatus.granted) {
        debugPrint('🔐 위치 권한 요청 중...');
        await locationManager.requestLocation();
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (locationManager.permissionStatus != loc.PermissionStatus.granted) {
          _showLocationError('위치 권한이 필요합니다.');
          return;
        }
      }

      // 위치가 없다면 새로 요청
      if (!locationManager.hasValidLocation) {
        debugPrint('📍 새로운 위치 요청 중...');
        await locationManager.requestLocation();
        await Future.delayed(const Duration(milliseconds: 1000)); // 위치 획득 대기
      }

      // 🔥 여러 번 시도하는 안정적인 이동
      bool moveSuccess = false;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          debugPrint('🎯 내 위치 이동 시도 $attempt/3');
          
          await _controller.moveToMyLocation().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('이동 타임아웃', const Duration(seconds: 10)),
          );
          
          moveSuccess = true;
          debugPrint('✅ 내 위치 이동 성공 (시도 $attempt)');
          break;
        } catch (e) {
          debugPrint('❌ 이동 시도 $attempt 실패: $e');
          if (attempt < 3) {
            await Future.delayed(const Duration(milliseconds: 1000));
          }
        }
      }
      
      if (moveSuccess) {
        _showLocationMoveSuccess();
      } else {
        _showLocationError('위치로 이동할 수 없습니다. 네트워크를 확인해주세요.');
      }
      
    } catch (e) {
      debugPrint('❌ 내 위치 이동 전체 오류: $e');
      _showLocationError('위치로 이동할 수 없습니다. 다시 시도해주세요.');
    } finally {
      _isRequestingLocation = false;
    }
  }
// 10. 에러 표시 헬퍼 메서드:
  void _showLocationError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // 🔥 내 위치 버튼 수정 - 안전한 위치 요청 사용
  Widget _buildMyLocationButton(LocationManager locationManager) {
    final bool isLoading = _isRequestingLocation || locationManager.isRequestingLocation;
    final bool hasLocation = locationManager.hasValidLocation;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : _moveToMyLocationSafely,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: hasLocation
                  ? const Color(0xFF1E3A8A).withOpacity(0.3)
                  : Colors.grey.shade200,
              width: hasLocation ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xFF1E3A8A),
                    strokeWidth: 2,
                  ),
                )
              : Icon(
                  hasLocation ? Icons.my_location : Icons.location_searching,
                  color: const Color(0xFF1E3A8A),
                  size: 24,
                ),
        ),
      ),
    );
  }

  Widget _buildCompactControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.map_outlined, Icons.map, l10n.home),
              _buildNavItem(1, Icons.schedule_outlined, Icons.schedule, l10n.timetable),
              _buildFriendsNavItem(),
              _buildNavItem(3, Icons.person_outline, Icons.person, l10n.my_page),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsNavItem() {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => FriendsBottomSheet.show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.people_outline,
                size: 22,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.friends,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1E3A8A).withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 22,
                color: isActive ? const Color(0xFF1E3A8A) : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? const Color(0xFF1E3A8A) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 네비게이션 상태 카드 위젯 - 더 컴팩트하게 수정하여 우측 버튼과 겹치지 않도록
  Widget _buildNavigationStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 더 컴팩트한 패딩
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(12), // 더 작은 둥글기
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 필요한 최소 크기만 사용
        children: [
          // 예상 시간과 거리 표시 - 더 컴팩트하게
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCompactInfoItem(Icons.straighten, '거리', _estimatedDistance.isNotEmpty ? _estimatedDistance : '계산중'),
              Container(
                width: 1,
                height: 20, // 높이 더 축소
                color: Colors.white.withOpacity(0.2),
              ),
              _buildCompactInfoItem(Icons.access_time, '시간', _estimatedTime.isNotEmpty ? _estimatedTime : '계산중'),
            ],
          ),
          
          const SizedBox(height: 8), // 간격 더 축소
          
          // 길 안내 시작 버튼과 경로 초기화 버튼을 나란히 배치
          Row(
            children: [
              // 길 안내 시작 버튼 (50%)
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // 실제 길 안내 시작
                    _startActualNavigation();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6), // 더 작은 패딩
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6), // 더 작은 둥글기
                    ),
                    elevation: 1,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.navigation, size: 12), // 더 작은 아이콘
                      SizedBox(width: 3),
                      Text(
                        '길 안내',
                        style: TextStyle(
                          fontSize: 11, // 더 작은 폰트
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 6),
              
              // 경로 초기화 버튼 (50%)
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _controller.clearNavigation();
                    // 네비게이션 상태도 함께 초기화
                    setState(() {
                      _showNavigationStatus = false;
                      _estimatedDistance = '';
                      _estimatedTime = '';
                      _navigationStart = null;
                      _navigationEnd = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6), // 더 작은 패딩
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6), // 더 작은 둥글기
                    ),
                    elevation: 1,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.clear, size: 12), // 더 작은 아이콘
                      SizedBox(width: 3),
                      Text(
                        '초기화',
                        style: TextStyle(
                          fontSize: 11, // 더 작은 폰트
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 컴팩트한 정보 아이템 위젯 - 더 작게
  Widget _buildCompactInfoItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 14, // 더 작은 아이콘
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9, // 더 작은 폰트
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10, // 더 작은 폰트
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // 🔥 실제 길 안내 시작 메서드 - 이때 경로를 표시하고 UI는 유지
  void _startActualNavigation() {
    if (_navigationEnd == null) {
      debugPrint('도착지가 설정되지 않았습니다');
      return;
    }
    
    debugPrint('🚀 길 안내 시작 - 경로 표시!');
    debugPrint('출발지: ${_navigationStart?.name ?? "현재 위치"}');
    debugPrint('도착지: ${_navigationEnd!.name}');
    
    // 🔥 이제 실제로 경로를 표시
    try {
      if (_navigationStart == null) {
        // 현재 위치에서 출발
        debugPrint('현재 위치에서 ${_navigationEnd!.name}까지 경로 표시');
        _controller.navigateFromCurrentLocation(_navigationEnd!);
      } else {
        // 특정 건물에서 출발
        debugPrint('${_navigationStart!.name}에서 ${_navigationEnd!.name}까지 경로 표시');
        _controller.setStartBuilding(_navigationStart!);
        _controller.setEndBuilding(_navigationEnd!);
        _controller.calculateRoute();
      }
      
      // 네비게이션 상태는 유지 (UI 그대로 둠)
      
      // 성공 알림 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.navigation, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _navigationStart == null 
                      ? '${_navigationEnd!.name}까지 경로가 표시되었습니다'
                      : '${_navigationStart!.name}에서 ${_navigationEnd!.name}까지 경로가 표시되었습니다',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ 경로 표시 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('경로 표시에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRouteLoadingIndicator() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Color(0xFF1E3A8A),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.calculating_route,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.finding_optimal_route,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClearNavigationButton(MapScreenController controller) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _controller.clearNavigation();
              // 네비게이션 상태도 함께 초기화
              setState(() {
                _showNavigationStatus = false;
                _estimatedDistance = '';
                _estimatedTime = '';
                _navigationStart = null;
                _navigationEnd = null;
              });
            },
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.clear,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.clear_route,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationError() {
    final l10n = AppLocalizations.of(context)!;
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 150,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_off,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.location_permission_denied,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // 설정 열기 버튼
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // 앱 설정 열기
                      await AppSettings.openAppSettings();
                    },
                    icon: const Icon(Icons.settings, size: 16),
                    label: Text(l10n.open_settings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 재확인 버튼
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _checkAndRequestLocation,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(l10n.retry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingInfoWindow(MapScreenController controller) {
    final l10n = AppLocalizations.of(context)!;
    
    return OverlayPortal(
      controller: _infoWindowController,
      overlayChildBuilder: (context) {
        if (controller.selectedBuilding == null) {
          return const SizedBox.shrink();
        }

        return BuildingInfoWindow(
          building: controller.selectedBuilding!,
          onClose: () => controller.closeInfoWindow(_infoWindowController),
          onShowDetails: (building) => BuildingDetailSheet.show(context, building),
          onShowFloorPlan: (building) {
            // FloorPlanDialog.show(context, building);
          },
          onSetStart: (result) {
            // DirectionsScreen에서 반환된 결과를 Map으로 캐스팅
            if (result is Map<String, dynamic>) {
              print('길찾기 결과 받음 (출발지): $result');
              _handleDirectionsResult(result);
            } else {
              print('잘못된 결과 타입: $result');
            }
          },
          onSetEnd: (result) {
            // DirectionsScreen에서 반환된 결과를 Map으로 캐스팅
            if (result is Map<String, dynamic>) {
              print('길찾기 결과 받음 (도착지): $result');
              _handleDirectionsResult(result);
            } else {
              print('잘못된 결과 타입: $result');
            }
          },
        );
      },
    );
  }

  // 길찾기 결과 처리 메서드
  void _handleDirectionsResult(Map<String, dynamic> result) {
    final startBuilding = result['start'] as Building?;
    final endBuilding = result['end'] as Building?;
    final useCurrentLocation = result['useCurrentLocation'] as bool? ?? false;
    final estimatedDistance = result['estimatedDistance'] as String? ?? '';
    final estimatedTime = result['estimatedTime'] as String? ?? '';
    final showNavigationStatus = result['showNavigationStatus'] as bool? ?? false;
    
    debugPrint('=== 경로 안내 결과 처리 ===');
    debugPrint('출발지: ${startBuilding?.name ?? '내 위치'}');
    debugPrint('도착지: ${endBuilding?.name}');
    debugPrint('현재 위치 사용: $useCurrentLocation');
    debugPrint('예상 거리: $estimatedDistance');
    debugPrint('예상 시간: $estimatedTime');
    debugPrint('네비게이션 상태 표시: $showNavigationStatus');
    
    // 네비게이션 상태 업데이트
    setState(() {
      _showNavigationStatus = showNavigationStatus;
      _estimatedDistance = estimatedDistance;
      _estimatedTime = estimatedTime;
      _navigationStart = useCurrentLocation ? null : startBuilding;
      _navigationEnd = endBuilding;
    });
    
    // 성공 알림 표시
    if (mounted && showNavigationStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${endBuilding?.name}까지의 경로 정보가 준비되었습니다',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (estimatedDistance.isNotEmpty && estimatedTime.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '$estimatedDistance • $estimatedTime',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
          ),
          backgroundColor: const Color(0xFF2196F3),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// 🔥 길찾기 버튼 탭 처리 - 모든 길찾기 로직을 여기서 관리
Future<void> _handleDirectionsButtonTap() async {
  try {
    print('길찾기 버튼 클릭됨');
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DirectionsScreen(),
      ),
    );
    
    print('길찾기 결과: $result');
    
    if (result != null && result is Map<String, dynamic>) {
      // 🔥 두 가지 처리 방식:
      // 1. 네비게이션 상태 카드 표시 (기존 방식)
      // 2. 바로 경로 계산 및 표시 (기존 BuildingSearchBar 방식)
      
      // 기본적으로는 네비게이션 상태 카드를 표시
      _handleDirectionsResult(result);
      
      // 만약 바로 경로를 표시하고 싶다면 아래 메서드 호출
      // await _calculateAndShowRoute(result);
    }
  } catch (e) {
    print('길찾기 전체 오류: $e');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('길찾기 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/// 🔥 바로 경로 계산 및 표시 (기존 BuildingSearchBar 로직)
Future<void> _calculateAndShowRoute(Map<String, dynamic> result) async {
  final Building? startBuilding = result['start'] as Building?;
  final Building endBuilding = result['end'] as Building;
  final bool useCurrentLocation = result['useCurrentLocation'] as bool? ?? false;
  
  if (useCurrentLocation) {
    print('현재 위치에서 ${endBuilding.name}까지 길찾기');
  } else {
    print('출발지: ${startBuilding?.name}, 도착지: ${endBuilding.name}');
  }
  
  // 로딩 표시
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                useCurrentLocation 
                    ? '현재 위치에서 ${endBuilding.name}으로 경로 계산 중...'
                    : '${startBuilding?.name}에서 ${endBuilding.name}으로 경로 계산 중...'
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // PathApiService를 통해 경로 계산
  try {
    List<NLatLng> pathCoordinates;
    
    if (useCurrentLocation) {
      // 현재 위치에서 목적지로의 경로 계산
      try {
        final locationManager = Provider.of<LocationManager>(context, listen: false);
        
        if (locationManager.hasValidLocation && locationManager.currentLocation != null) {
          final currentLocation = NLatLng(
            locationManager.currentLocation!.latitude!,
            locationManager.currentLocation!.longitude!,
          );
          pathCoordinates = await PathApiService.getRouteFromLocation(currentLocation, endBuilding);
          print('📍 LocationManager에서 현재 위치 사용: ${currentLocation.latitude}, ${currentLocation.longitude}');
        } else {
          final defaultLocation = const NLatLng(36.338133, 127.446423);
          pathCoordinates = await PathApiService.getRouteFromLocation(defaultLocation, endBuilding);
          print('📍 기본 위치 사용: ${defaultLocation.latitude}, ${defaultLocation.longitude}');
        }
      } catch (e) {
        print('❌ 현재 위치 가져오기 실패: $e');
        final defaultLocation = const NLatLng(36.338133, 127.446423);
        pathCoordinates = await PathApiService.getRouteFromLocation(defaultLocation, endBuilding);
      }
    } else if (startBuilding != null) {
      pathCoordinates = await PathApiService.getRoute(startBuilding, endBuilding);
    } else {
      throw Exception('출발지가 설정되지 않았습니다');
    }
    
    if (mounted) {
      // 로딩 스낵바 숨기기
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (pathCoordinates.isNotEmpty) {
        // MapController를 통해 경로 표시
        if (useCurrentLocation) {
          await _controller.navigateFromCurrentLocation(endBuilding);
        } else {
          _controller.setStartBuilding(startBuilding!);
          _controller.setEndBuilding(endBuilding);
          await _controller.calculateRoute();
        }
        
        // 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.navigation, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    useCurrentLocation
                        ? '현재 위치에서 ${endBuilding.name}까지 경로가 표시되었습니다 (${pathCoordinates.length}개 지점)'
                        : '${startBuilding?.name}에서 ${endBuilding.name}까지 경로가 표시되었습니다 (${pathCoordinates.length}개 지점)',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        print('경로 계산 완료: ${pathCoordinates.length}개 좌표');
      } else {
        // 경로를 찾을 수 없음
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('경로를 찾을 수 없습니다. 직선 거리로 표시됩니다.'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
    
  } catch (e) {
    print('PathApiService 오류: $e');
    
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('서버 연결 오류로 직선 경로를 표시합니다'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      
      // 대체 경로 계산 (직선)
      try {
        if (useCurrentLocation) {
          await _controller.navigateFromCurrentLocation(endBuilding);
        } else if (startBuilding != null) {
          _controller.setStartBuilding(startBuilding);
          _controller.setEndBuilding(endBuilding);
          await _controller.calculateRoute();
        }
      } catch (mapError) {
        print('MapController 오류: $mapError');
      }
    }
  }
}
}