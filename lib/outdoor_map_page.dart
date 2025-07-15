import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class OutdoorMapPage extends StatelessWidget {
  final List<NLatLng> path; // 실외 경로 좌표 리스트
  final double distance;    // 실외 구간 거리 (미터)

  const OutdoorMapPage({
    super.key,
    required this.path,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('실외 경로 안내')),
      body: Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: path.isNotEmpty ? path.first : NLatLng(36.337, 127.445),
                zoom: 16,
              ),
            ),
            onMapReady: (controller) async {
              if (path.length >= 2) {
                await controller.addOverlay(NPolylineOverlay(
                  id: 'outdoor_path',
                  coords: path,
                  color: Colors.blue,
                  width: 6,
                ));
              }
            },
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
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
                '실외 이동 거리: ${distance.toStringAsFixed(0)}m',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
