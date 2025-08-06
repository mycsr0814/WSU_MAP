import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_application_1/generated/app_localizations.dart';
import 'package:flutter_application_1/services/map_location_service.dart';
import 'package:flutter_application_1/controllers/location_controllers.dart';
import 'dart:math';

class OutdoorMapPage extends StatefulWidget {
  final List<NLatLng> path;
  final double distance;
  final bool showMarkers;
  final String? startLabel;
  final String? endLabel;

  const OutdoorMapPage({
    required this.path,
    required this.distance,
    this.showMarkers = false,
    this.startLabel,
    this.endLabel,
    super.key,
  });

  @override
  State<OutdoorMapPage> createState() => _OutdoorMapPageState();
}

class _OutdoorMapPageState extends State<OutdoorMapPage> {
  NaverMapController? _mapController;
  List<String> _pathOverlayIds = [];
  List<String> _markerOverlayIds = [];

  // 위치 서비스들
  late MapLocationService _mapLocationService;
  late LocationController _locationController;

  @override
  void initState() {
    super.initState();

    // 서비스 초기화
    _mapLocationService = MapLocationService();
    _locationController = LocationController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('🔄 initState에서 마커 추가 시작');
      _drawPath();
      await _addRouteMarkers();
      _showCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          NaverMap(
            options: const NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(36.3370, 127.4450),
                zoom: 15.5,
              ),
            ),
            onMapReady: (controller) async {
              debugPrint('🗺️ 지도 준비 완료 - 마커 추가 시작');
              _mapController = controller;
              _mapLocationService.setMapController(controller);
              _locationController.setMapController(controller);
              _drawPath();
              await _addRouteMarkers();
              _showCurrentLocation();
            },
          ),
          // 하단 정보 패널
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  // 출발/도착 정보
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3B82F6), // 파란색으로 변경
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '출발지',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '출발지',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.arrow_forward, color: Colors.grey),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444), // 빨간색 유지
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '도착지',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '도착지',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 거리 정보
                  Text(
                    '${l10n.outdoor_movement_distance}: ${widget.distance.toStringAsFixed(0)}m',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _drawPath() {
    if (_mapController == null || widget.path.isEmpty) return;

    // 기존 경로 오버레이 제거
    for (var overlayId in _pathOverlayIds) {
      _mapController!.deleteOverlay(
        NOverlayInfo(type: NOverlayType.polylineOverlay, id: overlayId),
      );
    }
    _pathOverlayIds.clear();

    // 🔥 동적 경로 두께 계산
    final dynamicWidth = _calculateDynamicPathWidth(widget.path);

    // 새로운 경로 그리기
    if (widget.path.length > 1) {
      final pathOverlay = NPolylineOverlay(
        id: 'outdoor_path',
        coords: widget.path,
        color: const Color(0xFF3B82F6),
        width: dynamicWidth,
      );
      _mapController!.addOverlay(pathOverlay);
      _pathOverlayIds.add('outdoor_path');
    }
  }

  /// 🔥 동적 경로 두께 계산
  double _calculateDynamicPathWidth(List<NLatLng> pathCoordinates) {
    // 경로 길이에 따른 동적 두께 계산
    final pathLength = _calculatePathLength(pathCoordinates);

    if (pathLength < 100) {
      return 8.0; // 짧은 경로: 두꺼운 선
    } else if (pathLength < 300) {
      return 6.0; // 중간 경로: 보통 두께
    } else if (pathLength < 500) {
      return 5.0; // 긴 경로: 얇은 선
    } else {
      return 4.0; // 매우 긴 경로: 가장 얇은 선
    }
  }

  /// 🔥 경로 길이 계산 (미터 단위)
  double _calculatePathLength(List<NLatLng> coordinates) {
    if (coordinates.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < coordinates.length - 1; i++) {
      totalDistance += _calculateDistance(
        coordinates[i].latitude,
        coordinates[i].longitude,
        coordinates[i + 1].latitude,
        coordinates[i + 1].longitude,
      );
    }
    return totalDistance;
  }

  /// 🔥 두 좌표 간 거리 계산 (미터 단위)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // 지구 반지름 (미터)

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// 🔥 도를 라디안으로 변환
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// 출발지와 도착지 마커 추가
  Future<void> _addRouteMarkers() async {
    debugPrint('🎯 _addRouteMarkers 시작');
    debugPrint('MapController: ${_mapController != null ? "있음" : "없음"}');
    debugPrint('Path 길이: ${widget.path.length}');
    debugPrint('showMarkers: ${widget.showMarkers}');
    debugPrint('startLabel: ${widget.startLabel}');
    debugPrint('endLabel: ${widget.endLabel}');

    if (_mapController == null || widget.path.isEmpty) {
      debugPrint('❌ MapController가 없거나 경로가 비어있음');
      return;
    }

    // 🔥 showMarkers가 false면 마커를 추가하지 않음
    if (!widget.showMarkers) {
      debugPrint('⚠️ showMarkers가 false로 설정되어 마커를 표시하지 않습니다');
      return;
    }

    // 기존 마커 제거
    _clearRouteMarkers();

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 🔥 출발점 마커 (start_marker.png 사용)
      if (widget.path.isNotEmpty) {
        final startMarkerId = 'route_start_$timestamp';
        final startMarker = NMarker(
          id: startMarkerId,
          position: widget.path.first,
          icon: NOverlayImage.fromAssetImage('lib/asset/start_marker.png'),
          caption: NOverlayCaption(
            text: '출발지',
            color: Colors.white,
            haloColor: const Color(0xFF3B82F6),
            textSize: 12,
          ),
        );

        await _mapController!.addOverlay(startMarker);
        _markerOverlayIds.add(startMarkerId);
        debugPrint(
          '✅ 출발지 마커 추가 성공: ${widget.path.first.latitude}, ${widget.path.first.longitude}',
        );
        debugPrint('출발지 마커 ID: $startMarkerId');
      }

      // 🔥 도착점 마커 (end_marker.png 사용)
      if (widget.path.length > 1) {
        final endMarkerId = 'route_end_$timestamp';
        final endMarker = NMarker(
          id: endMarkerId,
          position: widget.path.last,
          icon: NOverlayImage.fromAssetImage('lib/asset/end_marker.png'),
          caption: NOverlayCaption(
            text: '도착지',
            color: Colors.white,
            haloColor: const Color(0xFFEF4444),
            textSize: 12,
          ),
        );

        await _mapController!.addOverlay(endMarker);
        _markerOverlayIds.add(endMarkerId);
        debugPrint(
          '✅ 도착지 마커 추가 성공: ${widget.path.last.latitude}, ${widget.path.last.longitude}',
        );
        debugPrint('도착지 마커 ID: $endMarkerId');
      }

      debugPrint('✅ 경로 마커 추가 완료 - 총 ${_markerOverlayIds.length}개 마커');

      // 🔥 마커가 추가되지 않았으면 다시 시도
      if (_markerOverlayIds.isEmpty) {
        debugPrint('⚠️ 마커가 추가되지 않음. 1초 후 재시도...');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _addRouteMarkers();
          }
        });
      }
    } catch (e) {
      debugPrint('❌ 경로 마커 추가 실패: $e');

      // 🔥 실패 시에도 재시도
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          debugPrint('🔄 마커 추가 재시도...');
          _addRouteMarkers();
        }
      });
    }
  }

  /// 현재 위치 표시
  void _showCurrentLocation() async {
    try {
      await _locationController.requestCurrentLocation();
      debugPrint('✅ 현재 위치 요청 완료');
    } catch (e) {
      debugPrint('❌ 현재 위치 요청 실패: $e');
    }
  }

  /// 경로 마커 제거
  void _clearRouteMarkers() {
    for (var markerId in _markerOverlayIds) {
      try {
        _mapController!.deleteOverlay(
          NOverlayInfo(type: NOverlayType.marker, id: markerId),
        );
      } catch (e) {
        debugPrint('마커 제거 오류 (무시): $markerId - $e');
      }
    }
    _markerOverlayIds.clear();
  }

  @override
  void dispose() {
    // 오버레이 정리
    if (_mapController != null) {
      for (var overlayId in _pathOverlayIds) {
        _mapController!.deleteOverlay(
          NOverlayInfo(type: NOverlayType.polylineOverlay, id: overlayId),
        );
      }
      _clearRouteMarkers();
    }

    // 서비스 정리
    _mapLocationService.dispose();
    _locationController.dispose();

    super.dispose();
  }
}
