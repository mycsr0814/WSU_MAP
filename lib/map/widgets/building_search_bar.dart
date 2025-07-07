// lib/map/widgets/building_search_bar.dart - 정리된 검색바 위젯

import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/building.dart';
import 'package:flutter_application_1/map/widgets/search_screen.dart';
import 'package:flutter_application_1/map/widgets/directions_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/controllers/map_controller.dart';
import 'package:flutter_application_1/services/path_api_service.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_application_1/managers/location_manager.dart';

class BuildingSearchBar extends StatelessWidget {
  final Function(Building) onBuildingSelected;
  final VoidCallback? onSearchFocused;

  const BuildingSearchBar({
    super.key,
    required this.onBuildingSelected,
    this.onSearchFocused,
  });

  void _onDirectionsTap(BuildContext context) async {
    try {
      print('길찾기 버튼 클릭됨');
      
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DirectionsScreen(),
        ),
      );
      
      print('길찾기 결과: $result');
      
      // 길찾기 결과가 있으면 처리
      if (result != null && result is Map<String, dynamic>) {
        final Building? startBuilding = result['start'] as Building?;
        final Building endBuilding = result['end'] as Building;
        final bool useCurrentLocation = result['useCurrentLocation'] as bool? ?? false;
        
        if (useCurrentLocation) {
          print('현재 위치에서 ${endBuilding.name}까지 길찾기');
        } else {
          print('출발지: ${startBuilding?.name}, 도착지: ${endBuilding.name}');
        }
        
        // 로딩 표시
        if (context.mounted) {
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
              
              // LocationManager에서 현재 위치 가져오기
              if (locationManager.hasValidLocation && locationManager.currentLocation != null) {
                final currentLocation = NLatLng(
                  locationManager.currentLocation!.latitude!,
                  locationManager.currentLocation!.longitude!,
                );
                pathCoordinates = await PathApiService.getRouteFromLocation(currentLocation, endBuilding);
                print('📍 LocationManager에서 현재 위치 사용: ${currentLocation.latitude}, ${currentLocation.longitude}');
              } else {
                // LocationManager에 위치가 없으면 기본 위치 사용
                final defaultLocation = const NLatLng(36.338133, 127.446423); // 우송대학교 중심
                pathCoordinates = await PathApiService.getRouteFromLocation(defaultLocation, endBuilding);
                print('📍 기본 위치 사용: ${defaultLocation.latitude}, ${defaultLocation.longitude}');
              }
            } catch (e) {
              print('❌ 현재 위치 가져오기 실패: $e');
              // 오류시 기본 위치 사용
              final defaultLocation = const NLatLng(36.338133, 127.446423);
              pathCoordinates = await PathApiService.getRouteFromLocation(defaultLocation, endBuilding);
            }
          } else if (startBuilding != null) {
            pathCoordinates = await PathApiService.getRoute(startBuilding, endBuilding);
          } else {
            throw Exception('출발지가 설정되지 않았습니다');
          }
          
          if (context.mounted) {
            // 로딩 스낵바 숨기기
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            
            if (pathCoordinates.isNotEmpty) {
              // MapController를 통해 경로 표시
              final mapController = Provider.of<MapScreenController>(context, listen: false);
              
              if (useCurrentLocation) {
                // 현재 위치에서 목적지로의 경로
                await mapController.navigateFromCurrentLocation(endBuilding);
              } else {
                // 건물 간 경로
                mapController.setStartBuilding(startBuilding!);
                mapController.setEndBuilding(endBuilding);
                await mapController.calculateRoute();
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
              for (int i = 0; i < pathCoordinates.length && i < 5; i++) {
                print('좌표 $i: ${pathCoordinates[i].latitude}, ${pathCoordinates[i].longitude}');
              }
              
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
          
          if (context.mounted) {
            // 로딩 스낵바 숨기기
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            
            // 오류 메시지 표시
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
              final mapController = Provider.of<MapScreenController>(context, listen: false);
              if (useCurrentLocation) {
                await mapController.navigateFromCurrentLocation(endBuilding);
              } else if (startBuilding != null) {
                mapController.setStartBuilding(startBuilding);
                mapController.setEndBuilding(endBuilding);
                await mapController.calculateRoute();
              }
            } catch (mapError) {
              print('MapController 오류: $mapError');
            }
          }
        }
      }
    } catch (e) {
      print('길찾기 전체 오류: $e');
      
      // 오류 발생시 사용자에게 알림
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // 검색창 - 크기 줄임
          Expanded(
            flex: 4,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
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
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    onSearchFocused?.call();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchScreen(
                          onBuildingSelected: onBuildingSelected,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.indigo.shade400,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '학교 건물을 검색해주세요',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 길찾기 버튼
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.indigo.shade600,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _onDirectionsTap(context),
                child: const Icon(
                  Icons.directions,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}