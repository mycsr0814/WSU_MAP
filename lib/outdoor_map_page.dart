import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_application_1/generated/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _drawPath();
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
            onMapReady: (controller) {
              _mapController = controller;
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
    // 오버레이 정리
    if (_mapController != null) {
      for (var overlayId in _pathOverlayIds) {
        _mapController!.deleteOverlay(NOverlayInfo(
          type: NOverlayType.polylineOverlay,
          id: overlayId,
        ));
      }
    }
    super.dispose();
  }
}