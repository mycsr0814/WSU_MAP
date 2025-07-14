// lib/repositories/building_repository.dart - Result 패턴 완전 적용
import 'package:flutter/material.dart';
import '../models/building.dart';
import '../services/building_api_service.dart';
import '../services/building_data_service.dart';
import '../core/result.dart';
import '../core/app_logger.dart';

/// 건물 데이터의 단일 진실 공급원 (Single Source of Truth)
class BuildingRepository extends ChangeNotifier {
  static final BuildingRepository _instance = BuildingRepository._internal();
  factory BuildingRepository() => _instance;
  BuildingRepository._internal();

  // 🔥 단일 데이터 저장소
  List<Building> _allBuildings = [];
  bool _isLoaded = false;
  bool _isLoading = false;
  String? _lastError;
  DateTime? _lastLoadTime;

  // 🔥 서비스 인스턴스들
  final BuildingDataService _buildingDataService = BuildingDataService();

  // 🔥 콜백 관리
  final List<Function(List<Building>)> _dataChangeListeners = [];

  // Getters
  List<Building> get allBuildings => List.unmodifiable(_allBuildings);
  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  bool get hasData => _allBuildings.isNotEmpty;
  String? get lastError => _lastError;
  DateTime? get lastLoadTime => _lastLoadTime;
  int get buildingCount => _allBuildings.length;

  /// 🔥 메인 데이터 로딩 메서드 - Result 패턴 완전 적용
  Future<Result<List<Building>>> getAllBuildings({bool forceRefresh = false}) async {
    return await ResultHelper.runSafelyAsync(() async {
      // 이미 로딩된 데이터가 있고 강제 새로고침이 아니면 캐시 반환
      if (_isLoaded && _allBuildings.isNotEmpty && !forceRefresh) {
        AppLogger.info('BuildingRepository: 캐시된 데이터 반환 (${_allBuildings.length}개)', tag: 'REPO');
        return _getCurrentBuildingsWithOperatingStatus();
      }

      // 현재 로딩 중이면 기다리기
      if (_isLoading) {
        AppLogger.debug('BuildingRepository: 이미 로딩 중, 대기...', tag: 'REPO');
        return await _waitForLoadingComplete();
      }

      return await _loadBuildingsFromServer();
    }, 'BuildingRepository.getAllBuildings');
  }

  /// 🔥 동기식 건물 데이터 반환 (기존 호환성 유지)
  List<Building> getAllBuildingsSync() {
    if (_isLoaded && _allBuildings.isNotEmpty) {
      return _getCurrentBuildingsWithOperatingStatus();
    }
    
    // 데이터가 없으면 fallback 반환
    return _getFallbackBuildings().map((building) {
      final autoStatus = _getAutoOperatingStatus(building.baseStatus);
      return building.copyWith(baseStatus: autoStatus);
    }).toList();
  }

  /// 🔥 서버에서 건물 데이터 로딩 - Result 패턴 적용
  Future<List<Building>> _loadBuildingsFromServer() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      AppLogger.info('BuildingRepository: 서버에서 건물 데이터 로딩 시작...', tag: 'REPO');
      
      List<Building> buildings = [];

      // 1단계: BuildingApiService 시도
      final apiResult = await ResultHelper.runSafelyAsync(() async {
        return await BuildingApiService.getAllBuildings();
      }, 'BuildingApiService.getAllBuildings');

      if (apiResult.isSuccess) {
        buildings = apiResult.data!;
        AppLogger.info('BuildingApiService에서 ${buildings.length}개 로딩 성공', tag: 'REPO');
      } else {
        AppLogger.warning('BuildingApiService 실패: ${apiResult.error}', tag: 'REPO');
        
        // 2단계: BuildingDataService 시도
        final dataServiceResult = await ResultHelper.runSafelyAsync(() async {
          await _buildingDataService.loadBuildings();
          if (_buildingDataService.hasData) {
            return _buildingDataService.buildings;
          } else {
            throw Exception('BuildingDataService has no data');
          }
        }, 'BuildingDataService.loadBuildings');

        if (dataServiceResult.isSuccess) {
          buildings = dataServiceResult.data!;
          AppLogger.info('BuildingDataService에서 ${buildings.length}개 로딩 성공', tag: 'REPO');
        } else {
          AppLogger.error('BuildingDataService도 실패: ${dataServiceResult.error}', tag: 'REPO');
        }
      }

