import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class OutdoorMapPage extends StatefulWidget {
  final List<NLatLng> path; // 실외 경로 좌표 리스트
  final double distance; // 실외 구간 거리 (미터)
  
  // 🔥 선택적 파라미터 (기본값으로 하위 호환성 유지)
  final String? startLabel;
  final String? endLabel;
  final bool showMarkers; // 🔥 마커 표시 여부

  const OutdoorMapPage({
    super.key,
    required this.path,
    required this.distance,
    this.startLabel,
    this.endLabel,
    this.showMarkers = false, // 🔥 기본값 false
  });

  @override
  State<OutdoorMapPage> createState() => _OutdoorMapPageState();
}

class _OutdoorMapPageState extends State<OutdoorMapPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔥 AppBar 제거 - UnifiedNavigationStepperPage에서 관리
      body: Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: widget.path.isNotEmpty ? widget.path.first : const NLatLng(36.337, 127.445),
                zoom: 16,
              ),
            ),
            onMapReady: (controller) async {
              if (widget.path.length >= 2) {
                // 🔥 경로 라인
                await controller.addOverlay(NPolylineOverlay(
                  id: 'outdoor_path',
                  coords: widget.path,
                  color: Colors.blue,
                  width: 6,
                ));

                // 🔥 간단한 점 마커들 (showMarkers가 true일 때만)
                if (widget.showMarkers) {
                  // 파란색 출발점 (화살표 모양)
                  await controller.addOverlay(NCircleOverlay(
                    id: 'start_point',
                    center: widget.path.first,
                    radius: 10,
                    color: const Color(0xFF3B82F6), // 파란색으로 변경
                    outlineColor: Colors.white,
                    outlineWidth: 2,
                  ));

                  // 빨간색 도착점 (깃발 모양)
                  await controller.addOverlay(NCircleOverlay(
                    id: 'end_point',
                    center: widget.path.last,
                    radius: 12,
                    color: const Color(0xFFEF4444), // 빨간색 유지
                    outlineColor: Colors.white,
                    outlineWidth: 2,
                  ));

                  // 출발점 화살표 아이콘 추가
                  await controller.addOverlay(NMarker(
                    id: 'start_arrow',
                    position: widget.path.first,
                    icon: await NOverlayImage.fromWidget(
                      context: context,
                      widget: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Color(0xFF3B82F6),
                          size: 12,
                        ),
                      ),
                      size: const Size(20, 20),
                    ),
                    size: const Size(20, 20),
                  ));

                  // 도착점 깃발 아이콘 추가
                  await controller.addOverlay(NMarker(
                    id: 'end_flag',
                    position: widget.path.last,
                    icon: await NOverlayImage.fromWidget(
                      context: context,
                      widget: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flag,
                          color: Color(0xFFEF4444),
                          size: 14,
                        ),
                      ),
                      size: const Size(24, 24),
                    ),
                    size: const Size(24, 24),
                  ));
                }
              }
            },
          ),
          // 🔥 하단 정보 카드 유지
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _buildInfoCard(),
          ),
        ],
      ),
    );
  }

  // 🔥 정보 카드 (마커 정보 포함할 때와 기본일 때 구분)
  Widget _buildInfoCard() {
    if (widget.showMarkers && (widget.startLabel != null || widget.endLabel != null)) {
      // 마커가 있고 라벨이 있을 때 - 향상된 카드
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 출발지 → 도착지
            Row(
              children: [
                // 출발지
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B82F6), // 파란색으로 변경
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '출발',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.startLabel ?? '출발지',
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
                
                Icon(Icons.arrow_forward, color: Colors.grey.shade600, size: 16),
                
                // 도착지
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
                      const Text(
                        '도착',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.endLabel ?? '도착지',
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
              '실외 이동 거리: ${widget.distance.toStringAsFixed(0)}m',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    } else {
      // 기본 카드 (기존과 동일)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '실외 이동 거리: ${widget.distance.toStringAsFixed(0)}m',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      );
    }
  }
}