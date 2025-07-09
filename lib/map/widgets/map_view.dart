//map_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_application_1/constants/map_constants.dart';

class MapView extends StatelessWidget {
  final Function(NaverMapController) onMapReady;
  final VoidCallback onTap;

  const MapView({
    super.key,
    required this.onMapReady,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NaverMap(
        options: const NaverMapViewOptions(
          initialCameraPosition: MapConstants.initialCameraPosition,
          locationButtonEnable: false,
          logoMargin: EdgeInsets.only(right: 100, left: 8, bottom: 8), // 로고 마진 조정
          scaleBarEnable: false,
        ),
        onMapReady: onMapReady,
      ),
    );
  }
}