import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_application_1/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/managers/location_manager.dart';

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
  NLatLng? _currentLocation;
  LocationManager? _locationManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _getCurrentLocation();
      _drawPath();
      _setupLocationListener();
    });
  }

  /// 위치 변화 감지 설정
  void _setupLocationListener() {
    _locationManager = Provider.of<LocationManager>(context, listen: false);
    _locationManager?.addListener(_onLocationChanged);
  }

  /// 위치 변화 시 호출되는 콜백
  void _onLocationChanged() {
    if (_locationManager?.hasValidLocation == true && 
        _locationManager?.currentLocation != null) {
      final newLocation = NLatLng(
        _locationManager!.currentLocation!.latitude!,
        _locationManager!.currentLocation!.longitude!,
      );
      
      // 위치가 실제로 변경되었는지 확인
      if (_currentLocation == null || 
          _currentLocation!.latitude != newLocation.latitude ||
          _currentLocation!.longitude != newLocation.longitude) {
        setState(() {
          _currentLocation = newLocation;
        });
        _showCurrentLocation();
      }
    }
  }

  /// 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    final locationManager = Provider.of<LocationManager>(context, listen: false);
    if (locationManager.hasValidLocation && locationManager.currentLocation != null) {
      setState(() {
        _currentLocation = NLatLng(
          locationManager.currentLocation!.latitude!,
          locationManager.currentLocation!.longitude!,
        );
      });
      await _showCurrentLocation();
    }
  }

  /// 현재 위치 표시
  Future<void> _showCurrentLocation() async {
    if (_mapController == null || _currentLocation == null) return;

    // 기존 현재 위치 마커 제거
    _mapController!.deleteOverlay(NOverlayInfo(
      type: NOverlayType.marker,
      id: 'current_location',
    ));

    // 현재 위치 마커 추가
    final currentLocationMarker = NMarker(
      id: 'current_location',
      position: _currentLocation!,
      icon: await NOverlayImage.fromWidget(
        context: context,
        widget: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(
            Icons.my_location,
            color: Colors.white,
            size: 14,
          ),
        ),
        size: const Size(24, 24),
      ),
      size: const Size(24, 24),
    );

    _mapController!.addOverlay(currentLocationMarker);
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
              _mapController = controller;
              await _getCurrentLocation();
              _drawPath();
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
                                color: Color(0xFF10B981), // 초록색 유지
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.departure,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.startLabel ?? l10n.myLocation,
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
                              l10n.arrival,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.endLabel ?? l10n.destination,
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
      _mapController!.deleteOverlay(NOverlayInfo(
        type: NOverlayType.polylineOverlay,
        id: overlayId,
      ));
    }
    _pathOverlayIds.clear();
    
    // 새로운 경로 그리기
    if (widget.path.length > 1) {
      final pathOverlay = NPolylineOverlay(
        id: 'outdoor_path',
        coords: widget.path,
        color: const Color(0xFF3B82F6),
        width: 8,
      );
      _mapController!.addOverlay(pathOverlay);
      _pathOverlayIds.add('outdoor_path');
    }
  }

  @override
  void dispose() {
    // 위치 리스너 제거
    _locationManager?.removeListener(_onLocationChanged);
    
    // 오버레이 정리
    if (_mapController != null) {
      for (var overlayId in _pathOverlayIds) {
        _mapController!.deleteOverlay(NOverlayInfo(
          type: NOverlayType.polylineOverlay,
          id: overlayId,
        ));
      }
      // 현재 위치 마커 정리
      _mapController!.deleteOverlay(NOverlayInfo(
        type: NOverlayType.marker,
        id: 'current_location',
      ));
    }
    super.dispose();
  }
}