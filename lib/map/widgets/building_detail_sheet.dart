// lib/map/widgets/building_detail_sheet.dart - 길찾기 연동된 완전한 건물 상세 정보 시트

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/controllers/map_controller.dart';
import 'package:flutter_application_1/services/path_api_service.dart';
import 'package:flutter_application_1/managers/location_manager.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/map/building_data.dart';
import 'package:flutter_application_1/map/widgets/directions_screen.dart';

class BuildingDetailSheet extends StatelessWidget {
  final Building building;

  const BuildingDetailSheet({
    super.key,
    required this.building,
  });

  static void show(BuildContext context, Building building) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BuildingDetailSheet(building: building),
    );
  }

  // 출발지로 설정 - DirectionsScreen으로 이동
  void _setAsStartLocation(BuildContext context) async {
    Navigator.pop(context); // DetailSheet 닫기
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectionsScreen(presetStart: building),
      ),
    );
    
    // 길찾기 결과 처리
    if (result != null) {
      _handleDirectionsResult(context, result);
    }
  }

  // 도착지로 설정 - DirectionsScreen으로 이동
  void _setAsEndLocation(BuildContext context) async {
    Navigator.pop(context); // DetailSheet 닫기
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectionsScreen(presetEnd: building),
      ),
    );
    
    // 길찾기 결과 처리
    if (result != null) {
      _handleDirectionsResult(context, result);
    }
  }

  // 현재 위치에서 이 건물까지 바로 길찾기
  void _navigateHere(BuildContext context) async {
    Navigator.pop(context); // DetailSheet 닫기
    
    try {
      // 로딩 표시
      if (!context.mounted) return;
      
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
                child: Text('현재 위치에서 ${building.name}으로 길찾기를 시작합니다...'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );


      // LocationManager에서 현재 위치 가져오기
        final locationManager = Provider.of<LocationManager>(context, listen: false);
      NLatLng currentLocation;

      if (locationManager.hasValidLocation && locationManager.currentLocation != null) {
        currentLocation = NLatLng(
          locationManager.currentLocation!.latitude!,
          locationManager.currentLocation!.longitude!,
        );
        debugPrint('✅ 기존 위치 사용: ${currentLocation.latitude}, ${currentLocation.longitude}');
      } else {
        // 새로운 위치 요청
        debugPrint('📍 새로운 위치 요청...');
        await locationManager.requestLocation();
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (locationManager.hasValidLocation && locationManager.currentLocation != null) {
          currentLocation = NLatLng(
            locationManager.currentLocation!.latitude!,
            locationManager.currentLocation!.longitude!,
          );
          debugPrint('✅ 위치 획득 성공: ${currentLocation.latitude}, ${currentLocation.longitude}');
        } else {
          // 위치가 없으면 기본 위치 사용
          currentLocation = const NLatLng(36.338133, 127.446423); // 우송대학교 중심
          debugPrint('⚠️ 기본 위치 사용');
        }
      }

      // PathApiService를 통해 경로 계산 (에러 처리 개선)
      final pathCoordinates = await PathApiService.getRouteFromLocation(currentLocation, building);

      // MapController를 통해 경로 표시
      if (!context.mounted) return;
      final mapController = Provider.of<MapScreenController>(context, listen: false);
      await mapController.navigateFromCurrentLocation(building);

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.navigation, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${building.name}까지의 경로가 표시되었습니다'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ 길찾기 오류: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('길찾기 중 오류가 발생했습니다: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  // 길찾기 결과 처리
  void _handleDirectionsResult(BuildContext context, dynamic result) {
    if (result is Map<String, dynamic>) {
      final startBuilding = result['start'] as Building?;
      final endBuilding = result['end'] as Building?;
      final useCurrentLocation = result['useCurrentLocation'] as bool? ?? false;
      
      if (endBuilding != null) {
        // 실제 경로 계산 및 표시 로직 실행
        _executeDirections(context, startBuilding, endBuilding, useCurrentLocation);
      } else {
        debugPrint('⚠️ 도착지 정보가 없습니다');
      }
    } else {
      debugPrint('⚠️ 잘못된 길찾기 결과 형식');
    }
  }

  // 실제 길찾기 실행 (개선된 에러 처리)
  Future<void> _executeDirections(
    BuildContext context, 
    Building? startBuilding, 
    Building endBuilding, 
    bool useCurrentLocation
  ) async {
    if (!context.mounted) return;
    
    try {
      final mapController = Provider.of<MapScreenController>(context, listen: false);

      if (useCurrentLocation) {
        // 현재 위치에서 길찾기
        await mapController.navigateFromCurrentLocation(endBuilding);
      } else if (startBuilding != null) {
        // 건물 간 길찾기
        mapController.setStartBuilding(startBuilding);
        mapController.setEndBuilding(endBuilding);
        await mapController.calculateRoute();
      } else {
        debugPrint('⚠️ 출발지 정보가 없습니다');
        return;
      }

      String message;
      if (useCurrentLocation) {
        message = '현재 위치에서 ${endBuilding.name}으로 경로를 표시합니다';
      } else {
        message = '${startBuilding?.name}에서 ${endBuilding.name}으로 경로를 표시합니다';
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ 경로 실행 오류: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('경로 계산 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

   @override
  Widget build(BuildContext context) {
    final floorInfos = _parseFloorInfo(building.info);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 헤더
              _buildHeader(context),
              
              // 길찾기 버튼들
              _buildDirectionsButtons(context),
              
              // 내용
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      
                      // 기본 정보
                      _buildBasicInfo(),
                      
                      const SizedBox(height: 20),
                      
                      // 층별 도면
                      if (floorInfos.isNotEmpty) ...[
                        _buildFloorPlanSection(context, floorInfos),
                        const SizedBox(height: 20),
                      ],
                      
                      const SizedBox(height: 100), // 하단 여백
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.apartment,
                  color: Colors.blue.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      building.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${building.category} • 우송대학교',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionsButtons(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          // 제목
          Row(
            children: [
              Icon(
                Icons.directions,
                color: Colors.indigo.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '길찾기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 버튼들
          Row(
            children: [
              // 여기까지 오기 버튼
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateHere(context),
                  icon: const Icon(Icons.near_me, size: 18),
                  label: const Text('여기까지'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // 출발지로 설정 버튼
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _setAsStartLocation(context),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('출발지'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // 도착지로 설정 버튼
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _setAsEndLocation(context),
                  icon: const Icon(Icons.flag, size: 18),
                  label: const Text('도착지'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '기본 정보',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(Icons.category, '분류', building.category),
          _buildInfoRow(Icons.info, '상태', building.baseStatus),
          if (building.hours.isNotEmpty)
            _buildInfoRow(Icons.access_time, '운영시간', building.hours),
          if (building.phone.isNotEmpty)
            _buildInfoRow(Icons.phone, '전화번호', building.phone),
          _buildInfoRow(Icons.gps_fixed, '좌표', 
            '${building.lat.toStringAsFixed(6)}, ${building.lng.toStringAsFixed(6)}'),
          
          if (building.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              building.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorPlanSection(BuildContext context, List<Map<String, String>> floorInfos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade50, Colors.indigo.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.architecture,
                    color: Colors.purple.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '층별 도면 보기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '각 층을 선택하여 상세 도면을 확인하세요',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.purple.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // 층별 카드들
        ...floorInfos.map((floorInfo) {
          final floor = floorInfo['floor']!;
          final detail = floorInfo['detail']!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFloorCard(context, floor, detail),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFloorCard(BuildContext context, String floor, String detail) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showFloorDetail(context, floor, detail),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.blue.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.shade200,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.layers,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        floor,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (detail.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          detail,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '도면보기',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.architecture,
                        size: 12,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 층 정보 파싱
  List<Map<String, String>> _parseFloorInfo(String info) {
    final floorInfos = <Map<String, String>>[];
    final lines = info.split('\n');
    
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      
      final parts = line.split('\t');
      if (parts.length >= 2) {
        floorInfos.add({
          'floor': parts[0].trim(),
          'detail': parts[1].trim(),
        });
      } else if (parts.length == 1 && parts[0].trim().isNotEmpty) {
        floorInfos.add({
          'floor': parts[0].trim(),
          'detail': '',
        });
      }
    }
    
    // 층 정렬
    floorInfos.sort((a, b) {
      final floorA = a['floor']!;
      final floorB = b['floor']!;
      
      final numA = _extractFloorNumber(floorA);
      final numB = _extractFloorNumber(floorB);
      
      final isBasementA = floorA.toUpperCase().startsWith('B');
      final isBasementB = floorB.toUpperCase().startsWith('B');
      
      if (isBasementA && !isBasementB) return -1;
      if (!isBasementA && isBasementB) return 1;
      
      if (isBasementA && isBasementB) {
        return int.tryParse(numB)?.compareTo(int.tryParse(numA) ?? 0) ?? 0;
      } else {
        return int.tryParse(numA)?.compareTo(int.tryParse(numB) ?? 0) ?? 0;
      }
    });
    
    return floorInfos;
  }

  void _showFloorDetail(BuildContext context, String floor, String detail) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade600, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$floor 정보',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            building.name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              // 컨텐츠
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 층 정보
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.apartment,
                                  color: Colors.indigo.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '층 정보',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              detail.isNotEmpty ? detail : '상세 정보가 없습니다.',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 도면 보기 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showFloorPlan(context, floor, detail);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade600,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.architecture, size: 22),
                          label: const Text(
                            '층 도면 보기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
// 서버에서 도면 가져오기
  Future<void> _showFloorPlan(BuildContext context, String floor, String detail) async {
    final floorNumber = _extractFloorNumber(floor);
    final buildingCode = _extractBuildingCode(building.name);
    final apiUrl = 'http://13.55.76.216:3000/floor/$floorNumber/$buildingCode';
    
    debugPrint('🚀 도면 로딩 시작');
    debugPrint('📍 층: $floor → $floorNumber');
    debugPrint('🏢 건물: ${building.name} → $buildingCode');
    debugPrint('🌐 API URL: $apiUrl');

    // 로딩 다이얼로그 표시
    bool isLoading = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  '$floor 도면을 불러오는 중...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '서버: $buildingCode/$floorNumber',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (context.mounted && isLoading) {
                      Navigator.pop(context);
                      isLoading = false;
                      debugPrint('⏹️ 사용자가 로딩을 취소함');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('취소'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      debugPrint('🌐 HTTP 요청 시작: $apiUrl');
      
      final request = http.Request('GET', Uri.parse(apiUrl));
      request.headers.addAll({
        'Accept': 'image/*',
        'User-Agent': 'Flutter-App/1.0',
        'Cache-Control': 'no-cache',
        'Connection': 'close',
      });
      
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏰ 요청 타임아웃');
          throw Exception('서버 응답 시간 초과 (10초)');
        },
      );
      
      debugPrint('📡 응답 상태: ${streamedResponse.statusCode}');
      
      if (streamedResponse.statusCode != 200) {
        debugPrint('❌ HTTP 오류: ${streamedResponse.statusCode}');
        
        if (context.mounted && isLoading) {
          Navigator.pop(context);
          isLoading = false;
        }
        
        if (context.mounted) {
          _showErrorDialog(context, 'HTTP 오류가 발생했습니다.\n\n'
              '상태 코드: ${streamedResponse.statusCode}\n'
              'URL: $apiUrl');
        }
        return;
      }
      
      // 스트림에서 바이트 데이터 수집
      final bytes = <int>[];
      await for (List<int> chunk in streamedResponse.stream) {
        bytes.addAll(chunk);
      }
      
      final response = http.Response.bytes(Uint8List.fromList(bytes), streamedResponse.statusCode, 
          headers: streamedResponse.headers);

      // 로딩 다이얼로그 닫기
      if (context.mounted && isLoading) {
        Navigator.pop(context);
        isLoading = false;
      }

      if (response.statusCode == 200) {
        if (response.bodyBytes.isEmpty) {
          debugPrint('❌ 응답 데이터가 비어있음');
          if (context.mounted) {
            _showErrorDialog(context, '서버에서 빈 응답을 받았습니다.\n해당 층의 도면이 없을 수 있습니다.');
          }
          return;
        }

        // 이미지 유효성 검사
        bool isValidImage = false;
        if (response.bodyBytes.length >= 8) {
          final header = response.bodyBytes.take(8).toList();
          // PNG: 89 50 4E 47 0D 0A 1A 0A
          if (header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47) {
            debugPrint('✅ 유효한 PNG 파일 확인');
            isValidImage = true;
          }
          // JPEG: FF D8 FF
          else if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF) {
            debugPrint('✅ 유효한 JPEG 파일 확인');
            isValidImage = true;
          }
        }

        final contentType = response.headers['content-type'] ?? '';
        
        if (isValidImage || contentType.startsWith('image/')) {
          debugPrint('✅ 이미지 데이터 확인됨');
          if (context.mounted) {
            _showFloorPlanDialog(context, floor, detail, response.bodyBytes);
          }
        } else {
          debugPrint('❌ 이미지가 아닌 응답');
          if (context.mounted) {
            _showErrorDialog(context, '서버에서 이미지가 아닌 데이터를 반환했습니다.\n'
                'Content-Type: $contentType\n'
                'URL: $apiUrl');
          }
        }
      } else if (response.statusCode == 404) {
        debugPrint('❌ 404 오류: 도면을 찾을 수 없음');
        if (context.mounted) {
          _showErrorDialog(context, '해당 층의 도면을 찾을 수 없습니다.\n\n'
              '건물: ${building.name} ($buildingCode)\n'
              '층: $floor ($floorNumber)');
        }
      }
    } catch (e) {
      debugPrint('❌ 예외 발생: $e');
      
      if (context.mounted && isLoading) {
        Navigator.pop(context);
        isLoading = false;
      }
      
      if (context.mounted) {
        String errorMessage = '네트워크 오류가 발생했습니다.\n\n';
        
        if (e.toString().contains('시간 초과') || e.toString().contains('timeout')) {
          errorMessage += '⏰ 서버 응답 시간이 초과되었습니다.\n'
              '잠시 후 다시 시도해주세요.';
        } else {
          errorMessage += '오류: ${e.toString()}';
        }
        
        _showErrorDialog(context, errorMessage);
      }
    }
  }

  String _extractBuildingCode(String buildingName) {
    final RegExp regex = RegExp(r'\(([^)]+)\)');
    final match = regex.firstMatch(buildingName);
    if (match != null) {
      return match.group(1)!;
    }
    return buildingName.replaceAll(' ', '');
  }

  String _extractFloorNumber(String floor) {
    floor = floor.trim().toUpperCase();
    
    if (floor.startsWith('B')) {
      final RegExp regex = RegExp(r'B(\d+)');
      final match = regex.firstMatch(floor);
      if (match != null) {
        return 'B${match.group(1)}';
      }
    }
    
    final RegExp regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(floor);
    return match?.group(1) ?? '1';
  }

  void _showFloorPlanDialog(BuildContext context, String floor, String detail, Uint8List imageBytes) {
    debugPrint('🎨 도면 다이얼로그 표시');
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade600, Colors.blue.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.architecture,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$floor 도면',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              building.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                // 도면 이미지
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red.shade300,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '이미지를 표시할 수 없습니다',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                // 하단 안내
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '핀치하여 확대/축소, 드래그하여 이동',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade400,
            ),
            const SizedBox(width: 8),
            const Text('도면 로딩 실패'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}