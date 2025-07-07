// lib/services/building_data_service.dart - 데이터 관리 서비스

import 'package:flutter/material.dart';
import '../models/building.dart';
import 'building_api_service.dart';

class BuildingDataService extends ChangeNotifier {
  static final BuildingDataService _instance = BuildingDataService._internal();
  factory BuildingDataService() => _instance;
  BuildingDataService._internal();

  List<Building> _buildings = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Building> get buildings => _buildings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _buildings.isNotEmpty;

  /// 건물 데이터 초기화 및 로드
  Future<void> loadBuildings() async {
    if (_isLoading) return; // 이미 로딩 중이면 중복 실행 방지
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('🔄 서버에서 건물 데이터 로딩 시작...');
      
      final buildings = await BuildingApiService.getAllBuildings();
      
      _buildings = buildings;
      _errorMessage = null;
      
      debugPrint('✅ 건물 데이터 로딩 완료: ${_buildings.length}개');
      
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 건물 데이터 로딩 실패: $e');
      
      // 네트워크 오류 시 빈 리스트로 초기화 (앱 크래시 방지)
      _buildings = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 새로고침
  Future<void> refresh() async {
    _buildings.clear();
    await loadBuildings();
  }

  /// 특정 건물 찾기
  Building? findBuildingByName(String name) {
    try {
      return _buildings.firstWhere(
        (building) => building.name.toLowerCase().contains(name.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }

  /// 카테고리별 건물 필터링
  List<Building> getBuildingsByCategory(String category) {
    return _buildings.where((building) => building.category == category).toList();
  }

  /// 검색
  List<Building> searchBuildings(String query) {
    if (query.isEmpty) return _buildings;
    
    final lowercaseQuery = query.toLowerCase();
    return _buildings.where((building) {
      return building.name.toLowerCase().contains(lowercaseQuery) ||
             building.info.toLowerCase().contains(lowercaseQuery) ||
             building.category.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}