      // 3단계: 데이터 검증 및 저장
      if (buildings.isNotEmpty) {
        _allBuildings = buildings;
        _isLoaded = true;
        _lastLoadTime = DateTime.now();
        AppLogger.info('BuildingRepository: 서버 데이터 저장 완료 (${buildings.length}개)', tag: 'REPO');
        
        // 데이터 변경 리스너들에게 알림
        _notifyDataChangeListeners();
      } else {
        // 4단계: Fallback 데이터 사용
        _allBuildings = _getFallbackBuildings();
        _isLoaded = true;
        _lastLoadTime = DateTime.now();
        _lastError = '서버 데이터 없음, Fallback 사용';
        AppLogger.warning('BuildingRepository: Fallback 데이터 사용 (${_allBuildings.length}개)', tag: 'REPO');
      }

    } catch (e) {
      _lastError = e.toString();
      _allBuildings = _getFallbackBuildings();
      _isLoaded = true;
      AppLogger.error('BuildingRepository: 로딩 실패, Fallback 사용', tag: 'REPO', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _getCurrentBuildingsWithOperatingStatus();
  }

  /// 🔥 현재 시간 기준 운영상태가 적용된 건물 목록 반환
  List<Building> _getCurrentBuildingsWithOperatingStatus() {
    return _allBuildings.map((building) {
      final autoStatus = _getAutoOperatingStatus(building.baseStatus);
      return building.copyWith(baseStatus: autoStatus);
    }).toList();
  }

  /// 🔥 자동 운영상태 결정
  String _getAutoOperatingStatus(String baseStatus) {
    // 특별 상태는 자동 변경하지 않음
    if (baseStatus == '24시간' || baseStatus == '임시휴무' || baseStatus == '휴무') {
      return baseStatus;
    }
    
    // 현재 시간 가져오기
    final now = DateTime.now();
    final currentHour = now.hour;
    
    // 09:00 ~ 18:00 운영중, 나머지는 운영종료
    if (currentHour >= 9 && currentHour < 18) {
      return '운영중';
    } else {
      return '운영종료';
    }
  }

  /// 🔥 Fallback 건물 데이터
  List<Building> _getFallbackBuildings() {
    return [
      Building(
        name: '우송도서관(W1)',
        info: '도서관 및 학습 공간',
        lat: 36.337000,
        lng: 127.445000,
        category: '학습시설',
        baseStatus: '운영중',
        hours: '09:00-18:00',
        phone: '042-821-5601',
        imageUrl: null,
        description: '메인 도서관',
      ),
      Building(
        name: '서캠퍼스앤디컷빌딩(W19)',
        info: '강의실 및 실습실',
        lat: 36.337200,
        lng: 127.445200,
        category: '강의시설',
        baseStatus: '운영중',
        hours: '09:00-18:00',
        phone: '042-821-5602',
        imageUrl: null,
        description: '강의동',
      ),
      Building(
        name: '24시간 편의점',
        info: '24시간 운영하는 편의점',
        lat: 36.337500,
        lng: 127.446000,
        category: '편의시설',
        baseStatus: '24시간',
        hours: '24시간',
        phone: '042-821-5678',
        imageUrl: null,
        description: '24시간 편의점',
      ),
    ];
  }

  /// 🔥 로딩 완료까지 대기
  Future<List<Building>> _waitForLoadingComplete() async {
    int attempts = 0;
    const maxAttempts = 50; // 최대 5초 대기
    
    while (_isLoading && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    
    return _getCurrentBuildingsWithOperatingStatus();
  }

  /// 🔥 데이터 새로고침 - Result 패턴 적용
  Future<Result<void>> refresh() async {
    return await ResultHelper.runSafelyAsync(() async {
      AppLogger.info('BuildingRepository: 강제 새로고침', tag: 'REPO');
      _allBuildings.clear();
      _isLoaded = false;
      
      final result = await getAllBuildings(forceRefresh: true);
      if (result.isFailure) {
        throw Exception('Refresh failed: ${result.error}');
      }
    }, 'BuildingRepository.refresh');
  }

  /// 🔥 검색 기능 - Result 패턴 적용
  Result<List<Building>> searchBuildings(String query) {
    return ResultHelper.runSafely(() {
      if (query.isEmpty) return _getCurrentBuildingsWithOperatingStatus();
      
      final lowercaseQuery = query.toLowerCase();
      final filtered = _allBuildings.where((building) {
        return building.name.toLowerCase().contains(lowercaseQuery) ||
               building.info.toLowerCase().contains(lowercaseQuery) ||
               building.category.toLowerCase().contains(lowercaseQuery);
      }).toList();
      
      return filtered.map((building) {
        final autoStatus = _getAutoOperatingStatus(building.baseStatus);
        return building.copyWith(baseStatus: autoStatus);
      }).toList();
    }, 'BuildingRepository.searchBuildings');
  }

  /// 🔥 카테고리별 건물 필터링 - Result 패턴 적용
  Result<List<Building>> getBuildingsByCategory(String category) {
    return ResultHelper.runSafely(() {
      final filtered = _allBuildings.where((building) {
        return building.category == category;
      }).toList();
      
      return filtered.map((building) {
        final autoStatus = _getAutoOperatingStatus(building.baseStatus);
        return building.copyWith(baseStatus: autoStatus);
      }).toList();
    }, 'BuildingRepository.getBuildingsByCategory');
  }

  /// 🔥 운영 상태별 건물 가져오기 - Result 패턴 적용
  Result<List<Building>> getOperatingBuildings() {
    return ResultHelper.runSafely(() {
      final current = _getCurrentBuildingsWithOperatingStatus();
      return current.where((building) => 
        building.baseStatus == '운영중' || building.baseStatus == '24시간'
      ).toList();
    }, 'BuildingRepository.getOperatingBuildings');
  }

  Result<List<Building>> getClosedBuildings() {
    return ResultHelper.runSafely(() {
      final current = _getCurrentBuildingsWithOperatingStatus();
      return current.where((building) => 
        building.baseStatus == '운영종료' || building.baseStatus == '임시휴무'
      ).toList();
    }, 'BuildingRepository.getClosedBuildings');
  }

  /// 🔥 특정 건물 찾기 - Result 패턴 적용
  Result<Building?> findBuildingByName(String name) {
    return ResultHelper.runSafely(() {
      try {
        final current = _getCurrentBuildingsWithOperatingStatus();
        return current.firstWhere(
          (building) => building.name.toLowerCase().contains(name.toLowerCase()),
        );
      } catch (e) {
        return null;
      }
    }, 'BuildingRepository.findBuildingByName');
  }

  /// 🔥 데이터 변경 리스너 관리
  void addDataChangeListener(Function(List<Building>) listener) {
    _dataChangeListeners.add(listener);
    AppLogger.debug('데이터 변경 리스너 추가 (총 ${_dataChangeListeners.length}개)', tag: 'REPO');
  }

  void removeDataChangeListener(Function(List<Building>) listener) {
    _dataChangeListeners.remove(listener);
    AppLogger.debug('데이터 변경 리스너 제거 (총 ${_dataChangeListeners.length}개)', tag: 'REPO');
  }

  void _notifyDataChangeListeners() {
    final currentBuildings = _getCurrentBuildingsWithOperatingStatus();
    AppLogger.debug('데이터 변경 리스너들에게 알림 (${_dataChangeListeners.length}개)', tag: 'REPO');
    
    for (final listener in _dataChangeListeners) {
      try {
        listener(currentBuildings);
      } catch (e) {
        AppLogger.error('데이터 변경 리스너 오류', tag: 'REPO', error: e);
      }
    }
  }

  /// 🔥 캐시 무효화 - Result 패턴 적용
  Result<void> invalidateCache() {
    return ResultHelper.runSafely(() {
      AppLogger.info('BuildingRepository: 캐시 무효화', tag: 'REPO');
      _allBuildings.clear();
      _isLoaded = false;
      _lastLoadTime = null;
      _lastError = null;
      notifyListeners();
    }, 'BuildingRepository.invalidateCache');
  }

  /// 🔥 통계 정보 - Result 패턴 적용
  Result<Map<String, int>> getCategoryStats() {
    return ResultHelper.runSafely(() {
      final current = _getCurrentBuildingsWithOperatingStatus();
      final stats = <String, int>{};
      
      for (final building in current) {
        stats[building.category] = (stats[building.category] ?? 0) + 1;
      }
      
      AppLogger.debug('카테고리 통계: $stats', tag: 'REPO');
      return stats;
    }, 'BuildingRepository.getCategoryStats');
  }

  Result<Map<String, int>> getOperatingStats() {
    return ResultHelper.runSafely(() {
      final current = _getCurrentBuildingsWithOperatingStatus();
      final stats = <String, int>{};
      
      for (final building in current) {
        stats[building.baseStatus] = (stats[building.baseStatus] ?? 0) + 1;
      }
      
      AppLogger.debug('운영 상태 통계: $stats', tag: 'REPO');
      return stats;
    }, 'BuildingRepository.getOperatingStats');
  }

  /// 🔥 Repository 정리
  @override
  void dispose() {
    AppLogger.info('BuildingRepository 정리', tag: 'REPO');
    _dataChangeListeners.clear();
    _allBuildings.clear();
    super.dispose();
  }
}